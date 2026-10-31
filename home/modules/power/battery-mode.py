#!/usr/bin/env python3
"""Battery mode: trims the session while the machine runs on battery.

Power source changes come from ``upower --monitor``. On battery it

* turns the Hyprland options in ``BM_HYPR_OPTIONS`` off (``hyprctl eval``)
  after saving their values, puts them back on AC, and repeats that after a
  config reload, which resets them;
* stops the user units in ``BM_BATTERY_UNITS`` right away and the ones in
  ``BM_LOW_UNITS`` once the charge is at or below ``BM_LOW_THRESHOLD``;
  on AC it starts again those of them that were running and are listed in
  ``BM_RESTORE_UNITS``;
* applies the Hyprland monitor rules in ``BM_BATTERY_MONITORS`` (JSON list
  of ``hl.monitor`` tables, e.g. a 60 Hz mode) on battery, or only at low
  charge with ``BM_MONITORS_AT=low``, and the ones in ``BM_AC_MONITORS`` on
  AC; after a config reload too.

Power profiles and idle timeouts are left to the desktop shell.
"""

import glob
import json
import os
import selectors
import signal
import socket
import subprocess
import sys
import time

HYPR_OPTIONS = os.environ.get("BM_HYPR_OPTIONS", "").split()
BATTERY_UNITS = os.environ.get("BM_BATTERY_UNITS", "").split()
LOW_UNITS = os.environ.get("BM_LOW_UNITS", "").split()
RESTORE_UNITS = set(os.environ.get("BM_RESTORE_UNITS", "").split())
LOW_THRESHOLD = int(os.environ.get("BM_LOW_THRESHOLD", "20"))
BATTERY_MONITORS = json.loads(os.environ.get("BM_BATTERY_MONITORS") or "[]")
MONITORS_AT = os.environ.get("BM_MONITORS_AT", "battery")  # "battery" or "low"
AC_MONITORS = json.loads(os.environ.get("BM_AC_MONITORS") or "[]")
RECHECK_SECONDS = 60  # also catches a missed upower line
# Units stopped by an earlier run, so a restart on battery still restores them
STATE_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "battery-mode.json")


def log(message: str) -> None:
    print(f"battery-mode: {message}", file=sys.stderr, flush=True)


def power_state() -> str:
    """Return "ac", "battery" or "low"; "ac" too on a machine without a battery."""
    capacity = None
    for supply in glob.glob("/sys/class/power_supply/*"):
        try:
            with open(f"{supply}/type") as fh:
                kind = fh.read().strip()
            if kind == "Mains":
                with open(f"{supply}/online") as fh:
                    if fh.read().strip() == "1":
                        return "ac"
            elif kind == "Battery":
                with open(f"{supply}/capacity") as fh:
                    capacity = int(fh.read().strip())
        except (OSError, ValueError):
            continue
    if capacity is None:
        return "ac"
    return "low" if capacity <= LOW_THRESHOLD else "battery"


def hyprctl(*args: str) -> str:
    result = subprocess.run(["hyprctl", *args], capture_output=True, text=True, check=False)
    return result.stdout


def lua_value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value)  # a valid Lua string literal for these values
    if isinstance(value, list):
        return "{ " + ", ".join(lua_value(item) for item in value) + " }"
    return "{ " + ", ".join(f"[{json.dumps(key)}] = {lua_value(item)}" for key, item in value.items()) + " }"


def lua_table(values: dict[str, bool]) -> str:
    """{"decoration:blur:enabled": False} -> { decoration = { blur = { enabled = false } } }"""
    tree: dict = {}
    for option, value in values.items():
        node = tree
        *parents, leaf = option.split(":")
        for part in parents:
            node = node.setdefault(part, {})
        node[leaf] = value
    return lua_value(tree)


class Hyprland:
    def __init__(self) -> None:
        self.saved: dict[str, bool] = {}
        self.battery_monitors = False

    def set_monitors(self, battery: bool) -> None:
        if battery == self.battery_monitors or not BATTERY_MONITORS:
            return
        for monitor in BATTERY_MONITORS if battery else AC_MONITORS:
            hyprctl("eval", f"hl.monitor({lua_value(monitor)})")
        self.battery_monitors = battery
        log("battery monitor rules applied" if battery else "monitor rules restored")

    def reduce(self) -> None:
        if not HYPR_OPTIONS:
            return
        self.saved = {}
        for option in HYPR_OPTIONS:
            try:
                reply = json.loads(hyprctl("-j", "getoption", option))
            except json.JSONDecodeError:
                continue  # option missing in this Hyprland version
            if isinstance(reply.get("bool"), bool):
                self.saved[option] = reply["bool"]
        if self.saved:
            hyprctl("eval", f"hl.config({lua_table(dict.fromkeys(self.saved, False))})")
            log(f"hyprland effects off: {' '.join(self.saved)}")

    def restore(self) -> None:
        self.set_monitors(False)
        if self.saved:
            hyprctl("eval", f"hl.config({lua_table(self.saved)})")
            log("hyprland effects restored")
        self.saved = {}


