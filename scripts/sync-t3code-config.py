#!/usr/bin/env python3
"""Sync T3 Code settings/keybindings from a live userdata dir into the repo.

Reads <source>/settings.json and <source>/keybindings.json (default
~/.t3/userdata, or a remote host via --host), drops host-specific and secret
keys, and writes the repo's declarative copies under
home/astroreen/profiles/apps/t3code/.

The custom.t3code module merges these into the live files on activation, so
this script only needs to capture the portable subset.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TARGET_DIR = REPO_ROOT / "home/astroreen/profiles/apps/t3code"
DEFAULT_SOURCE_DIR = "~/.t3/userdata"

# Dotted paths dropped before writing; "*" matches any single key.
#   projectSettingsOverrides                    per-project UUIDs, not portable
#   defaultThemeSetAt                           service-managed timestamp
#   environmentIcon                             host-specific (pc/laptop)
#   providerInstances.*.config.serverPassword   secret
EXCLUDED_PATHS = (
    "projectSettingsOverrides",
    "defaultThemeSetAt",
    "environmentIcon",
    "providerInstances.*.config.serverPassword",
)

FILES = ("settings.json", "keybindings.json")


# --------------------------------------------------------------------------- #
# Exclusion matching
# --------------------------------------------------------------------------- #


def _matches(pattern: str, path: str) -> bool:
    pat = pattern.split(".")
    parts = path.split(".")
    return len(pat) == len(parts) and all(
        p == "*" or p == q for p, q in zip(pat, parts)
    )


def is_excluded(path: str) -> bool:
    return any(_matches(p, path) for p in EXCLUDED_PATHS)


def strip(obj: Any, path: str = "", dropped: list[str] | None = None) -> Any:
    """Recursively drop excluded keys; lists are filtered element-wise."""
    if dropped is None:
        dropped = []
    if isinstance(obj, dict):
        out: dict[str, Any] = {}
        for key, val in obj.items():
            child = f"{path}.{key}" if path else key
            if is_excluded(child):
                dropped.append(child)
                continue
            out[key] = strip(val, child, dropped)
        return out
    if isinstance(obj, list):
        return [strip(item, path, dropped) for item in obj]
    return obj


# --------------------------------------------------------------------------- #
# Source reading (local or over ssh)
# --------------------------------------------------------------------------- #


def read_source(host: str | None, source_dir: str, name: str) -> str:
    if host:
        proc = subprocess.run(
            ["ssh", host, "cat", f"{source_dir}/{name}"],
            capture_output=True,
            text=True,
        )
        if proc.returncode != 0:
            raise RuntimeError(
                f"ssh {host} cat {source_dir}/{name}: {proc.stderr.strip()}"
            )
        return proc.stdout
    return (Path(source_dir).expanduser() / name).read_text(encoding="utf-8")


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        description=(
            "Fetch T3 Code settings/keybindings into the repo, dropping "
            "host-specific and secret keys."
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

    where = f"{args.host}:{args.source_dir}" if args.host else args.source_dir
    rc = 0
    for name in FILES:
        try:
            raw = read_source(args.host, args.source_dir, name)
            data = json.loads(raw)
        except (OSError, RuntimeError, json.JSONDecodeError) as exc:
            print(f"error: {name}: {exc}", file=sys.stderr)
            rc = 2
            continue

        dropped: list[str] = []
        filtered = strip(data, dropped=dropped)
        text = json.dumps(filtered, indent=2, ensure_ascii=False) + "\n"
        target = args.target_dir / name

        print(f"== {name}")
        print(f"  source:  {where}/{name}")
        print(f"  dropped: {', '.join(dropped) if dropped else 'none'}")
        if isinstance(filtered, dict):
            print(f"  keys:    {len(filtered)}")
        else:
            print(f"  rules:   {len(filtered)}")

        if args.dry_run:
            print("  not written (--dry-run)")
            continue

        old = target.read_text(encoding="utf-8") if target.exists() else None
        if old == text:
            print("  unchanged")
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding="utf-8")
            print("  updated")
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
