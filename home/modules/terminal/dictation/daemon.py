#!/usr/bin/env python3
"""Push-to-talk dictation daemon.

Triggered by a Hyprland keybind which runs this same file in client mode:

    dictation-daemon toggle   # press to start listening, press again to stop

While "recording" it captures 16 kHz mono s16 audio with ``pw-record``,
transcribes on stop through a faster-whisper HTTP server (``FW_SERVER_URL``,
local or remote), and injects the text into the focused window via clipboard +
synthetic Ctrl+V (robust for Cyrillic/Lithuanian input).

Transcription runs in a worker thread so a new utterance can start while the
previous one is still being decoded.

With ``FW_MODE=auto`` the server is picked when recording starts: the remote
one (``FW_REMOTE_URL``) when it answers its health check, and either the
machine runs on battery or the check took at most ``FW_MAX_LATENCY_MS``;
otherwise the local one (``FW_LOCAL_URL``), whose systemd unit is started
right away so the model loads while the user speaks. A remote request that
fails falls back to the local server.

State is published to ``FW_STATE_FILE`` so the Quickshell overlay can render
listening/transcribing/idle without an IPC dependency.
"""

import glob
import json
import os
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
import uuid

SERVER_URL = os.environ.get("FW_SERVER_URL", "http://127.0.0.1:7777/inference")
LANGUAGE = os.environ.get("FW_LANGUAGE", "auto")
STATE_FILE = os.environ.get("FW_STATE_FILE", f"/run/user/{os.getuid()}/dictation.state")
CAPTURE_SOURCE = os.environ.get("FW_CAPTURE_SOURCE", "")
SOCKET_PATH = os.environ.get("FW_SOCKET", f"/run/user/{os.getuid()}/dictation.sock")
MODE = os.environ.get("FW_MODE", "fixed")
LOCAL_URL = os.environ.get("FW_LOCAL_URL", "http://127.0.0.1:7777/inference")
REMOTE_URL = os.environ.get("FW_REMOTE_URL", "")
LOCAL_UNIT = os.environ.get("FW_LOCAL_UNIT", "whisper-server.service")
MAX_LATENCY_MS = float(os.environ.get("FW_MAX_LATENCY_MS", "150"))
PROBE_TIMEOUT = 1.5  # seconds; also the latency accepted on battery
LOCAL_START_TIMEOUT = 120  # seconds for a cold start (model load)

COMMANDS = ("start", "stop", "toggle", "status")


def health_url(inference_url: str) -> str:
    return inference_url.rsplit("/inference", 1)[0] + "/"


def probe_ms(inference_url: str, timeout: float) -> float | None:
    """Round trip of the server's health endpoint, None when it is down."""
    started = time.monotonic()
    try:
        with urllib.request.urlopen(health_url(inference_url), timeout=timeout) as resp:
            if resp.status != 200:
                return None
    except OSError:
        return None
    return (time.monotonic() - started) * 1000


def on_battery() -> bool:
    has_battery = False
    for supply in glob.glob("/sys/class/power_supply/*"):
        try:
            with open(f"{supply}/type") as fh:
                kind = fh.read().strip()
            if kind == "Mains":
                with open(f"{supply}/online") as fh:
                    if fh.read().strip() == "1":
                        return False
            elif kind == "Battery":
                has_battery = True
        except OSError:
            continue
    return has_battery


def start_local() -> None:
    subprocess.run(["systemctl", "--user", "start", "--no-block", LOCAL_UNIT], check=False)


def wait_local() -> None:
    deadline = time.monotonic() + LOCAL_START_TIMEOUT
    while time.monotonic() < deadline:
        if probe_ms(LOCAL_URL, 1) is not None:
            return
        time.sleep(0.25)
    raise TimeoutError(f"local server not ready after {LOCAL_START_TIMEOUT}s")


def pick_server() -> str:
    if not REMOTE_URL:
        start_local()
        return LOCAL_URL
    battery = on_battery()
    rtt = probe_ms(REMOTE_URL, PROBE_TIMEOUT)
    if rtt is not None and (battery or rtt <= MAX_LATENCY_MS):
        print(f"dictation: remote server ({rtt:.0f} ms, battery={battery})", file=sys.stderr)
        return REMOTE_URL
    print(f"dictation: local server (remote rtt={rtt}, battery={battery})", file=sys.stderr)
    start_local()
    return LOCAL_URL


class Route:
    """Server for one utterance, picked in the background while recording."""

    def __init__(self) -> None:
        self.url = SERVER_URL
        self._picked = threading.Event()
        if MODE == "auto":
            threading.Thread(target=self._pick, daemon=True).start()
        else:
            self._picked.set()

    def _pick(self) -> None:
        try:
            self.url = pick_server()
        finally:
            self._picked.set()

    def transcribe(self, path: str) -> str:
        self._picked.wait()
        if MODE != "auto":
            return transcribe(path, self.url)
        if self.url == LOCAL_URL:
            wait_local()
            return transcribe(path, LOCAL_URL)
        try:
            return transcribe(path, self.url)
        except OSError as exc:  # URLError and timeouts
            print(f"dictation: remote failed ({exc}), using the local server", file=sys.stderr)
            start_local()
            wait_local()
            return transcribe(path, LOCAL_URL)


