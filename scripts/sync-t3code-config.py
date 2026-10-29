#!/usr/bin/env python3
"""Sync T3 Code settings, keybindings and themes from a live userdata dir into the repo.

Reads from <source> (default ~/.t3/userdata, or a remote host via --host):

  settings.json         server settings (models, worktrees, cleanup, providers, ...)
  client-settings.json  desktop app UI (fonts, contrast, diff layout, notifications, ...)
  keybindings.json      full keymap
  themes/*.json         custom themes

drops host-specific and secret keys, and writes the repo's declarative copies
under home/astroreen/profiles/apps/t3code/. The custom.t3code module merges
these into the live files on activation, so only the portable subset is kept.

Not synced (host-specific by design): desktop-settings.json (window bounds,
network exposure, Tailscale serve, password store), connection-catalog.json
(encrypted per host), and the renderer's localStorage (theme picks per
environment; the server's `defaultTheme` covers new environments).
"""

from __future__ import annotations

import argparse
import json
import re
import shlex
import subprocess
import sys
from fnmatch import fnmatchcase
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TARGET_DIR = REPO_ROOT / "home/astroreen/profiles/apps/t3code"
DEFAULT_SOURCE_DIR = "~/.t3/userdata"

# Dotted paths dropped before writing; each segment is an fnmatch pattern.
EXCLUDED_PATHS: dict[str, tuple[str, ...]] = {
    "settings.json": (
        # Records keyed by per-environment project UUIDs: projectSettingsOverrides,
        # projectScriptOverrides, projectAutoPullOverrides,
        # projectAgentBrowserAccessOverrides, and whatever upstream adds next.
        "project*Overrides",
        "defaultThemeSetAt",  # service-managed timestamp
        "environmentIcon",  # which machine this is (pc/laptop)
    ),
    "client-settings.json": (
        "onboardingCompletedAt",  # per-install state
        "dismissedProviderUpdateNotificationKeys",  # transient
        "browserProfiles",  # tied to this host's browser partitions
        "browserDefaultProfileId",
        "sidebarProjectGroupingOverrides",  # keyed by per-environment projects
    ),
    "keybindings.json": (),
}

# Keys that may hold credentials. The server moves inline secrets into its own
# store and leaves "" behind, so empty values are kept (they match the live
# file); a non-empty value is dropped and reported.
SECRET_KEY = re.compile(r"(password|token|secret|api_?key)$", re.IGNORECASE)

FILES = tuple(EXCLUDED_PATHS)
THEMES_DIR = "themes"


# --------------------------------------------------------------------------- #
# Filtering
# --------------------------------------------------------------------------- #


def _matches(pattern: str, path: str) -> bool:
    pat = pattern.split(".")
    parts = path.split(".")
    return len(pat) == len(parts) and all(
        fnmatchcase(q, p) for p, q in zip(pat, parts)
    )


def strip(
    obj: Any,
    excluded: tuple[str, ...],
    dropped: list[str],
    path: str = "",
) -> Any:
    """Recursively drop excluded and secret keys; lists are filtered element-wise."""
    if isinstance(obj, dict):
        out: dict[str, Any] = {}
        for key, val in obj.items():
            child = f"{path}.{key}" if path else key
            if any(_matches(p, child) for p in excluded):
                dropped.append(child)
                continue
            if SECRET_KEY.search(key) and isinstance(val, str) and val:
                dropped.append(f"{child} (secret)")
                continue
            out[key] = strip(val, excluded, dropped, child)
        return out
    if isinstance(obj, list):
        return [strip(item, excluded, dropped, path) for item in obj]
    return obj


# --------------------------------------------------------------------------- #
# Source access (local or over ssh)
# --------------------------------------------------------------------------- #


