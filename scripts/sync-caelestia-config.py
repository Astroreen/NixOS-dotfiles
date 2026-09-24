#!/usr/bin/env python3
"""Merge the official caelestia-shell example config into local shell.json sources.

For each target JSON:
  1. apply schema migrations (stale keys -> current keys),
  2. add only the keys that are missing from the official example (values already
     set by the user are never overwritten; arrays are kept wholesale),
  3. apply the migrations again (idempotent) so nothing stale is reintroduced,
  4. report unknown keys (present locally, absent from the example).

Example source: the largest ```json fenced block of the upstream README.md
(https://github.com/caelestia-dots/shell), or a local file via --example.
"""

from __future__ import annotations

import argparse
import copy
import json
import sys
import urllib.error
import urllib.request
from pathlib import Path
from typing import Any

DEFAULT_README_URL = (
    "https://raw.githubusercontent.com/caelestia-dots/shell/main/README.md"
)


# --------------------------------------------------------------------------- #
# Example config loading
# --------------------------------------------------------------------------- #


def extract_json_blocks(markdown: str) -> list[str]:
    """Return the bodies of every fenced ```json block in a markdown document."""
    blocks: list[str] = []
    lines = markdown.splitlines()
    i = 0
    while i < len(lines):
        if lines[i].strip() == "```json":
            i += 1
            start = i
            while i < len(lines) and lines[i].strip() != "```":
                i += 1
            blocks.append("\n".join(lines[start:i]))
        i += 1
    return blocks


def load_example_from_readme(url: str) -> dict[str, Any]:
    with urllib.request.urlopen(url, timeout=30) as resp:
        text = resp.read().decode("utf-8")
    blocks = extract_json_blocks(text)
    if not blocks:
        raise ValueError(f"no ```json fenced block found in {url}")
    body = max(blocks, key=len)
    return json.loads(body)


def load_example_from_file(path: Path) -> dict[str, Any]:
    with path.open(encoding="utf-8") as fh:
        return json.load(fh)


# --------------------------------------------------------------------------- #
# Schema migrations
# --------------------------------------------------------------------------- #


def _migrate_use_twelve_hour_clock(cfg: dict[str, Any], notes: list[str]) -> None:
    """services.useTwelveHourClock (bool, removed upstream) -> services.clockFormat."""
    services = cfg.get("services")
    if not isinstance(services, dict) or "useTwelveHourClock" not in services:
        return
    val = services.pop("useTwelveHourClock")
    if "clockFormat" in services:
        notes.append(
            f"services.useTwelveHourClock={val!r} removed "
            f"(services.clockFormat already {services['clockFormat']!r})"
        )
        return
    services["clockFormat"] = "TwelveHour" if val else "TwentyFourHour"
    notes.append(
        f"services.useTwelveHourClock={val!r} -> "
        f"services.clockFormat={services['clockFormat']!r}"
    )


def _migrate_vpn_provider_enabled(cfg: dict[str, Any], notes: list[str]) -> None:
    """utilities.vpn.provider[].enabled (not a schema field) -> utilities.vpn.selectedProvider."""
    utilities = cfg.get("utilities")
    if not isinstance(utilities, dict):
        return
    vpn = utilities.get("vpn")
    if not isinstance(vpn, dict):
        return
    providers = vpn.get("provider")
    if not isinstance(providers, list):
        return

    enabled_ids: list[str] = []
    for idx, item in enumerate(providers):
        if not isinstance(item, dict):
            continue
        if not item.get("id"):
            fallback = item.get("name") or f"provider-{idx}"
            item["id"] = fallback
            notes.append(f"utilities.vpn.provider[{idx}].id added as {fallback!r}")
        if "enabled" in item:
            val = item.pop("enabled")
            notes.append(
                f"utilities.vpn.provider[{idx}].enabled={val!r} removed "
                f"(selection lives in utilities.vpn.selectedProvider)"
            )
            if val:
                enabled_ids.append(item["id"])

    if not enabled_ids and len(providers) == 1 and vpn.get("enabled"):
        only = providers[0]
        if isinstance(only, dict) and only.get("id"):
            enabled_ids.append(only["id"])

    if enabled_ids and not vpn.get("selectedProvider"):
        vpn["selectedProvider"] = enabled_ids[0]
        notes.append(f"utilities.vpn.selectedProvider set to {enabled_ids[0]!r}")


def apply_migrations(cfg: dict[str, Any]) -> list[str]:
    """Apply every known stale-key migration in place. Returns human-readable notes."""
    notes: list[str] = []
    _migrate_use_twelve_hour_clock(cfg, notes)
    _migrate_vpn_provider_enabled(cfg, notes)
    return notes


