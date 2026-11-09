"""Build the before/after page from changes.json.

Usage: python3 -I build.py <changes.json> <shots dir> <out dir>

Writes <out>/index.html, copies every referenced picture to <out>/img/ and writes
<out>/files.json: the `files` map for the Artifact publish ({"img/x.png": "<abs path>"}).
With `groups` the page is one batch; with `rounds` it is split into review rounds, each with its
own colour, ask, video and agent decisions. The JSON format is described in SKILL.md.
"""
import html
import json
import os
import shutil
import sys

e = html.escape
spec_path, shots, out = sys.argv[1:4]
spec = json.load(open(spec_path, encoding="utf-8"))
template = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "template.html"), encoding="utf-8").read()
os.makedirs(os.path.join(out, "img"), exist_ok=True)
used = {}
missing = []
ROUND_COLOURS = 6      # .r1 … .r6 in template.html; later rounds reuse them
VIDEO_MAX_MB = 15      # the Artifact player loads the whole file; keep a round's video small


def png_size(path):
    # width/height on <img> reserve the space, so lazy pictures loading later do not
    # push the page away from a menu jump.
    with open(path, "rb") as f:
        head = f.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        return ""
    return f' width="{int.from_bytes(head[16:20], "big")}" height="{int.from_bytes(head[20:24], "big")}"'


def fig(i):
    src = os.path.join(shots, i["file"])
    size = ""
    if not os.path.isfile(src):
        missing.append(i["file"])
    else:
        dst = os.path.join(out, "img", os.path.basename(i["file"]))
        shutil.copy(src, dst)
        used[f'img/{os.path.basename(i["file"])}'] = os.path.abspath(dst)
        size = png_size(src)
    name = e(os.path.basename(i["file"]))
    tag = "Было" if i["side"] == "before" else "Стало"
    return (f'<figure class="{i["side"]}"><span class="tag">{tag}</span>'
            f'<button class="zoom" type="button" data-src="img/{name}" aria-label="Открыть картинку крупно">'
            f'<img src="img/{name}"{size} alt="{e(i["caption"])}" loading="lazy"></button>'
            f'<figcaption>{e(i["caption"])}</figcaption></figure>')


def pairs(c):
    before = [i for i in c.get("images", []) if i["side"] == "before"]
    after = [i for i in c.get("images", []) if i["side"] == "after"]
    rows = []
    for k in range(max(len(before), len(after))):
        if k < len(before) and k < len(after):
            rows.append(f'<div class="pair">{fig(before[k])}{fig(after[k])}</div>')
        else:
            i = before[k] if k < len(before) else after[k]
            rows.append(f'<div class="pair"><div class="solo {i["side"]}">{fig(i)}</div></div>')
    return f'<div class="pairs">{"".join(rows)}</div>' if rows else ""


def video(v):
    src = v["file"] if os.path.isabs(v["file"]) else os.path.join(shots, v["file"])
    name = os.path.basename(v["file"])
    if not os.path.isfile(src):
        missing.append(v["file"])
    elif os.path.getsize(src) > VIDEO_MAX_MB * 1024 * 1024:
        sys.exit(f"{name} is {os.path.getsize(src) / 1048576:.1f} MB, over {VIDEO_MAX_MB} MB: "
                 "re-encode it with a higher crf (video/assemble.py --crf)")
    else:
        os.makedirs(os.path.join(out, "video"), exist_ok=True)
        dst = os.path.join(out, "video", name)
        shutil.copy(src, dst)
        used[f"video/{name}"] = os.path.abspath(dst)
    return (f'<figure class="proof"><video controls preload="metadata" playsinline src="video/{e(name)}"></video>'
            + (f'<figcaption>{e(v["caption"])}</figcaption>' if v.get("caption") else "") + "</figure>")


def rc(n):
    return f"r{(n - 1) % ROUND_COLOURS + 1}"


