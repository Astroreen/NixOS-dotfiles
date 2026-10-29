#!/usr/bin/env python3
"""Sync the live Dux shell (dms) config of a host into the repo.

Dux keeps its user config in three files:

  ~/.config/dms/settings.json         shell settings (bar, launcher, clock, power, ...)
  ~/.local/state/dms/session.json     weather, terminal, locale, wallpapers, night
                                      mode, pinned apps, display layout, ...
  ~/.config/dms/plugin_settings.json  per-plugin settings

Every top-level key (nested for plugin settings) is classified as:

  shared  portable, written to home/astroreen/profiles/wm/shell/dux/<file>.json
          and applied on every host. Deep-merged into the repo copy (the host
          wins on conflicts): keys the source host lacks are kept, so syncing a
          host that never saw a setting does not drop it. Remove a shared key
          by editing the file.
  host    tied to this machine's monitors, battery, devices; written to
          home/astroreen/<host>/assets/dux-<file>.json, replacing it whole
  drop    transient state (launcher history, DND, ...) or schema versions that
          dux migrates itself; never written

The hypr/dms/*.lua fragments are not synced: dux regenerates them from these
files (layout/input/cursor from settings, outputs from the session).
"""

from __future__ import annotations

import argparse
import json
import socket
import subprocess
import sys
from fnmatch import fnmatchcase
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
SHARED_DIR = REPO_ROOT / "home/astroreen/profiles/wm/shell/dux"


def host_dir(host: str) -> Path:
    return REPO_ROOT / "home/astroreen" / host / "assets"


# name: (live path relative to $HOME, repo file stem, host patterns, drop patterns)
# Patterns are dotted paths; each segment is an fnmatch pattern.
FILES: dict[str, tuple[str, tuple[str, ...], tuple[str, ...]]] = {
    "settings": (
        ".config/dms/settings.json",
        (
            "ac*",  # power on AC: lock/suspend/monitor timeouts, profile
            "battery*",  # power on battery (laptop only)
            "lockBeforeSuspend",
            "barConfigs",  # bars are bound to monitors (screenPreferences)
            "screenPreferences",  # which monitor shows the lock screen, notepad, ...
            "controlCenterWidgets",  # grid layout differs (battery tile)
        ),
        ("configVersion",),
    ),
    "session": (
        ".local/state/dms/session.json",
        (
            "hyprlandOutputSettings",  # display layout -> hypr/dms/outputs.lua
            "niriOutputSettings",
            "activeDisplayProfile*",
            "monitorWallpapers*",
            "monitorCyclingSettings",
            "lockScreenAutoPositions",
            "desktopWidgetGridSettings",
            "lockScreenWidgetGridSettings",
            "islandFreePositions",
            "brightness*",
            "*GpuTempEnabled",
            "enabledGpuPciIds",
            "wifiDeviceOverride",
            "bluetoothAdapterOverride",
            "deviceMaxVolumes",
            "hidden*DeviceNames",  # audio devices
        ),
        (
            "configVersion",
            "doNotDisturb*",
            "screenShare*",
            "idleInhibited*",
            "updaterNotified*",
            "launcher*",
            "appDrawerLastMode",
            "niriOverviewLastMode",
            "notepadLastMode",
            "lastPlayerIdentity",
            "lastBrightnessDevice",
            "vpnLastConnected",
            "greeterSync*",
            "lastAppliedIconTheme",
            "showConfigReloadToast",
            "pluginBrowser*",
        ),
    ),
    "plugin-settings": (
        ".config/dms/plugin_settings.json",
        (
            "dankKDEConnect.selectedDeviceId",  # device id as paired with this host
            "linuxWallpaperEngine.monitorScenes",  # keyed by output name
            "linuxWallpaperEngine.outputSettings",
        ),
        (),
    ),
}


# --------------------------------------------------------------------------- #
# Classification
# --------------------------------------------------------------------------- #


def _matches(pattern: str, path: str) -> bool:
    pat = pattern.split(".")
    parts = path.split(".")
    return len(pat) == len(parts) and all(
        fnmatchcase(q, p) for p, q in zip(pat, parts)
    )


def split(
    data: dict[str, Any],
    host_patterns: tuple[str, ...],
    drop_patterns: tuple[str, ...],
    dropped: list[str],
    path: str = "",
) -> tuple[dict[str, Any], dict[str, Any]]:
    """Return (shared, host) parts of `data`, recursing into objects that a
    nested pattern refers to."""
    shared: dict[str, Any] = {}
    host: dict[str, Any] = {}
    for key, val in data.items():
        child = f"{path}.{key}" if path else key
        if any(_matches(p, child) for p in drop_patterns):
            dropped.append(child)
            continue
        if any(_matches(p, child) for p in host_patterns):
            host[key] = val
            continue
        nested = any(
            _matches(".".join(p.split(".")[: child.count(".") + 1]), child)
            and p.count(".") > child.count(".")
            for p in host_patterns + drop_patterns
        )
        if nested and isinstance(val, dict):
            sub_shared, sub_host = split(
                val, host_patterns, drop_patterns, dropped, child
            )
            if sub_shared:
                shared[key] = sub_shared
            if sub_host:
                host[key] = sub_host
            continue
        shared[key] = val
    return shared, host