def socket2_path() -> str | None:
    signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    if signature:
        return f"{runtime}/hypr/{signature}/.socket2.sock"
    candidates = sorted(glob.glob(f"{runtime}/hypr/*/.socket2.sock"), key=os.path.getmtime)
    return candidates[-1] if candidates else None


def unit_active(unit: str) -> bool:
    return subprocess.run(["systemctl", "--user", "is-active", "--quiet", unit], check=False).returncode == 0


class Units:
    def __init__(self) -> None:
        try:
            with open(STATE_FILE) as fh:
                self.stopped: set[str] = set(json.load(fh))
        except (OSError, ValueError):
            self.stopped = set()

    def save(self) -> None:
        try:
            with open(STATE_FILE, "w") as fh:
                json.dump(sorted(self.stopped), fh)
        except OSError:
            pass

    def stop(self, units: list[str]) -> None:
        for unit in units:
            if unit not in self.stopped and unit_active(unit):
                subprocess.run(["systemctl", "--user", "stop", unit], check=False)
                self.stopped.add(unit)
                log(f"stopped {unit}")
        self.save()

    def restore(self) -> None:
        for unit in sorted(self.stopped & RESTORE_UNITS):
            subprocess.run(["systemctl", "--user", "start", unit], check=False)
            log(f"started {unit}")
        self.stopped = set()
        self.save()


class BatteryMode:
    def __init__(self) -> None:
        self.hyprland = Hyprland()
        self.units = Units()
        self.state = "ac"
        self.selector = selectors.DefaultSelector()
        self.monitor = subprocess.Popen(["upower", "--monitor"], stdout=subprocess.PIPE, text=True, bufsize=1)
        self.selector.register(self.monitor.stdout, selectors.EVENT_READ, "upower")
        self.events = self.connect_hyprland()
        self.buffer = b""

    def connect_hyprland(self) -> socket.socket | None:
        path = socket2_path() if HYPR_OPTIONS or BATTERY_MONITORS else None
        if not path:
            return None
        events = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        try:
            events.connect(path)
        except OSError as exc:
            log(f"no Hyprland event socket ({exc}); effects are not re-applied after reloads")
            return None
        self.selector.register(events, selectors.EVENT_READ, "hyprland")
        return events

    def apply(self, new_state: str) -> None:
        if new_state == self.state:
            return
        log(f"{self.state} -> {new_state}")
        if new_state == "ac":
            self.hyprland.restore()
            self.units.restore()
        else:
            if self.state == "ac":
                self.hyprland.reduce()
            self.units.stop(BATTERY_UNITS)
            if MONITORS_AT == "battery" or new_state == "low":
                self.hyprland.set_monitors(True)
            if new_state == "low":
                self.units.stop(LOW_UNITS)
        self.state = new_state

    def on_hyprland_events(self) -> bool:
        chunk = self.events.recv(4096)
        if not chunk:
            log("Hyprland event socket closed")
            return False
        self.buffer += chunk
        *lines, self.buffer = self.buffer.split(b"\n")
        if self.state != "ac" and any(line.startswith(b"configreloaded>>") for line in lines):
            # the reload reset the options and monitors to their config values
            time.sleep(0.2)
            self.hyprland.reduce()
            if self.hyprland.battery_monitors:
                self.hyprland.battery_monitors = False
                self.hyprland.set_monitors(True)
        return True

    def run(self) -> int:
        self.apply(power_state())
        while True:
            for key, _ in self.selector.select(timeout=RECHECK_SECONDS):
                if key.data == "upower" and not self.monitor.stdout.readline():
                    log("upower --monitor exited")
                    return 1
                if key.data == "hyprland" and not self.on_hyprland_events():
                    return 1
            self.apply(power_state())


def main() -> int:
    # Put the options back on exit: a restarted instance would otherwise save
    # the reduced values as the ones to restore
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    mode = BatteryMode()
    try:
        return mode.run()
    finally:
        mode.hyprland.restore()


if __name__ == "__main__":
    sys.exit(main())
