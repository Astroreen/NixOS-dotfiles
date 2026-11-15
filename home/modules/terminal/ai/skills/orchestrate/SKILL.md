# Orchestrate

You are the **orchestrator**: you split the owner's request into lanes, start one T3 thread per
lane and keep every thread moving. You write little code yourself. Project rules (`AGENTS.md`,
lane and risk limits) override anything here; read them first.

Work that fits one session goes to one thread: splitting and re-checking it costs more than it
saves. Run this on `high` effort yourself: a lead on low/medium stops early with a list of what is
left, and nobody is watching.

## Only the owner merges

The danger is not many PRs but PRs reaching `main` faster than the owner understands them.

- Every PR targets `main` (a stacked one: its parent's branch) and waits for the owner's review
  and merge.
- Nobody else merges (not you, not a child) unless the owner says so in this conversation, for
  the PRs they name. Copy their words into the brief of each thread they cover.
- A step that can be undone (a commit, a push to the lane's branch, a rerun) goes ahead without
  asking; one that cannot (merge, delete, deploy, a message to people) waits for the owner.
- **At most 5 open PRs per orchestration**, at most 2 of them high-risk (money, permissions,
  login, data migrations, deletes: a mistake there costs data or money, not just a redraw). The
  owner or the project may set another number. The next PR opens when one is merged or closed.

## Plan the lanes before any thread

1. **Map dependencies.** List the tasks; mark which depend on which and which touch the same files
   or modules. Only independent work runs in parallel.
2. **One thread = one independent lane.** If B needs A, one thread does A then B. Tasks on the same
   files share a lane. Threads = lanes (usually 3–4), never tasks.
3. **Handle a dependency**, in this order of preference:
   - **Sequential in one thread**: B's PR opens after the owner merged A's.
   - **Stacked PRs**: the child branch starts from the parent's (`workspaceStrategy` with the parent
     as `baseRef`, `startFromOrigin: false`) and its PR targets the parent's branch until the owner
     merges the parent, then `main`. Chains of 2–3 only.
   - **Integration branch** `integration/<topic>`: only when the owner asks for one, or when the
     changes cannot work apart. Ask the owner who merges into it.
4. **Show the plan, one click**: lanes, order inside each, the model and effort of each, which PRs
   are high-risk, in what order the owner will get them. Ask with the question tool, then start.

## Pick the model per lane

A thread inherits your model unless you pass `modelSelection` (`t3_thread_launch`, `delegate_task`
`target`). Choose per lane, from the cheapest that can do it, and say why in the plan:

| Lane | Model, effort |
|---|---|
| Lookup, file search, logs, renames, version bumps, mechanical edits by a clear recipe | `claude-haiku-5-5`, low |
| Small, clear task with known files and checks (one screen, one endpoint, a config value) | `claude-sonnet-5-5`, medium |
| Default: features, bug hunts, anything needing judgment | `claude-opus-5-5`, medium |
| High-risk (money, permissions, login, migrations, deletes), architecture, cross-module change | `claude-opus-5-5`, high |
| Review of a high-risk PR, or a job Opus on high already failed: the hardest problem, a large rewrite, 3D | `claude-fable-5-1`, high |

- **Never above `high`** (`xhigh`, `max`, `ultrathink`, `ultracode`) unless the owner asks: little
  gain for many tokens. Step up a model, not an effort level.
- **Pick at launch, do not switch mid-thread**: the new model re-reads the whole thread at full
  price and loses the old one's reasoning. Need another model? Start a new thread with a summary.
- Check names with `orchestrator_capabilities` before use; only `claudeAgent` models share the
  subscription. Other providers (OpenRouter via `opencode`) bill per token: only when the owner asks.

## Steps

1. **Check load, then launch.** Before each wave read `uptime` and `free -g` on the host. Start at
   most the project's limit (default 4) and none while load is above the core count or free memory
   is under ~4 GB. Launch with `t3_thread_launch` in a worktree, title `"<#issue or letter> <short
   topic>"`. Each brief carries: goal, acceptance checks (each one pass/fail: a test, a command,
   a screenshot; "make it good" is not a check; set the bar high), model and effort (see *Pick
   the model per lane*), base (`main` or the stack parent), "open the PR, link and watch it, do
   not merge" (or the owner's exact merge words), and review rounds per `review-loop`.
2. **Watch.** Link and watch every PR. Before you end any turn, see *Staying awake*.
3. **After the owner merges a PR**, pull `main` into the open branches that now conflict and open
   the next queued PR.
4. **Cross-page check after a very large change** (many screens): lanes fix their own screens and
   nobody sees the whole. Collect data once: a script records every actionable element per page
   (label, region, position) plus screenshots, before = `main`, after = a local merge of all the
   lane branches (never pushed), same seed data. Spawn one analysis subagent per group of pages; each reports (1) the same action placed
   differently across pages, (2) elements moved, vanished or duplicated against before. Decide one
   placement per action, fix, re-run until the cross-page list is empty; only then report.
5. **Report** for someone who watched none of it: most important first, plain words, real
   results (screenshots, test output), small changes too. One `changes-page` for the batch, and
   one message per lane with the PR links, what changed, decisions you made for the owner, what
   still needs the owner's eyes, and the order to review the PRs in.

Done means: every PR is open for the owner (or merged by them) or parked with a reason, and the
report is sent.

## Staying awake

A GitHub event can fail to arrive. A PR can merge, close or conflict while you wait. So:

- **Every wait has a deadline.** Pair a PR watch with a background command that exits on its own,
  e.g. `timeout 900 gh pr checks <N> --watch --fail-fast; true`, so you are woken within 15 minutes
  even when no notification comes.
- **On every wake, re-read the truth**, not the notification: `gh pr view <N> --json
  state,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision`. Act on what it says: merged
  → stop watching and move on; conflict → rebase or pull `main`; red check → fix or rerun now;
  green → tell the owner it is ready.
- **A failed job is fixed now.** If one job of a run is red, cancel the run (`gh run cancel`) and
  `gh run rerun --failed`, or push the fix. A turn that ends on "I will rerun once the run
  finishes" ends with a deadline armed, never on the promise alone.
- **Children that go quiet**: when a child thread has said nothing for 30 minutes while its PR
  is not green, `t3_thread_read` it and send it the next concrete step.

## Review rounds

Follow the `review-loop` skill; put that into every brief. The review runs in a fresh context that
did not write the code (a new `delegate_task`, not the builder thread), on a model at least as
strong as the builder's: a high-risk PR on `claude-fable-5-1`, high.

## Decisions the owner cannot make

The owner is a developer, not a domain expert (logistics, accounting, customs). When they answer
"не знаю / не моя специальность / сделай как считаешь", choose the option most common in the
domain, record it as lore in the project's docs (what, why, the alternative), and list it in the
report. Do not ask again.

## Usage limits

All threads share one Claude subscription. Hitting the limit is expected: threads resume when it
resets. After a reset, check every thread once and restart the ones that stopped.