# Keys inside otherwise portable values (dock, widget instances, ...) that bind
# them to specific monitors; anything but ["all"] makes the value host-bound.
SCREEN_KEYS = ("screenPreferences", "displayPreferences")


def screen_bound(val: Any, path: str = "") -> list[str]:
    """Paths under `val` that pin it to specific monitors."""
    found: list[str] = []
    if isinstance(val, dict):
        for key, sub in val.items():
            child = f"{path}.{key}" if path else key
            if key in SCREEN_KEYS and sub not in (["all"], [], None):
                found.append(child)
            else:
                found += screen_bound(sub, child)
    elif isinstance(val, list):
        for i, sub in enumerate(val):
            found += screen_bound(sub, f"{path}[{i}]")
    return found


# --------------------------------------------------------------------------- #
# IO
# --------------------------------------------------------------------------- #


def read_live(host: str, rel: str, remote: bool) -> dict[str, Any] | None:
    if remote:
        proc = subprocess.run(
            ["ssh", host, f"cat ~/{rel} 2>/dev/null || true"],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            raise RuntimeError(f"ssh {host}: {proc.stderr.strip()}")
        raw = proc.stdout
    else:
        path = Path.home() / rel
        raw = path.read_text(encoding="utf-8") if path.exists() else ""
    return json.loads(raw) if raw.strip() else None


def load_repo(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}


def deep_merge(base: dict[str, Any], top: dict[str, Any]) -> dict[str, Any]:
    """`top` wins at the leaves; objects merge, anything else is replaced."""
    out = dict(base)
    for key, val in top.items():
        if isinstance(val, dict) and isinstance(out.get(key), dict):
            out[key] = deep_merge(out[key], val)
        else:
            out[key] = val
    return out


def dump(data: Any) -> str:
    # Sorted, so hosts that order keys differently do not churn the diff
    return json.dumps(data, indent=2, ensure_ascii=False, sort_keys=True) + "\n"


def write(path: Path, data: dict[str, Any], dry_run: bool) -> None:
    rel = path.relative_to(REPO_ROOT)
    text = dump(data)
    old = path.read_text(encoding="utf-8") if path.exists() else None
    if old == text:
        state = "unchanged"
    elif dry_run:
        state = "would update" if old is not None else "would create"
    else:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
        state = "updated" if old is not None else "created"
    print(f"  {rel}: {len(data)} keys, {state}")


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def main(argv: list[str]) -> int:
    local = socket.gethostname().split(".")[0]
    ap = argparse.ArgumentParser(
        description=(
            "Copy a host's live Dux settings, session and plugin settings into "
            "the repo: portable keys into the shared profile, machine-bound "
            "keys into the host's assets."
        )
    )
    ap.add_argument(
        "host",
        nargs="?",
        default=local,
        help=f"flake host to read (default: this machine, {local}); read over ssh when remote",
    )
    ap.add_argument("--dry-run", action="store_true", help="report, do not write")
    args = ap.parse_args(argv)

    if not (REPO_ROOT / "home/astroreen" / args.host).is_dir():
        print(f"error: unknown host '{args.host}'", file=sys.stderr)
        return 2
    remote = args.host != local

    rc = 0
    for stem, (rel, host_patterns, drop_patterns) in FILES.items():
        print(f"== {stem} ({'ssh ' + args.host + ':' if remote else ''}~/{rel})")
        try:
            live = read_live(args.host, rel, remote)
        except (OSError, RuntimeError, json.JSONDecodeError) as exc:
            print(f"error: {exc}", file=sys.stderr)
            rc = 2
            continue
        if live is None:
            print("  missing on the host, skipped")
            continue

        dropped: list[str] = []
        shared, host = split(live, host_patterns, drop_patterns, dropped)
        print(f"  dropped: {', '.join(dropped) if dropped else 'none'}")

        moved: list[str] = []
        for key in list(shared):
            bound = screen_bound(shared[key], key)
            if bound:
                moved.append(key)
                # Monitor names of this host would land on every host: keep
                # the whole key with the host instead.
                print(f"  warning: {key} is pinned to monitors ({', '.join(bound)}), stored per host")
                host[key] = shared.pop(key)

        shared_path = SHARED_DIR / f"{stem}.json"
        repo_shared = load_repo(shared_path)
        # A key now stored per host must leave the shared file, or the profile
        # and the host would define it twice
        for key in moved:
            repo_shared.pop(key, None)
        kept = sorted(k for k in repo_shared if k not in shared)
        if kept:
            print(f"  kept from repo (not set on {args.host}): {', '.join(kept)}")
        write(shared_path, deep_merge(repo_shared, shared), args.dry_run)
        write(host_dir(args.host) / f"dux-{stem}.json", host, args.dry_run)
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