def set_state(value: str) -> None:
    try:
        with open(STATE_FILE, "w") as fh:
            fh.write(value)
    except OSError:
        pass


def start_recording(path: str) -> subprocess.Popen:
    cmd = ["pw-record", "--rate", "16000", "--channels", "1", "--format", "s16"]
    if CAPTURE_SOURCE:
        cmd += ["--target", CAPTURE_SOURCE]
    cmd.append(path)
    return subprocess.Popen(cmd)


def stop_recording(proc: subprocess.Popen) -> None:
    if proc.poll() is None:
        proc.send_signal(signal.SIGINT)
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()


def transcribe(path: str, url: str) -> str:
    with open(path, "rb") as fh:
        audio = fh.read()
    boundary = uuid.uuid4().hex
    parts = [
        f"--{boundary}\r\n".encode(),
        b'Content-Disposition: form-data; name="language"\r\n\r\n',
        f"{LANGUAGE}\r\n".encode(),
        f"--{boundary}\r\n".encode(),
        b'Content-Disposition: form-data; name="file"; filename="audio.wav"\r\n',
        b"Content-Type: audio/wav\r\n\r\n",
        audio,
        f"\r\n--{boundary}--\r\n".encode(),
    ]
    body = b"".join(parts)
    req = urllib.request.Request(
        url,
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=120) as resp:
        return json.loads(resp.read().decode())["text"]


def inject(text: str) -> None:
    if not text.strip():
        return
    subprocess.run(["wl-copy"], input=text.encode(), check=False)
    time.sleep(0.05)
    if shutil.which("wtype"):
        subprocess.run(
            ["wtype", "-M", "ctrl", "-P", "v", "-p", "v", "-m", "ctrl"],
            check=False,
        )
    else:
        subprocess.run(["ydotool", "key", "29:1", "47:1", "47:0", "29:0"], check=False)


class Recorder:
    """Owns the pw-record child process and the listening/transcribing states."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._proc = None
        self._wav = None
        self._route = None

    def start(self) -> None:
        with self._lock:
            if self._proc is not None:
                return
            handle, self._wav = tempfile.mkstemp(suffix=".wav")
            os.close(handle)
            self._proc = start_recording(self._wav)
            self._route = Route()
            set_state("listening")

    def stop(self) -> None:
        with self._lock:
            if self._proc is None:
                return
            stop_recording(self._proc)
            self._proc = None
            wav, self._wav = self._wav, None
            route, self._route = self._route, None
            set_state("transcribing")
        threading.Thread(target=self._finish, args=(wav, route), daemon=True).start()

    def _finish(self, wav: str, route: Route) -> None:
        try:
            inject(route.transcribe(wav))
        except Exception as exc:  # noqa: BLE001 - keep daemon alive
            print(f"dictation: transcription failed: {exc}", file=sys.stderr)
        finally:
            try:
                os.unlink(wav)
            except OSError:
                pass
            with self._lock:
                if self._proc is None:
                    set_state("idle")

    def status(self) -> str:
        return "recording" if self._proc is not None else "idle"


def handle_command(recorder: Recorder, command: str) -> str:
    print(f"dictation: command={command}", file=sys.stderr)
    if command == "start":
        recorder.start()
    elif command == "stop":
        recorder.stop()
    elif command == "toggle":
        if recorder.status() == "recording":
            recorder.stop()
        else:
            recorder.start()
    elif command == "status":
        return recorder.status()
    else:
        return "error: unknown command"
    return "ok"


def serve() -> None:
    if os.path.exists(SOCKET_PATH):
        os.unlink(SOCKET_PATH)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(SOCKET_PATH)
    os.chmod(SOCKET_PATH, 0o600)
    server.listen(8)

    recorder = Recorder()
    set_state("idle")
    print(f"dictation: listening on {SOCKET_PATH}", file=sys.stderr)

    def shutdown(*_args) -> None:
        sys.exit(0)

    signal.signal(signal.SIGTERM, shutdown)
    signal.signal(signal.SIGINT, shutdown)

    try:
        while True:
            conn, _ = server.accept()
            try:
                command = conn.recv(64).decode(errors="replace").strip()
                conn.sendall((handle_command(recorder, command) + "\n").encode())
            except OSError:
                pass
            finally:
                conn.close()
    finally:
        server.close()
        try:
            os.unlink(SOCKET_PATH)
        except OSError:
            pass
        with recorder._lock:
            if recorder._proc is not None:
                stop_recording(recorder._proc)


def send_command(command: str) -> int:
    if not os.path.exists(SOCKET_PATH):
        # Service not up yet (e.g. first keypress after login): start and wait.
        subprocess.run(["systemctl", "--user", "start", "dictation"], check=False)
        for _ in range(40):
            if os.path.exists(SOCKET_PATH):
                break
            time.sleep(0.05)

    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        sock.connect(SOCKET_PATH)
    except OSError as exc:
        print(f"dictation: cannot reach daemon ({SOCKET_PATH}): {exc}", file=sys.stderr)
        return 1
    try:
        sock.sendall(command.encode())
        print(sock.recv(64).decode(errors="replace").strip())
    finally:
        sock.close()
    return 0


def main() -> int:
    if len(sys.argv) > 1 and sys.argv[1] in COMMANDS:
        return send_command(sys.argv[1])
    serve()
    return 0


if __name__ == "__main__":
    sys.exit(main())