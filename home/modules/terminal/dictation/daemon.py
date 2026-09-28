#!/usr/bin/env python3
"""Push-to-talk dictation daemon.

Triggered by Hyprland keybinds (``hl.bind`` on press, ``{ release = true; }`` on
release) which run this same file in client mode:

    dictation-daemon start    # key pressed
    dictation-daemon stop     # key released

While "recording" it captures 16 kHz mono s16 audio with ``pw-record``,
transcribes on stop through the local faster-whisper HTTP server, and injects
the text into the focused window via clipboard + synthetic Ctrl+V (robust for
Cyrillic/Lithuanian input).

Transcription runs in a worker thread so a new utterance can start while the
previous one is still being decoded.

State is published to ``FW_STATE_FILE`` so the Quickshell overlay can render
listening/transcribing/idle without an IPC dependency.
"""

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

COMMANDS = ("start", "stop", "toggle", "status")


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


def transcribe(path: str) -> str:
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
        SERVER_URL,
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

    def start(self) -> None:
        with self._lock:
            if self._proc is not None:
                return
            handle, self._wav = tempfile.mkstemp(suffix=".wav")
            os.close(handle)
            self._proc = start_recording(self._wav)
            set_state("listening")

    def stop(self) -> None:
        with self._lock:
            if self._proc is None:
                return
            stop_recording(self._proc)
            self._proc = None
            wav, self._wav = self._wav, None
            set_state("transcribing")
        threading.Thread(target=self._finish, args=(wav,), daemon=True).start()

    def _finish(self, wav: str) -> None:
        try:
            inject(transcribe(wav))
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