def card(c, n=None):
    badge = c.get("badge")
    meta = [f'<span class="chip round">Круг {n}</span>'] if n else []
    if badge:
        meta.append(f'<span class="chip fix">{e(badge)}</span>')
    if c.get("who"):
        meta.append(f'<span>Для кого: {e(c["who"])}</span>')
    for ref in c.get("refs", []):
        meta.append(f'<a class="ref" href="{e(ref["url"])}">{e(ref["label"])}</a>')
    links = []
    for later in changed_by(c) if n else []:
        links.append(f'<a class="later {rc(ROUND[later])}" href="#{e(later)}">'
                     f'Изменено в круге {ROUND[later]} → {e(SHORT[later])}</a>')
    for p in EARLIER.get(c["id"], []):
        links.append(f'<a class="earlier {rc(ROUND[p])}" href="#{e(p)}">← меняет круг {ROUND[p]}: {e(SHORT[p])}</a>')
    parts = [f'<header><div class="meta">{"".join(meta)}</div><h3>{e(c["title"])}</h3>'
             + (f'<div class="links">{"".join(links)}</div>' if links else "") + "</header>"]
    if c.get("what"):
        parts.append(f'<p class="what"><b>Что это.</b> {e(c["what"])}</p>')
    parts.append(f'<div class="compare"><div class="was"><h4>{e(c.get("beforeLabel", "Как было"))}</h4>'
                 f'<p>{e(c["before"])}</p></div><div class="now"><h4>Что стало</h4><p>{e(c["after"])}</p></div></div>')
    if c.get("why"):
        parts.append(f'<p class="why"><b>Зачем:</b> {e(c["why"])}</p>')
    parts.append(pairs(c))
    if c.get("howto"):
        steps = "".join(f"<li>{e(h)}</li>" for h in c["howto"])
        parts.append(f'<div class="howto"><h4>Как пользоваться</h4><ol>{steps}</ol></div>')
    cls = "change badged" if badge else "change"
    return f'<article class="{cls}" id="{e(c["id"])}">\n' + "\n".join(p for p in parts if p) + "\n</article>"


def changed_by(c):
    v = c.get("changedBy") or []
    return [v] if isinstance(v, str) else v


def check_ids(ids):
    dupes = {i for i in ids if ids.count(i) > 1}
    if dupes:
        sys.exit(f"duplicate change ids: {sorted(dupes)}")


def note_items(items):
    return "".join(f'<li><strong>{e(x["title"])}.</strong> {e(x["text"])}</li>' for x in items)


ROUND, SHORT, EARLIER = {}, {}, {}   # change id -> round, menu label; later id -> earlier ids it changes
questions = []                       # open questions from the rounds' decisions, repeated in the notes
toc, steps, body = [], [], []
rounds = spec.get("rounds")

if rounds:
    for k, r in enumerate(rounds, 1):
        r.setdefault("n", k)
        r.setdefault("id", f'round{r["n"]}')
        for c in r["changes"]:
            ROUND[c["id"]], SHORT[c["id"]] = r["n"], c.get("short", c["title"])
    ids = [c["id"] for r in rounds for c in r["changes"]]
    check_ids(ids)
    for r in rounds:
        for c in r["changes"]:
            for later in changed_by(c):
                if later not in ROUND:
                    sys.exit(f'{c["id"]}.changedBy: unknown change id {later}')
                if ROUND[later] <= r["n"]:
                    sys.exit(f'{c["id"]}.changedBy: {later} is not in a later round')
                EARLIER.setdefault(later, []).append(c["id"])

    for r in rounds:
        n, rid, cls = r["n"], r["id"], rc(r["n"])
        sub, cards, lane = [], [], None
        for c in r["changes"]:
            if c.get("lane") and c["lane"] != lane:
                lane = c["lane"]
                sub.append(f'<li class="lane">{e(lane.split(" · ")[0])}</li>')
                cards.append(f'<h3 class="lane-h">{e(lane)}</h3>')
            sub.append(f'<li><a href="#{e(c["id"])}">{e(c.get("short", c["title"]))}</a></li>')
            cards.append(card(c, n))
        dec = ""
        if r.get("decisions"):
            did = f"{rid}-dec"
            sub.append(f'<li><a href="#{did}"><span class=dot></span>Решения агентов</a></li>')
            items = []
            for x in r["decisions"]:
                later = x.get("changedIn")
                tail = (f' <span class="changed {rc(later["round"])}">Изменено в круге {later["round"]}: '
                        f'{e(later["text"])}</span>' if later else "")
                q = ' <span class="chip q">Вопрос вам</span>' if x.get("question") else ""
                items.append(f'<li><strong>{e(x["title"])}.</strong>{q} {e(x["text"])}{tail}</li>')
                if x.get("question") and not later:
                    questions.append({"title": f'Открытый вопрос вам (круг {n})', "text": f'{x["title"]}. {x["text"]}'})
            dec = (f'<section class="notes" id="{did}"><h2>Решения, которые агенты приняли за вас — круг {n}</h2>'
                   f'<p>Это вы явно не решали. Каждое легко поменять.</p><ul>{"".join(items)}</ul></section>')
        toc.append(f'<li class="rnd {cls}"><a class="grp" href="#{e(rid)}"><span class="n">{n}</span>{e(r["title"])}</a>'
                   f'<ol>{"".join(sub)}</ol></li>')
        steps.append(f'<li class="rnd {cls}"><a href="#{e(rid)}">{e(r["title"])}</a>'
                     f'<span>{e(r.get("short", ""))}{" · " if r.get("short") else ""}{len(r["changes"])} изм.</span></li>')
        ask = f'<p class="ask">{e(r["ask"])}</p>' if r.get("ask") else ""
        vid = video(r["video"]) if r.get("video") else ""
        body.append(f'<section class="group rnd {cls}" id="{e(rid)}"><div class="group-head">'
                    f'<h2><span class="step">{n}</span>{e(r["title"])}</h2>{ask}{vid}</div>'
                    + "".join(cards) + dec + "</section>")
    path = spec.get("path") or {"title": "Круги правок",
                                "text": "Каждый круг — свой цвет. Сверху круга — что вы просили и видео-проверка."}
    legend = "".join(f'<span class="chip round {rc(r["n"])}">Круг {r["n"]}</span>' for r in rounds)
