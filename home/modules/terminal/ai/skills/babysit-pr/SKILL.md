# Babysit PR

Many repos have automated review bots (such as Claude Code Review, CodeRabbit,
Copilot, or repo-specific review workflows). They are helpful, even when they
are not always right.

## Waiting in T3 Code

Never write your own watcher, polling loop, `sleep` loop, or `gh --watch`.
Use T3 Code's `watch_pull_request` tool — one watcher per PR.

Handle the existing checks and comments first (read them with
`pull_request_read` using `include: ["checks", "threads", "comments"]`). Then
call `watch_pull_request` and end your turn. T3 Code wakes you when a check
fails, required checks pass, someone comments or reviews, or the branch
conflicts.

- **Only the thread that owns the PR watches it.** If you are a delegated
  child task (a reviewer, a review round, any `delegate_task` child), never
  call `watch_pull_request`. The parent owns the PR. Do not watch PRs you are
  not working on.
- **Set `until` to match your goal:** `"checks"` when handing the ready PR to
  the user; `"merged"` only when you were explicitly authorized to merge it.
- **A wake is news, not a merge decision.** Re-read live PR state with
  `pull_request_read` and verify the merge gate yourself.
- **Unwatch when you hand off.** A watched thread stays in Working and out of
  the user's inbox. When you stop (ready, blocked, or asking the user a
  question), call `unwatch_pull_request` first. A merge or close ends the watch
  on its own.
- **When a wake needs no action**, end your turn without a message. Never post
  or say "still waiting".
- **"Stopped watching, could not read it"** usually means GitHub's rate limit
  is used up. Run `gh api rate_limit --jq .resources.graphql` before watching
  again. If `remaining` is near 0, wait for `reset` instead of retrying in a
  tight loop.

## Checks and CI

Use T3 Code's MCP tools for PR and CI operations:

- `pull_request_read` (`include: ["checks", "threads", "comments"]`) to inspect
  checks, review state, mergeability, and unresolved threads.
- `ci_logs` to read failing check output.
- `ci_rerun` to re-run flaky or infrastructure-failed checks.
- `pull_request_respond` to reply to and resolve review threads.
- `pull_request_merge` (with `expectedHeadSha`) when merge is authorized.

## Reviews and bot exit route

Only act on checks and comments newer than the latest push. Verify every bot or
reviewer finding against the source before changing code. Fix real findings and
CI failures, distinguish repository failures from infrastructure flakes, and
reply with a written reason when dismissing false positives.

If a review bot cites repo review rules or guidelines (such as `AGENTS.md`,
`CLAUDE.md`, or a repo review config), read them before replying.

Handle automated review bots in a repo-agnostic way:

- **Detect what this repo actually runs.** Inspect the PR's check runs,
  workflows, reviews, and repo docs to see which review bots (e.g. Claude Code
  Review or any other bot) are active on this repo.
- **Wait only for active, non-advisory review bots.** If a review bot check or
  workflow is running on the current head, wait for it to finish unless the
  repo marks it advisory/non-blocking.
- **Exit route when no bot is configured (or after bots finish).** Never wait
  indefinitely for a specific review bot that this repo does not run. Once
  required checks are green, no review-bot check is still pending on the latest
  head, and no unresolved review threads remain, stop waiting — the review gate
  is satisfied.

If a review bot leaves feedback you believe is not worth addressing, reply with
a written reason and resolve the thread with `pull_request_respond`. Use the
`leaving-pr-comments` skill for every comment posted on the user's behalf.

Screenshots and videos help as well, when you have a way to upload them.

Keep the PR at the size the user's goal needs. Review loops tend to grow a PR
one cheap-looking fix at a time. Fix real bugs in the intended case. Decline
the rest with a written reason, and list them as follow-ups: unneeded tests,
guards for edge cases that do not matter, extra integration or compatibility,
and small performance costs. Prefer the fix that deletes or narrows code.

## Base branch and merging

Keep an eye on changes to the base branch (`main` or the PR's target) and
rebase when needed. `watch_pull_request` reports conflicts only, so run
`git fetch` and check with `pull_request_read` whether the PR is `BEHIND` or
`DIRTY` before calling it ready.

If an overlapping PR makes this one obsolete, stop monitoring (call
`unwatch_pull_request`), report it to the user, and ask before closing the PR
unless closure was explicitly authorized.

If nothing has changed, stay quiet rather than posting filler comments. Stop
when the merge gate passes on the latest head. Merge only when the user
explicitly requested it; otherwise call `unwatch_pull_request` and report that
the PR is ready. Right before merging with `pull_request_merge`, run
`git fetch` and check `pull_request_read` again. Never merge when the PR is
`BEHIND` or `DIRTY`, or when base commits that landed after the last green run
touch this PR's files — rebase, push, and wait for green again.
