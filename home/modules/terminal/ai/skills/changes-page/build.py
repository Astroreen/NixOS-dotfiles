"""Build the before/after page from changes.json.

Usage: python3 -I build.py <changes.json> <shots dir> <out dir>

Writes <out>/index.html, copies every referenced picture to <out>/img/ and writes
<out>/files.json: the `files` map for the Artifact publish ({"img/x.png": "<abs path>"}).
The JSON format is described in SKILL.md.
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


def card(c):
    badge = c.get("badge")
    meta = []
    if badge:
        meta.append(f'<span class="chip fix">{e(badge)}</span>')
    if c.get("who"):
        meta.append(f'<span>Для кого: {e(c["who"])}</span>')
    for ref in c.get("refs", []):
        meta.append(f'<a class="ref" href="{e(ref["url"])}">{e(ref["label"])}</a>')
    parts = [f'<header><div class="meta">{"".join(meta)}</div><h3>{e(c["title"])}</h3></header>']
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


groups = spec["groups"]
ids = [c["id"] for g in groups for c in g["changes"]]
dupes = {i for i in ids if ids.count(i) > 1}
if dupes:
    sys.exit(f"duplicate change ids: {sorted(dupes)}")

toc, steps, body = [], [], []
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

notes_html = ""
notes = spec.get("notes")
if notes:
    toc.append(f'<li><a class="grp" href="#notes"><span class="n">!</span>{e(notes.get("title", "Что ещё заметили"))}</a></li>')
    items = "".join(f'<li><strong>{e(x["title"])}.</strong> {e(x["text"])}</li>' for x in notes["items"])
    lead = f'<p>{e(notes["intro"])}</p>' if notes.get("intro") else ""
    notes_html = f'<section class="notes" id="notes"><h2>{e(notes.get("title", "Что ещё заметили"))}</h2>{lead}<ul>{items}</ul></section>'

path_html = ""
path = spec.get("path")
if path and len(groups) > 1:
    gloss = ""
    if spec.get("glossary"):
        dl = "".join(f"<dt>{e(t)}</dt><dd>{e(d)}</dd>" for t, d in spec["glossary"])
        gloss = f'<details class="gloss"><summary>{e(spec.get("glossaryTitle", "Словарь терминов"))}</summary><dl>{dl}</dl></details>'
    path_html = (f'<section class="path" aria-labelledby="path-h"><h2 id="path-h">{e(path["title"])}</h2>'
                 + (f'<p>{e(path["text"])}</p>' if path.get("text") else "")
                 + f'<ol class="steps">{"".join(steps)}</ol>{gloss}</section>')

legend = '<span class="chip fix">' + e(spec["legendBadge"]) + "</span>" if spec.get("legendBadge") else ""
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
print(f"{len(ids)} changes, {len(used)} pictures -> {os.path.join(out, 'index.html')}")
if missing:
    sys.exit(f"missing pictures: {missing}")
