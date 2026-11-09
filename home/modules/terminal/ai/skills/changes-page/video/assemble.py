"""Cut the video check of a rounds page: title cards, captioned clips, one video per round + the full one.

Usage: python3 -I assemble.py <plan.json> <out dir> [--crf 31] [--max-mb 15] [--font F] [--font-bold F]

plan.json:
  {"clips": "<Playwright output dir>", "name": "proof",
   "intro": {"title": "Видео-проверка: круги 1–3", "text": "Снято с ветки …\\nДанные выдуманы. …"},
   "rounds": [{"n": 1, "title": "Круг 1 · Уборка", "text": "Что вы просили: …",
               "items": [{"title": "Рейс отменяется на любом этапе (#525)", "text": "Смотрите: …"},
                         {"clip": "operations-trip-undo", "caption": "Рейс: отмена и возврат (#525)"}]}]}

An item with `title` is a title card on the round's colour (an invisible change gets only a card,
whose text says why there is nothing to see). An item with `clip` is a recorded test: an existing
file, or a prefix of exactly one `<clips>/<prefix>*/video.webm` folder; the same clip may appear in
several rounds. Its caption sits at the bottom of the frame, prefixed with "Круг N · ".
`\\n` breaks a card line. Every round starts with its own card (title + text).

Writes <out>/<name>-round<N>.mp4 (embedded in the page, at most --max-mb each) and <out>/<name>.mp4
(the full video, intro + all rounds; given as a path in the reply, not embedded). Segments are cached
in <out>/cut/ by content, so a re-run only cuts what changed. Needs ffmpeg and a TrueType font;
on NixOS: nix-shell -p ffmpeg dejavu_fonts fontconfig.
"""
import argparse
import glob
import hashlib
import json
import os
import subprocess
import sys

ap = argparse.ArgumentParser()
ap.add_argument("plan")
ap.add_argument("out")
ap.add_argument("--crf", type=int, default=31, help="x264 quality; higher = smaller (31 keeps ~15 clips under 15 MB)")
ap.add_argument("--max-mb", type=float, default=15)
ap.add_argument("--font")
ap.add_argument("--font-bold")
ap.add_argument("--size", default="1440x900")
a = ap.parse_args()

# dark versions of the page's round colours (template.html --r1 … --r6); 0 = intro
BG = ["0x1b1e3a", "0x23277a", "0x6b3f00", "0x0f4d33", "0x6e1d43", "0x0a4553", "0x3a4400"]


def font(style):
    try:
        return subprocess.run(["fc-match", "-f", "%{file}", f"DejaVu Sans:{style}"],
                              check=True, capture_output=True, text=True).stdout
    except (OSError, subprocess.CalledProcessError):
        sys.exit("no font: pass --font/--font-bold or run inside nix-shell -p ffmpeg dejavu_fonts fontconfig")


F = a.font or font("book")
FB = a.font_bold or font("bold")
plan = json.load(open(a.plan, encoding="utf-8"))
cut = os.path.join(a.out, "cut")
os.makedirs(cut, exist_ok=True)
W, H = a.size.split("x")


def bg(n):
    return BG[0] if n == 0 else BG[(n - 1) % (len(BG) - 1) + 1]


def clip_path(c):
    if os.path.isfile(c):
        return os.path.abspath(c)
    m = glob.glob(os.path.join(plan["clips"], f"{glob.escape(c)}*", "video.webm"))
    if len(m) != 1:
        sys.exit(f"clip {c!r}: {len(m)} matches in {plan['clips']}, need exactly one")
    return m[0]


def run(args):
    subprocess.run(["ffmpeg", "-v", "error", "-y"] + args, check=True)


def text_file(key, s):
    p = os.path.join(cut, f"{key}.txt")
    open(p, "w", encoding="utf-8").write(s)
    return p


def seg(kind, n, x, y):
    """kind card: x title, y text; kind clip: x video path, y caption."""
    key = hashlib.sha1(json.dumps([kind, n, x, y, a.crf, a.size, F, FB,
                                   os.path.getmtime(x) if kind == "clip" else 0]).encode()).hexdigest()[:16]
    p = os.path.join(cut, f"{key}.mp4")
    if os.path.exists(p):
        return p
    enc = ["-c:v", "libx264", "-crf", str(a.crf), "-preset", "slow", "-pix_fmt", "yuv420p",
           "-c:a", "aac", "-b:a", "32k", p]
    silence = ["-f", "lavfi", "-i", "anullsrc=r=44100:cl=stereo", "-shortest"]
    if kind == "card":
        lines = y.count("\n") + 1
        dur = max(5, min(9, 3 + lines))
        bar = "drawbox=x=0:y=0:w=iw:h=10:color=white@0.85:t=fill," if n else ""
        vf = (bar + f"drawtext=fontfile={FB}:expansion=none:textfile={text_file(key + '-t', x)}:fontsize=40:"
              f"fontcolor=white:x=(w-tw)/2:y=h/2-140,"
              f"drawtext=fontfile={F}:expansion=none:textfile={text_file(key + '-b', y)}:fontsize=26:"
              f"fontcolor=0xe6e8f2:line_spacing=14:x=(w-tw)/2:y=h/2-40")
        run(["-f", "lavfi", "-i", f"color=c={bg(n)}:s={a.size}:d={dur}:r=25"] + silence + ["-vf", vf] + enc)
    else:
        vf = (f"scale={W}:{H},fps=25,drawbox=x=0:y=ih-56:w=iw:h=56:color={bg(n)}@0.92:t=fill,"
              f"drawtext=fontfile={F}:expansion=none:textfile={text_file(key + '-c', y)}:fontsize=26:"
              f"fontcolor=white:x=24:y=h-41")
        run(["-i", x] + silence + ["-vf", vf] + enc)
    return p


def concat(parts, out):
    lst = out + ".txt"
    open(lst, "w").write("".join(f"file '{p}'\n" for p in parts))
    run(["-f", "concat", "-safe", "0", "-i", lst, "-c", "copy", "-movflags", "+faststart", out])
    os.remove(lst)
    return os.path.getsize(out) / 1048576


name = plan.get("name", "proof")
everything = [seg("card", 0, plan["intro"]["title"], plan["intro"]["text"])] if plan.get("intro") else []
too_big = []
for k, r in enumerate(plan["rounds"], 1):
    n = r.get("n", k)
    parts = [seg("card", n, r["title"], r.get("text", ""))]
    for it in r["items"]:
        if "clip" in it:
            cap = it.get("caption", it["clip"])
            if not cap.startswith(f"Круг {n}"):
                cap = f"Круг {n} · {cap}"
            parts.append(seg("clip", n, clip_path(it["clip"]), cap))
        else:
            parts.append(seg("card", n, it["title"], it.get("text", "")))
    out = os.path.join(a.out, f"{name}-round{n}.mp4")
    mb = concat(parts, out)
    print(f"{out}: {mb:.1f} MB")
    if mb > a.max_mb:
        too_big.append(out)
    everything += parts
full = os.path.join(a.out, f"{name}.mp4")
print(f"{full}: {concat(everything, full):.1f} MB (full video, not embedded)")
if too_big:
    sys.exit(f"over {a.max_mb} MB: {too_big}; re-run with --crf {a.crf + 3} (or split the round)")
