<!-- astrocode builtin command (ported from oh-my-openagent) -->
You are starting an Atlas work session.

## ARGUMENTS

- `/start-work [plan-name]`
  - `plan-name` (optional): name or partial match of the plan to start

## WHAT TO DO

1. **Find available plans**: search for Prometheus-generated plan files under `.sisyphus/plans/`.

2. **Decision logic**:
   - If the user named a plan: match it (exact or partial).
   - If exactly one plan exists: auto-select it.
   - If multiple plans exist: list them with timestamps and ask the user to select.
   - If none exist: tell the user to run `/prometheus` (planning) first.

3. **Read the FULL plan file** before delegating any tasks.

4. **Set the goal + register todos (MANDATORY)**, immediately after reading the plan,
   BEFORE starting any work. Skipping either is a defect.
   - Set the session goal: plan name and path, concrete end state, phase/task counts, and how
     completion is verified.
   - Decompose every plan task into granular, implementation-level todos and register ALL of
     them with `todowrite`, grouped phase by phase. Keep them current: mark in_progress when
     work dispatches and completed immediately after its verification passes — never
     batch-complete, never run unregistered work.

   How to break down:
   - Each plan checkbox item must split into concrete sub-tasks.
   - Each sub-task must name: file to modify, what to change, expected behavior, how to verify.
   - "implement feature X" is NOT acceptable; "add validateToken() to src/auth/middleware.ts that
     checks JWT expiry and returns 401" IS.

<!-- astrocode: oh-my-openagent's session/boulder/worktree/PR machinery is NOT implemented.
     The original additionally required:
       - reading and updating .omo/boulder.json (active_plan, session_ids, worktree_path)
       - --worktree <path> setup via git worktree add
       - --make-pr / --ship delivery modes (push branch, open PR, merge gates)
       - .omo/ ledger + goal tooling (create_goal)
     astrocode tracks the active plan via todos and the normal git flow instead. If worktree
     or PR delivery modes are ever added, restore those sections here.
-->

## CRITICAL

- Read the FULL plan file before delegating any tasks.
- Follow atlas orchestration: delegate work with `task(...)`, verify every delegated result,
  never implement code yourself when a specialist fits.
- If a task needs a skill, name it in the delegation prompt's CONTEXT so the subagent loads it
  with its own `skill` tool call.

## EXECUTE NOW

Locate the plan, register the goal + todos, then begin executing task by task.
