# Changes page

A published page (Artifact) that shows what a branch, a batch of PRs or a thread changed: for
every change, what the thing is, how it was, how it is now, why, a "before" and an "after"
screenshot of the same screen, and how to use it. A contents menu on the left lists every group
and change; clicking one jumps to it, and the entry of the card in view is highlighted. The owner
reads it to review the work without reproducing anything.

Use it when the owner asks to show the changes ("покажи, что изменилось", "до и после",
"сделай страницу/артефакт с изменениями"), and offer it in one line after a batch of several
user-visible PRs. For one small change, screenshots in the reply (`catch-up`) are enough.

`template.html` and `build.py` sit next to this file (`~/.claude/skills/changes-page/` or
`~/.config/opencode/skills/changes-page/`). Never hand-write the page: fill `changes.json` and build.

## 1. List the changes

- Base and head: what the owner compares (`main` vs the branch, or the state before the thread).
  `git log --oneline <base>..<head>`, the PRs (`gh pr list --state all --base <branch>`), their
  issues (the why and the acceptance), `gh pr diff`.
- One entry per change a person can see. A backend-only change goes where its effect shows (a
  status, a warning, a log); a pure refactor gets no entry.
- Group by the path the user walks (e.g. quotation → order → trip → invoice → closing), not by
  PR number. Each group gets a one-line `short` (the flow strip) and an `intro` that teaches it.
- A fix of an earlier version of the same branch (owner review) gets its own entry with
  `badge` (e.g. «Исправлено по вашему ревью») and `beforeLabel: "В первой версии ветки"`; the
  older change's "after" picture shows the new look.
- Every fact must be true in the head code. Read it, do not guess.

## 2. Screenshots

- Two stacks, one per side: a detached worktree of base and of head, each with its own DB and
  ports, in the scratchpad. Never a shared or production server. Made-up data only (invented
  companies and people), never real customers. Seed both sides the same way so the difference is
  the only difference.
- Use the project's own e2e/screenshot tooling when it has one (Playwright specs, seed helpers);
  otherwise a Playwright script or the preview tools. Same screen, same viewport on both sides.
- Draw a red frame around what changed (an absolutely positioned div, `4px solid #e11d48`,
  radius 10px, 6px outside the element) on "after", and on "before" where something is missing
  or wrong. When base has no such screen, "before" is the closest screen with the empty spot
  framed; if nothing is close, no "before" picture and say so in `before`.
- A PDF: render page 1 (`pdftoppm -png -r 80 -f 1 -l 1`). A letter or a job: screenshot where it
  is visible (preview, journal, history).
- Names: `<id>-before.png`, `<id>-after.png`, then `-after2`, … At most 3 per side per change.
- Look at every PNG with the Read tool. Redo it until the frame sits on the right thing and the
  picture shows what the caption says.

Many changes (more than ~8): split by group across subagents. Give each the same brief: its
changes with PRs and issues, the two stacks (URLs, DB names, passwords), the screenshot rules
above, the writing rules below, its output file `changes-<group>.json` and picture prefix. They
write only in the scratchpad: no commits, pushes, deploys or app code changes, and no restarting
the shared stacks. Merge their JSON into one `changes.json`.

## 3. Writing (the part that matters most)

The reader may not know the feature at all. The page teaches, it does not report. Russian unless
the owner writes otherwise.

- `what`: what this thing IS, from zero, as to a new employee: what it is, who works with it, why
  it exists. 2–3 sentences.
- `before`: what was there, in plain words, and what was bad about it. 1–3 sentences.
- `after`: what the person sees and can do now. 1–3 sentences.
- `why`: one sentence: what goes wrong without it.
- `howto`: 2–5 steps, one action each ("Откройте …", "Нажмите …"), screen and button names
  exactly as the UI shows them.
- Short sentences (≤ 15 words), one idea each. No internals: no table, field, class, endpoint or
  permission names, no "fallback", no chains "first X, then Y, then Z". Describe what the person
  sees, not how the code decides.
- Every abbreviation gets its plain name at least once per change: «заказ клиента (SO)». Put the
  domain terms in `glossary`.
- `short`: the menu label, 3–6 words. The menu is how the owner navigates a long page.
- Numbers only in examples ("счёт на 1210 €: 1000 € + 210 € НДС").
- Bugs or doubts found on the way go to `notes`, same plain style.

## 4. changes.json

```json
{
  "title": "Ветка order-flow против main",
  "h1": "Что нового в ветке order-flow",
  "eyebrow": "integration/order-flow → main · 26 изменений",
  "intro": ["Абзац: что за ветка, как читать картинки (слева было, справа стало, красная рамка), данные выдуманные."],
  "legendBadge": "Исправлено по вашему ревью",
  "path": {"title": "Как идёт один заказ", "text": "Каждое изменение ниже относится к одному из шагов."},
  "glossaryTitle": "Словарь: SO, KR, IK…",
  "glossary": [["Заказ клиента, SO", "проданная перевозка: клиент, цена, маржа."]],
  "groups": [
    {"id": "g1", "title": "Заказ клиента (SO)", "short": "одна строка для полосы шагов", "intro": "что это за шаг",
     "changes": [
       {"id": "a357", "title": "Номера заказов система выдаёт сама", "short": "Номера сами",
        "who": "Продажи; FWD", "badge": null, "beforeLabel": "Как было",
        "refs": [{"label": "PR #376", "url": "https://github.com/<owner>/<repo>/pull/376"}],
        "what": "…", "before": "…", "after": "…", "why": "…", "howto": ["…", "…"],
        "images": [{"file": "a357-before.png", "side": "before", "caption": "одно предложение"},
                   {"file": "a357-after.png", "side": "after", "caption": "одно предложение"}]}
     ]}
  ],
  "notes": {"title": "Что ещё заметили по дороге", "intro": "Это не входит в изменения выше.",
            "items": [{"title": "Надо сверить", "text": "…"}]}
}
```

Required: `title`, `groups[].title`, `changes[].id` (unique, a valid HTML id), `title`, `before`,
`after`. Everything else is optional and is left out of the page when missing. `path` shows only
with two or more groups. Before and after pictures are paired in order; extra ones stand alone.

## 5. Build and publish

```bash
python3 -I <skill dir>/build.py <scratch>/changes.json <scratch>/shots <scratch>/page
```

It writes `page/index.html`, copies the used pictures to `page/img/`, writes `page/files.json`
(the `files` map) and fails on a missing picture or a duplicate id. Then:

- Follow the Artifact tool's rules (load `artifact-design` once; the template already carries the
  page contract: title, theme tokens, dark mode, phone layout).
- Publish `page/index.html` with `files` = the map in `files.json`, `icon: "compare"`, a
  one-sentence `description`. One publish takes at most 255 files; split larger sets over
  several publishes to the same URL.
- A redo (new review round, more changes) republishes to the SAME URL, so the owner's link keeps
  working. Rebuild from the updated JSON; do not patch the HTML by hand.
- Optionally check the page at desktop and phone width (menu jumps, highlight, no sideways
  scroll) before sending the link.

## 6. The reply

The link, then in a few lines: how many changes and pictures, how the page is organised, what is
made up or seeded by hand, and what waits for the owner (bugs found, things to compare with the
old system). Do not repeat the page in the reply.

Done means: every user-visible change has an entry with true facts, every picture was looked at,
the page is published, and the owner has the link.
