# self-review

Review your own change before anyone else sees it. The goal is real bugs caught locally, not a
longer diff.

## 0. Read the rules first

Read the repo's `AGENTS.md` / `CLAUDE.md` (root and any nested one next to the changed files).
Project rules live there; this skill does not repeat them.

## 1. Prove it runs

Run what the repo gives you for the changed code: build, type check, lint, the tests that cover
it, a screenshot or recording when the change is visible. Keep the command and its output.
"Done" without output does not count.

## 2. Review in a fresh context

The author's context is biased toward the code it just wrote. Get a second reader:

- **Sub-agent or separate thread** if the host has one. Give it only: the diff
  (`git diff <base>...HEAD`, plus uncommitted changes), the task in one or two sentences, and the
  paths of the rules files. Not your reasoning, not your plan, not "I think it is fine".
- **No sub-agent:** do a deliberate second pass yourself. Forget the plan, read only the diff and
  the rules, file by file, as if someone else wrote it.

What the reviewer hunts for (in this order):

1. Correctness: wrong condition, off-by-one, null/empty input, wrong order of operations, a caller
   that still expects the old behaviour, a state that is never reset.
2. Missing pieces the task implied: a second place that needed the same change, a migration, a
   translation, a test for the new behaviour.
3. Failures: errors swallowed, partial writes, retries that double an effect.

Each finding must name a **concrete failure scenario**: input or state → what goes wrong. No
scenario, no finding.

## 3. Validate every finding against the code

Open the code and check each finding before acting on it. Drop it when the scenario cannot
happen (guarded elsewhere, impossible input, already tested). Drop style-only findings (naming,
formatting, "could be cleaner") unless a repo rule demands them. Mark a bug that existed before
your change as *pre-existing*: report it, do not fix it in this change unless it is tiny and on a
line you touched.

## 4. Fix or reject, explicitly

For every surviving finding: fix it, or write one line why not. Then re-run step 1. If fixes keep
coming, follow `review-loop` (round cap, bug classes). If the diff grew a lot, run
`simplify-diff`. If the change touches access, login, files, agent tools, public pages, or
anything that leaves the system, run `security-check`.

## Output

```
Checks:   <command> → <result line from its output>   (one per check)
Findings: <file:line> — <scenario> — fixed | rejected: <reason> | pre-existing
Skipped:  <check not run> — <why>
```

Put the same evidence in the PR's proof section.
