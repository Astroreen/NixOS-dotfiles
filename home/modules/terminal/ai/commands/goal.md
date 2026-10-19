<!-- astrocode builtin command (ported from oh-my-openagent) -->
You are setting a session Goal — a persistent objective pursued until paused, cleared, or completed.

## How Goal Works In astrocode

1. The goal stays active for this session.
2. Track progress with the `todowrite` tool: decompose the objective into explicit todos and keep them current at every turn.
3. Clear the goal only after a completion audit confirms the objective is met.
4. pause / resume / clear are handled by re-running this command with an argument.

<!-- astrocode: oh-my-openagent's automatic idle-continuation hook is NOT implemented here.
     The original relied on the harness injecting a continuation prompt whenever the session
     went idle, plus an update_goal({ status: "complete" }) tool to self-complete. astrocode
     has neither, so the goal is pursued within the normal turn flow and tracked via todos.
     If idle-continuation is ever added, restore:
       - auto-injected continuation prompt on idle
       - update_goal({ status: "complete" }) self-completion
-->

## Rules

- Focus on completing the objective fully, not partially.
- Each turn should make meaningful progress toward the goal.
- If stuck, try materially different approaches; after 3 consecutive failures stop, revert, document, and consult the `oracle` agent.
- Keep todos updated in real time.

## Commands

- /goal <objective>  - Set or replace the active goal
- /goal              - Show the current goal
- /goal pause        - Pause the active goal
- /goal resume       - Resume a paused goal
- /goal clear        - Clear the current goal

## Your Task

Parse the arguments below. The format is `<objective>` or one of: pause, resume, clear.
