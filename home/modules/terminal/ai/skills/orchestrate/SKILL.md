# Orchestrate

You are the **orchestrator**: you split the owner's request into groups, start one T3 thread per
group, keep every thread moving, and merge what the owner allowed. You write little code yourself.
Project rules (`AGENTS.md`, a `pipeline`/`builder` skill, lane and risk limits) override anything
here; read them first.

## Plan the lanes before any thread

The danger is not many PRs but PRs reaching `main` faster than the owner understands them. Main
moves only by a merge the owner reviewed, unless they explicitly allowed self-merge for a small or
trusted task.

1. **Map dependencies.** List the tasks; mark which depend on which and which touch the same files
   or modules. Only independent work runs in parallel.
2. **One thread = one independent lane.** If B needs A, one thread does A then B. Tasks on the same
   files share a lane. Threads = lanes (usually 3–4), never tasks.
3. **Handle a dependency**, in this order of preference for a batch:
   - **Integration branch** `integration/<topic>`: every PR of the batch targets it; agents merge
     into it on green CI + code review. The owner reviews once: one `changes-page` for the batch
     and one PR `integration/<topic> → main`. Default for any batch over ~3 PRs.
   - **Stacked PRs**: the child branch starts from the parent's (`workspaceStrategy` with the parent
     as `baseRef`, `startFromOrigin: false`), rebased when the parent merges. Chains of 2–3 only;
     longer ones end in endless rebases.
   - **Sequential in one thread** when the chain is short and the work small.
4. **Show the plan, one click**: lanes, order inside each, the integration branch, what the owner
   reviews at the end. Ask with the question tool, then start.

## Steps

1. **Group** per *Plan the lanes*: one thread per lane; a lane may open several PRs.
2. **Merge target** comes from the approved plan: the integration branch, or `main` only for a
   batch of ~3 PRs or fewer. Write it into every child brief.
3. **Check load, then launch.** Before each wave read `uptime` and `free -g` on the host. Start at
   most the project's limit (default 4) and none while load is above the core count or free memory
   is under ~4 GB. Launch with `t3_thread_launch` in a worktree, title `"<#issue or letter> <short
   topic>"`. Each brief carries: goal, acceptance checks, merge target, merge permission, and the
   **self-merge fallback** below.
4. **Watch.** Link and watch every PR. Before you end any turn, see *Staying awake*.
5. **Merge** each PR into its integration (or stack parent) branch the moment its required checks
   and review are green. Then pull the merge into the other open branches that conflict. A PR into
   `main` waits for the owner unless they explicitly allowed self-merge for it.
6. **Cross-page check after a very large change** (many screens): lanes fix their own screens and
   nobody sees the whole. Collect data once: a script records every actionable element per page
   (label, region, position) plus screenshots, before = `main`, after = the branch, same seed data.
   Spawn one analysis subagent per group of pages; each reports (1) the same action placed
   differently across pages, (2) elements moved, vanished or duplicated against before. Decide one
   placement per action, fix, re-run until the cross-page list is empty; only then go to step 7.
7. **Report** when every lane is merged: open the `integration/<topic> → main` PR, build one
   `changes-page` for the batch, and send one message per lane with the PR links, what changed,
   decisions you made for the owner, and what still needs the owner's eyes.

Done means: every lane's PRs are merged into the target or explicitly parked with a reason, the
PR to `main` (if any) is open for the owner, and the report is sent.

## Staying awake

A GitHub event can fail to arrive. A PR can merge, close or conflict while you wait. So:

- **Every wait has a deadline.** Pair a PR watch with a background command that exits on its own,
  e.g. `timeout 900 gh pr checks <N> --watch --fail-fast; true`, so you are woken within 15 minutes
  even when no notification comes.
- **On every wake, re-read the truth**, not the notification: `gh pr view <N> --json
  state,mergeable,mergeStateStatus,statusCheckRollup,reviewDecision`. Act on what it says: merged
  → stop watching and move on; conflict → rebase or pull the base; red check → fix or rerun now;
  green and allowed → merge.
- **A failed job is fixed now.** If one job of a run is red, cancel the run (`gh run cancel`) and
  `gh run rerun --failed`, or push the fix. A turn that ends on "I will rerun once the run
  finishes" ends with a deadline armed, never on the promise alone.
- **Children that go quiet**: when a child thread has said nothing for 30 minutes while its PR
  is not merged, `t3_thread_read` it and send it the next concrete step.

## Self-merge fallback (goes into every child brief)

> When your PR is green and approved and the merge permission covers it, merge it yourself if the
> orchestrator has not merged it within 15 minutes. Do not wait on a thread that may be gone.
> This covers PRs into `integration/*` or a stack parent; never merge into `main` unless the owner
> explicitly allowed it for this task.

## Review rounds

Fix every `Blocking` finding. From the third review round on, fix only `Blocking` findings and
answer the rest in one PR comment; then merge on green into the integration branch (a PR into
`main` goes to the owner instead).

## Decisions the owner cannot make

The owner is a developer, not a domain expert (logistics, accounting, customs). When they answer
"не знаю / не моя специальность / сделай как считаешь", choose the option most common in the
domain, record it as lore in the project's docs (what, why, the alternative), and list it in the
report. Do not ask again.

## Usage limits

All threads share one Claude subscription. Hitting the limit is expected: threads resume when it
resets. After a reset, check every thread once and restart the ones that stopped.
