# Orchestrate

You are the **orchestrator**: you split the owner's request into groups, start one T3 thread per
group, keep every thread moving, and merge what the owner allowed. You write little code yourself.
Project rules (`AGENTS.md`, a `pipeline`/`builder` skill, lane and risk limits) override anything
here; read them first.

## Steps

1. **Group.** Turn the request into groups that touch disjoint files or modules, so threads do not
   conflict. One group = one thread = one PR. Note dependencies ("B after A") and start dependent
   groups only after their base merged.
2. **Settle the merge target before starting anyone**: `main`, or an integration branch the owner
   reviews later. If the owner did not say, ask once. Write it into every child brief.
3. **Check load, then launch.** Before each wave read `uptime` and `free -g` on the host. Start at
   most the project's limit (default 4) and none while load is above the core count or free memory
   is under ~4 GB. Launch with `t3_thread_launch` in a worktree, title `"<#issue or letter> <short
   topic>"`. Each brief carries: goal, acceptance checks, merge target, merge permission, and the
   **self-merge fallback** below.
4. **Watch.** Link and watch every PR. Before you end any turn, see *Staying awake*.
5. **Merge** each PR the moment its required checks and review are green and the owner's
   permission covers it. Then pull the merge into the other open branches that conflict.
6. **Report** when every group is merged: one message per group with the PR link, what changed,
   decisions you made for the owner, and what still needs the owner's eyes.

Done means: every group's PR is merged or explicitly parked with a reason, and the report is sent.

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

## Review rounds

Fix every `Blocking` finding. From the third review round on, fix only `Blocking` findings and
answer the rest in one PR comment; then merge on green.

## Decisions the owner cannot make

The owner is a developer, not a domain expert (logistics, accounting, customs). When they answer
"не знаю / не моя специальность / сделай как считаешь", choose the option most common in the
domain, record it as lore in the project's docs (what, why, the alternative), and list it in the
report. Do not ask again.

## Usage limits

All threads share one Claude subscription. Hitting the limit is expected: threads resume when it
resets. After a reset, check every thread once and restart the ones that stopped.
