# review-loop

Rules for any back-and-forth of review and fix: your own `self-review`, a CI review bot, another
agent, or a person. An agent author and an agent reviewer can keep each other busy forever and
grow a small fix into a huge diff. These rules make the loop end.

The repo's `AGENTS.md` / `CLAUDE.md` may set its own cap or labels; it wins.

## Rules

1. **Cap the rounds at 3.** A round is: findings in, fixes out. Count them.
2. **After round 3, step back.** Do not fix the next finding. Ask: are the findings clustering in
   one area? Is the approach wrong (wrong layer, wrong data model, fighting the framework)? Write
   that down and, if the approach should change, say so to the owner instead of patching again.
3. **Name the class, fix every instance.** A finding is a kind of bug ("user ID taken from the
   request without a scope check"), not one line. Search the whole diff for that class and fix
   all of them in the same round, listing each place.
4. **Never repeat a finding.** As reviewer, do not raise again what was already answered. As
   author, answer a repeat with a pointer to the earlier answer.
5. **Later rounds review only the new diff**, except to check that a fix did not break what it
   touched.
6. **A nit that grows the diff may be answered "not in this PR".** Obeying every comment is the
   failure mode. Fix nits only when they are one-line and inside lines you already changed.
7. **Every finding gets an answer**: fixed (with commit), rejected (one-line reason), or
   pre-existing (not caused by this change). Silence is not an answer.

## Output per round

```
Round N/3
Class: <bug class> — instances: <file:line>, <file:line> — fixed in <commit>
Rejected: <finding> — <reason>
Not in this PR: <nit> — <why it would grow the diff>
```
