# simplify-diff

A diff that grew past what the task needed. The usual cause: the agent obeyed every review
comment, added "while I'm here" fixes, or built for cases nobody asked about. Shrink it back.

Read the repo's `AGENTS.md` / `CLAUDE.md` first; a project rule outranks anything below.

## Steps

1. Restate the task in one sentence. Everything in the diff must serve it.
2. Read the full diff (`git diff <base>...HEAD`). For each hunk ask: would the task fail without
   it? If no, it is a removal candidate.
3. Remove or revert:
   - code for cases that cannot happen or were not asked for (extra options, flags, fallbacks,
     config knobs, generic helpers with one caller);
   - refactors, renames and reformatting of code the task did not need to touch;
   - duplicated logic that an existing helper in the repo already does (search before keeping);
   - defensive checks for states the callers already rule out;
   - comments that restate the code; debug output; dead code you added;
   - changes made only to satisfy a nit (answer the nit "not in this PR" instead).
4. Keep: tests for the new behaviour, fixes for real bugs with a failure scenario, anything a repo
   rule requires.
5. Re-run the checks (build, tests, lint) and confirm behaviour did not change.

Do not hunt for bugs here (that is `self-review`), and do not shorten code into something
harder to read; fewer lines is the result, not the goal.

## Output

```
Removed: <file> — <what> — <why the task did not need it>
Kept:    <file> — <what looked removable> — <why it stays>
Diff:    <files/+/- before> → <after>   (git diff --shortstat)
Checks:  <command> → <result>
```
