"""Emoji picker: rofi grid with category tabs and a frecency-sorted "all" tab.

Without arguments it opens rofi; rofi calls this same script back as a script
mode for every tab (argv[1] = tab key). The chosen character is written to a
result file and typed only after rofi exits, because rofi holds the keyboard
while it is open.
"""

import json
import os
import re
import subprocess
import sys
import time
from glob import glob
from pathlib import Path

ROFI = "@rofi@"
WTYPE = "@wtype@"
WL_COPY = "@wlCopy@"
THEME = "@theme@"
DATA = Path(glob("@rofimoji@/lib/python3*/site-packages/picker/data")[0])

STATE = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "emoji-picker"
FRECENCY = STATE / "frecency.json"
RESULT = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "emoji-picker.result"

# tab key -> (label shown in rofi, data files)
TABS = {
    "all": ("🕘", [f"emojis_{c}" for c in (
        "smileys_emotion", "people_body", "animals_nature", "food_drink",
        "activities", "travel_places", "objects", "symbols", "flags",
    )]),
    "smileys": ("😀", ["emojis_smileys_emotion"]),
    "people": ("👋", ["emojis_people_body"]),
    "nature": ("🐶", ["emojis_animals_nature"]),
    "food": ("🍔", ["emojis_food_drink"]),
    "activities": ("⚽", ["emojis_activities"]),
    "travel": ("✈️", ["emojis_travel_places"]),
    "objects": ("💡", ["emojis_objects"]),
    "symbols": ("🔣", ["emojis_symbols"]),
    "flags": ("🚩", ["emojis_flags"]),
    "glyphs": ("󰣇", ["nerd_font"]),
}

FREQUENT_LIMIT = 40


def load(name):
    entries = []
    for line in (DATA / f"{name}.csv").read_text().splitlines():
        if not line.strip():
            continue
        char, _, desc = line.partition(" ")
        desc = re.sub(r"</?small>|[()]", "", desc)
        entries.append((char.strip(), desc.strip()))
    return entries


def load_frecency():
    try:
        return json.loads(FRECENCY.read_text())
    except (FileNotFoundError, json.JSONDecodeError):
        return {}


def score(item):
    # Count decays with age in weeks, so old favourites slowly give way to new ones
    count, last, _ = item
    return count / (1 + (time.time() - last) / 86400 / 7)


def mode(tab):
    retv = int(os.environ.get("ROFI_RETV", "0"))
    if retv == 1:
        RESULT.write_text(os.environ.get("ROFI_INFO", ""))
        return  # no rows -> rofi exits

    _, files = TABS[tab]
    entries = [e for f in files for e in load(f)]

    if tab == "all":
        frequent = sorted(load_frecency().items(), key=lambda kv: score(kv[1]), reverse=True)
        top = [(char, desc) for char, (_, _, desc) in frequent[:FREQUENT_LIMIT]]
        seen = {char for char, _ in top}
        entries = top + [e for e in entries if e[0] not in seen]

    print("\0no-custom\x1ftrue")
    for char, desc in entries:
        # Only the character is shown; the name is searchable via meta
        print(f"{char}\0meta\x1f{desc}\x1finfo\x1f{char}\t{desc}")


def remember(char, desc):
    data = load_frecency()
    count = data.get(char, (0, 0, ""))[0]
    data[char] = (count + 1, time.time(), desc)
    FRECENCY.write_text(json.dumps(data, ensure_ascii=False))


def main():
    STATE.mkdir(parents=True, exist_ok=True)

    if len(sys.argv) > 1 and sys.argv[1] in TABS:
        mode(sys.argv[1])
        return

    RESULT.unlink(missing_ok=True)
    script = os.path.realpath(sys.argv[0])
    modi = ",".join(f"{label}:{script} {key}" for key, (label, _) in TABS.items())
    subprocess.run([
        ROFI, "-modi", modi, "-show", TABS["all"][0], "-theme", THEME,
        # Arrows move through the grid, not the search text cursor
        "-kb-move-char-back", "Control+b",
        "-kb-move-char-forward", "Control+f",
        "-kb-row-left", "Left,Control+Page_Up",
        "-kb-row-right", "Right,Control+Page_Down",
    ])

    if not RESULT.exists():
        return
    char, _, desc = RESULT.read_text().partition("\t")
    RESULT.unlink()
    if not char:
        return

    remember(char, desc)
    subprocess.run([WL_COPY, char])
    time.sleep(0.05)  # let the focus return to the previous window
    subprocess.run([WTYPE, char])


if __name__ == "__main__":
    main()