else:
    groups = spec["groups"]
    ids = [c["id"] for g in groups for c in g["changes"]]
    check_ids(ids)
    for n, g in enumerate(groups, 1):
        gid = g.get("id", f"g{n}")
        sub = "".join(
            f'<li><a href="#{e(c["id"])}">{"<span class=dot></span>" if c.get("badge") else ""}{e(c.get("short", c["title"]))}</a></li>'
            for c in g["changes"])
        toc.append(f'<li><a class="grp" href="#{e(gid)}"><span class="n">{n}</span>{e(g["title"])}</a><ol>{sub}</ol></li>')
        steps.append(f'<li><a href="#{e(gid)}">{e(g["title"])}</a><span>{e(g.get("short", ""))}</span></li>')
        head = f'<h2><span class="step">{n}</span>{e(g["title"])}</h2>' + (f'<p>{e(g["intro"])}</p>' if g.get("intro") else "")
        body.append(f'<section class="group" id="{e(gid)}"><div class="group-head">{head}</div>'
                    + "".join(card(c) for c in g["changes"]) + "</section>")
    path = spec.get("path") if len(groups) > 1 else None
    legend = '<span class="chip fix">' + e(spec["legendBadge"]) + "</span>" if spec.get("legendBadge") else ""

notes_html = ""
notes = spec.get("notes") or ({"items": []} if questions else None)
if notes:
    title = notes.get("title", "Что ещё заметили")
    toc.append(f'<li><a class="grp" href="#notes"><span class="n">!</span>{e(title)}</a></li>')
    lead = f'<p>{e(notes["intro"])}</p>' if notes.get("intro") else ""
    notes_html = (f'<section class="notes" id="notes"><h2>{e(title)}</h2>{lead}'
                  f'<ul>{note_items(questions + notes["items"])}</ul></section>')

path_html = ""
if path:
    gloss = ""
    if spec.get("glossary"):
        dl = "".join(f"<dt>{e(t)}</dt><dd>{e(d)}</dd>" for t, d in spec["glossary"])
        gloss = f'<details class="gloss"><summary>{e(spec.get("glossaryTitle", "Словарь терминов"))}</summary><dl>{dl}</dl></details>'
    path_html = (f'<section class="path" aria-labelledby="path-h"><h2 id="path-h">{e(path["title"])}</h2>'
                 + (f'<p>{e(path["text"])}</p>' if path.get("text") else "")
                 + f'<ol class="steps{" rounds" if rounds else ""}">{"".join(steps)}</ol>{gloss}</section>')

intro = "".join(f"<p>{e(p)}</p>" for p in spec.get("intro", []))
page = (template.replace("{{TITLE}}", e(spec["title"]))
        .replace("{{EYEBROW}}", e(spec.get("eyebrow", f"{len(ids)} изменений")))
        .replace("{{H1}}", e(spec.get("h1", spec["title"])))
        .replace("{{INTRO}}", intro)
        .replace("{{LEGEND}}", legend)
        .replace("{{TOC}}", f'<ol>{"".join(toc)}</ol>')
        .replace("{{PATH}}", path_html)
        .replace("{{BODY}}", "".join(body))
        .replace("{{NOTES}}", notes_html))
open(os.path.join(out, "index.html"), "w", encoding="utf-8").write(page)
json.dump(used, open(os.path.join(out, "files.json"), "w"), indent=1)
print(f"{len(ids)} changes, {len(used)} files -> {os.path.join(out, 'index.html')}")
if missing:
    sys.exit(f"missing files: {missing}")
