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
`~/.config/opencode/skills/changes-page/`), the video tools in `video/`. Never hand-write the page:
fill `changes.json` and build.

Two shapes of the page:

- **One batch** (`groups`): the first page for a branch or a batch of PRs.
- **Rounds** (`rounds`): the batch got a second (third, …) round of fixes after the owner looked at
  the page or its video and sent remarks. Switch to rounds from round 2 on, rebuild the whole page
  (round 1 = the earlier `groups`, its cards unchanged, each with a `lane`) and republish to the
  same URL. Each round gets a colour, what the owner asked, its own video check and its agent
  decisions; a card that a later round changed stays in place and links to the change. See §5.

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
  older change's "after" picture shows the new look. Once the owner sends a whole round of
  remarks on the page or its video, switch to rounds (§5) instead of badges.
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

## 5. Rounds (second and later rounds of fixes)

Top level is `rounds[]` instead of `groups[]`; everything else in §4 stays (`title`, `h1`,
`eyebrow`, `intro`, `glossary`, `notes`). Round 1 holds the cards of the first page.

```json
{
  "title": "…", "h1": "Что меняют три PR уборки — по кругам", "eyebrow": "PR #535 · #537 → main · круг 1: 12 · круг 2: 9",
  "intro": ["…; страница по кругам, у каждого свой цвет; вверху круга — что вы просили и его видео."],
  "path": {"title": "Три круга", "text": "Круг 1 — уборка, круги 2 и 3 — ваши замечания к видео."},
  "rounds": [
    {"id": "round1", "n": 1, "title": "Круг 1 · Уборка", "short": "уборка по трём правилам",
     "ask": "Что вы просили: навести порядок по трём правилам …",
     "video": {"file": "/abs/or/shots-relative/proof-round1.mp4", "caption": "Видео круга 1: …"},
     "changes": [
       {"id": "c525", "lane": "Рейсы и IK · PR #535", "title": "…", "short": "…", "changedBy": ["c548-arrows"],
        "who": "…", "refs": [], "what": "…", "before": "…", "after": "…", "why": "…", "howto": [], "images": []}
     ],
     "decisions": [
       {"title": "Рейсы и IK: кто отменяет рейс", "text": "…",
        "changedIn": {"round": 2, "text": "открывает только тот, кто может менять"}},
       {"title": "Котировки: отменить может каждый, кто видит", "text": "Требовать право? …", "question": true}
     ]},
    {"n": 2, "title": "Круг 2 · Замечания к первому видео", "ask": "Что вы просили: …", "changes": ["…"]}
  ],
  "notes": {"title": "Что ещё стоит знать", "items": [{"title": "Порядок слияния", "text": "…"}]}
}
```

- `n` (default: position), `id` (default `round<n>`), `title` and `changes` per round. Optional:
  `short` (flow strip), `ask`, `video`, `decisions`. Colours: rounds 1–6 have their own, light and
  dark (`--r1`…`--r6` in `template.html`), later ones reuse them.
- `ask`: one line, «Что вы просили: …», the owner's remarks for this round in their words, short.
- `lane`: the lane or PR a card belongs to (`"Деньги · PR #543"`). Consecutive cards with the same
  lane get a subheading; the menu shows the part before ` · `. Keep a round's cards ordered by lane.
- `changedBy` (string or list) goes on the OLD card only: the ids of later-round cards that change
  it. The old card shows «Изменено в круге N → <short>», the new one gets «← меняет круг N: …» by
  itself. The build fails on an unknown id or one that is not in a later round. Never move or
  delete the old card: the owner reads the history in place.
- `decisions`: what the agents decided for the owner in this round, one yellow block per round.
  Mark a decision a later round reversed with `changedIn` («Изменено в круге N: …»), do not delete
  it. `question: true` marks an open question to the owner: it gets a chip and is repeated in the
  final notes (unless already `changedIn`).
- Before/after pictures stay paired as in §2; for later rounds take them from the round's PR
  descriptions (they usually carry before/after shots) or shoot them as in §2.
- `video.file`: the round's video from §6, at most 15 MB (the build fails above that). A relative
  path is read from the shots dir. It is published as `video/<name>`.

## 6. Video check per round

One video per round, embedded at the top of the round, plus the full video (all rounds) as a file
whose path goes in the reply. Recorded from ONE branch that holds every round (the integration
branch), so the screens are in their latest state; a title card says so where it matters.