class Source:
    def __init__(self, host: str | None, directory: str) -> None:
        self.host = host
        self.directory = directory

    def __str__(self) -> str:
        return f"{self.host}:{self.directory}" if self.host else self.directory

    def _ssh(self, script: str) -> str:
        assert self.host is not None
        proc = subprocess.run(
            ["ssh", self.host, script], capture_output=True, text=True
        )
        if proc.returncode != 0:
            raise RuntimeError(f"ssh {self.host}: {proc.stderr.strip()}")
        return proc.stdout

    def _remote(self, name: str) -> str:
        # Leave a leading ~ unquoted so the remote shell expands it.
        path = f"{self.directory}/{name}"
        if path.startswith("~/"):
            return "~/" + shlex.quote(path[2:])
        return shlex.quote(path)

    def read(self, name: str) -> str:
        if self.host:
            return self._ssh(f"cat {self._remote(name)}")
        return (Path(self.directory).expanduser() / name).read_text(encoding="utf-8")

    def list_themes(self) -> list[str]:
        if self.host:
            out = self._ssh(
                f"cd {self._remote(THEMES_DIR)} 2>/dev/null && ls -1 -- *.json 2>/dev/null || true"
            )
            names = out.split()
        else:
            directory = Path(self.directory).expanduser() / THEMES_DIR
            names = [p.name for p in directory.glob("*.json")] if directory.is_dir() else []
        return sorted(n for n in names if n.endswith(".json"))


# --------------------------------------------------------------------------- #
# Writing
# --------------------------------------------------------------------------- #


def write(target: Path, text: str, dry_run: bool) -> None:
    old = target.read_text(encoding="utf-8") if target.exists() else None
    if old == text:
        print("  unchanged")
    elif dry_run:
        print("  would update (--dry-run)" if old is not None else "  would create (--dry-run)")
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8")
        print("  updated" if old is not None else "  created")


def dump(data: Any) -> str:
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def sync_file(source: Source, target_dir: Path, name: str, dry_run: bool) -> bool:
    try:
        data = json.loads(source.read(name))
    except (OSError, RuntimeError, json.JSONDecodeError) as exc:
        print(f"error: {name}: {exc}", file=sys.stderr)
        return False

    dropped: list[str] = []
    filtered = strip(data, EXCLUDED_PATHS[name], dropped)

    print(f"== {name}")
    print(f"  source:  {source}/{name}")
    print(f"  dropped: {', '.join(dropped) if dropped else 'none'}")
    label = "keys:" if isinstance(filtered, dict) else "rules:"
    print(f"  {label:<8} {len(filtered)}")
    write(target_dir / name, dump(filtered), dry_run)
    return True


def sync_themes(source: Source, target_dir: Path, dry_run: bool) -> bool:
    try:
        names = source.list_themes()
    except RuntimeError as exc:
        print(f"error: {THEMES_DIR}: {exc}", file=sys.stderr)
        return False

    print(f"== {THEMES_DIR}/")
    print(f"  source:  {source}/{THEMES_DIR}")
    ok = True
    for name in names:
        try:
            data = json.loads(source.read(f"{THEMES_DIR}/{name}"))
        except (OSError, RuntimeError, json.JSONDecodeError) as exc:
            print(f"error: {THEMES_DIR}/{name}: {exc}", file=sys.stderr)
            ok = False
            continue
        print(f"  {name}")
        write(target_dir / THEMES_DIR / name, dump(data), dry_run)

    # Repo-only themes are kept: they may come from another host.
    repo_dir = target_dir / THEMES_DIR
    if repo_dir.is_dir():
        for extra in sorted(p.name for p in repo_dir.glob("*.json")):
            if extra not in names:
                print(f"  {extra}: only in the repo, kept")
    return ok


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        description=(
            "Fetch T3 Code settings, client settings, keybindings and themes "
            "into the repo, dropping host-specific and secret keys."
        )
    )
    ap.add_argument(
        "--host",
        default=None,
        help="read from this host over ssh (default: local ~/.t3/userdata)",
    )
    ap.add_argument(
        "--source-dir",
        default=DEFAULT_SOURCE_DIR,
        help=f"userdata dir on the source (default: {DEFAULT_SOURCE_DIR})",
    )
    ap.add_argument(
        "--target-dir",
        type=Path,
        default=DEFAULT_TARGET_DIR,
        help=f"repo dir to write (default: {DEFAULT_TARGET_DIR})",
    )
    ap.add_argument("--dry-run", action="store_true", help="report, do not write")
    args = ap.parse_args(argv)

    source = Source(args.host, args.source_dir)
    ok = all([sync_file(source, args.target_dir, name, args.dry_run) for name in FILES])
    ok = sync_themes(source, args.target_dir, args.dry_run) and ok
    return 0 if ok else 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
