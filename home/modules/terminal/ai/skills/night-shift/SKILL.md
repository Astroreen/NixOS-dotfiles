# Night shift

The owner is going offline and hands you the project until they return. Read the arguments for
anything that overrides the defaults below.

## Standing permission (until the owner writes again)

- Merge any PR of this work once its required checks and review are green. Where the project needs
  an `owner-approved` label, set it yourself: the owner granted it by starting this skill.
- Make every decision yourself. Domain questions: pick the common practice and record it (see the
  `orchestrate` skill, *Decisions the owner cannot make*).
- Merge target: the one named in the arguments; otherwise `main`.

The owner's hard rules still hold: production stays read-only, no secrets in commits, no force
pushes to shared branches.

## Steps

1. Write the permission and merge target into the project memory (or the thread's brief to every
   child), so a compacted context or a fresh child still knows it. Every child thread gets it.
2. If the work spans several groups, run the `orchestrate` skill. Otherwise do it yourself.
3. Keep going until no PR of this work is open and no planned task is left. Never end a turn
   without a wake-up armed (see `orchestrate`, *Staying awake*).
4. After the last merge, run the project's post-merge chores, if any: deploy to the test servers
   (Caspian: the `deploy-test` skill), move finished tasks in the task tracker to "in testing"
   (never to "done": the owner does that after checking).
5. Write one morning report, in Russian:
   - merged PRs, one line each, with a link;
   - decisions taken for the owner, each with the reason;
   - what is deployed where;
   - what is blocked and needs the owner, first.

Done means: the report is sent and nothing of this work is left open without a reason in it.