Rules (all required, the owner checks them):

- 1 s pause between actions; 1 more second before every navigation (goto, reload, back, forward),
  except the `/login` after the cookies were dropped (a pause there breaks the login).
- The mouse glides (~0.8 s), never jumps. A red marker appears exactly where and when the real
  press happens (drawn on `mousedown`, no lagging CSS animation).
- The last screen of every check stays 2.5 s.
- Made-up data on a local stack only; never a shared or production server.

Tools in `video/` (portable, nothing project-specific):

- `preload.cjs`: patches the playwright-core client via `NODE_OPTIONS=--require`: wraps
  `Frame.prototype` actions (click, fill, …, goto) and `Page.prototype` reload/goBack/goForward,
  adds the cursor with an init script. Does all the rules above; the specs stay unchanged.
  Tunables: `VIDEO_PAUSE_MS`, `VIDEO_GLIDE_MS`, `VIDEO_HOLD_MS`, `VIDEO_NO_PAUSE_URLS` (default
  `/login`), `PLAYWRIGHT_CORE_DIR` (default: resolved from the cwd).
- `playwright.video.config.ts`: copy next to the project's `playwright.config.ts` (scratch copy or
  worktree, never committed); 1 worker, 1440×900 video of every test, output in `VIDEO_OUT`.
- `assemble.py`: title cards and captions, cut with ffmpeg per round and in full. Its docstring
  has the `plan.json` format.

How:

1. Bring up the app on a local stack the way the project's README / AGENTS.md / e2e docs say (own
   DB and ports in the scratchpad, seed data). That part is per project; never guess it.
2. Pick the existing e2e specs that walk each change (write a small one in the scratchpad when none
   does). Run them:
   ```bash
   cd <frontend dir> && cp <skill>/video/playwright.video.config.ts . && \
   VIDEO_OUT=<scratch>/vid NODE_OPTIONS="--require <skill>/video/preload.cjs" \
     npx playwright test -c playwright.video.config.ts <specs…>
   ```
3. Write `plan.json`: per round a card (title = round title, text = what the owner asked), then
   per change a card «<change> (#PR)» with «Смотрите: …» (what to watch, in order) and its clip(s);
   the caption at the bottom reads «Круг N · …». A clip two rounds need may repeat with another
   caption. A change with nothing to see on screen (a server-side permission check) gets only a
   card that says so and where it is proven (tests in PR #…).
4. `nix-shell -p ffmpeg dejavu_fonts fontconfig --run "python3 -I <skill>/video/assemble.py plan.json <scratch>/video"`.
   A round over 15 MB: rerun with a higher `--crf` (+3), or split the round.
5. Look at a few frames (`ffmpeg -ss <t> -i <file> -frames:v 1 x.png`, then Read): a card, a
   clip with its caption, a click with the marker.

## 7. Build and publish

```bash
python3 -I <skill dir>/build.py <scratch>/changes.json <scratch>/shots <scratch>/page
```

It writes `page/index.html`, copies the used pictures to `page/img/` (and round videos to
`page/video/`), writes `page/files.json` (the `files` map) and fails on a missing file, a duplicate
id, a wrong `changedBy` or a video over 15 MB. Then:

- Follow the Artifact tool's rules (load `artifact-design` once; the template already carries the
  page contract: title, theme tokens, dark mode, phone layout).
- Publish `page/index.html` with `files` = the map in `files.json`, `icon: "compare"`, a
  one-sentence `description`. One publish takes at most 255 files; split larger sets over
  several publishes to the same URL.
- A redo (new review round, more changes) republishes to the SAME URL, so the owner's link keeps
  working: pass the earlier artifact's `url` (read it first when it came from another
  conversation). Rebuild from the updated JSON; do not patch the HTML by hand. Keep the previous
  round's `changes.json` in the scratchpad: the next round adds to it.
- Optionally check the page at desktop and phone width (menu jumps, highlight, no sideways
  scroll) before sending the link.

## 8. The reply

The link, then in a few lines: how many changes and pictures, how the page is organised, what is
made up or seeded by hand, and what waits for the owner (bugs found, things to compare with the
old system, open questions). With rounds: the path of the full video file. Do not repeat the page
in the reply.

Done means: every user-visible change has an entry with true facts, every picture was looked at,
the page is published, and the owner has the link. With rounds also: each round has its ask, its
video (looked at) and its decisions; every card a later round changed links to the change.