# --------------------------------------------------------------------------- #
# Merge (user wins) and reporting
# --------------------------------------------------------------------------- #


def merge_missing(user: Any, example: Any, path: str, added: list[str]) -> None:
    """Copy keys present in `example` but absent in `user`. User wins for all else.

    Arrays are never merged item-wise: if the user has the key, their array is
    kept intact. New keys are appended at the end of their level (dict order is
    preserved by Python; existing user keys keep their positions).
    """
    if not isinstance(user, dict) or not isinstance(example, dict):
        return
    for key, ex_val in example.items():
        child = f"{path}.{key}" if path else key
        if key not in user:
            user[key] = copy.deepcopy(ex_val)
            added.append(child)
        elif isinstance(user[key], dict) and isinstance(ex_val, dict):
            merge_missing(user[key], ex_val, child, added)
        # else: leaf / array / type conflict -> user wins wholesale


def _all_paths(obj: Any, path: str, out: set[str]) -> None:
    if path:
        out.add(path)
    if isinstance(obj, dict):
        for key, val in obj.items():
            _all_paths(val, f"{path}.{key}" if path else key, out)


def unknown_keys(user: dict[str, Any], example: dict[str, Any]) -> list[str]:
    """Dotted paths present in `user` but absent from `example` (informational)."""
    user_paths: set[str] = set()
    example_paths: set[str] = set()
    _all_paths(user, "", user_paths)
    _all_paths(example, "", example_paths)
    return sorted(user_paths - example_paths)


# --------------------------------------------------------------------------- #
# Per-file driver
# --------------------------------------------------------------------------- #


def process_file(
    path: Path, example: dict[str, Any], *, dry_run: bool, check: bool
) -> None:
    with path.open(encoding="utf-8") as fh:
        user = json.load(fh)

    notes = apply_migrations(user)
    added: list[str] = []
    merge_missing(user, example, "", added)
    notes += apply_migrations(user)
    unknown = unknown_keys(user, example)

    print(f"== {path}")
    if notes:
        print("  migrations:")
        for n in notes:
            print(f"    - {n}")
    else:
        print("  migrations: none")
    if added:
        print("  added from example:")
        for a in added:
            print(f"    + {a}")
    else:
        print("  added: none")
    if unknown:
        print("  unknown keys (local, not in example):")
        for u in unknown:
            print(f"    ? {u}")
    else:
        print("  unknown keys: none")

    if check or dry_run:
        print("  not written (--check/--dry-run)")
        return

    text = json.dumps(user, indent=4, ensure_ascii=False) + "\n"
    original = path.read_text(encoding="utf-8")
    if text == original:
        print("  unchanged")
    else:
        path.write_text(text, encoding="utf-8")
        print("  updated")


# --------------------------------------------------------------------------- #
# CLI
# --------------------------------------------------------------------------- #


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(
        description=(
            "Merge the official caelestia-shell example config into local "
            "shell.json sources without overwriting already-set values."
        )
    )
    ap.add_argument(
        "targets",
        nargs="+",
        type=Path,
        help="caelestia shell.json config files to update",
    )
    ap.add_argument(
        "--example",
        type=Path,
        default=None,
        help="read the example config from a local JSON file (offline mode)",
    )
    ap.add_argument(
        "--readme",
        default=None,
        metavar="URL",
        help=f"README URL to fetch the example from (default: {DEFAULT_README_URL})",
    )
    ap.add_argument(
        "--dry-run",
        action="store_true",
        help="report what would change, do not write files",
    )
    ap.add_argument(
        "--check",
        action="store_true",
        help="diagnostics only: migrations needed, keys to add, unknown keys",
    )
    args = ap.parse_args(argv)

    try:
        if args.example is not None:
            example = load_example_from_file(args.example)
        else:
            example = load_example_from_readme(args.readme or DEFAULT_README_URL)
    except (
        urllib.error.URLError,
        urllib.error.HTTPError,
        json.JSONDecodeError,
        ValueError,
        OSError,
    ) as exc:
        print(f"error: cannot load example config: {exc}", file=sys.stderr)
        return 2

    rc = 0
    for target in args.targets:
        try:
            process_file(target, example, dry_run=args.dry_run, check=args.check)
        except (OSError, json.JSONDecodeError) as exc:
            print(f"error: {target}: {exc}", file=sys.stderr)
            rc = 2
    return rc


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
