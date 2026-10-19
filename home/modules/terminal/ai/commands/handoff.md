<!-- astrocode builtin command (ported from oh-my-openagent) -->
# Handoff Command

## Purpose

Use /handoff when:
- The current session context is getting too long and quality is degrading
- You want to start fresh while preserving essential context from this session
- The context window is approaching capacity

This creates a detailed context summary that can be used to continue work in a new session.

---

# PHASE 0: VALIDATE REQUEST

Before proceeding, confirm:
- [ ] There is meaningful work or context in this session to preserve
- [ ] The user wants a handoff summary (not just asking about it)

If the session is nearly empty or has no meaningful context, say so and stop.

---

# PHASE 0.5: SOURCE OF TRUTH (MANDATORY FIRST STEP)

The conversation history is the only authoritative record of what the user originally asked.
Do NOT reconstruct the first request from memory — long sessions truncate or summarize early
messages, so memory is unreliable.

Rules:
- Quote the user's requests verbatim from the conversation; do not paraphrase or "tidy up".
- Do not skip this step even if you feel you remember the first request.
- If the original request is not visible in the remaining context, state that explicitly in the
  USER REQUESTS (AS-IS) section rather than guessing.

---

# PHASE 1: GATHER PROGRAMMATIC CONTEXT

Use real tools to gather concrete data:

1. `todoread()` - current task progress
2. `bash` with `git diff --stat HEAD~10..HEAD` - recent file changes
3. `bash` with `git status --porcelain` - uncommitted changes

Analyze the outputs to understand:
- What work was completed
- What tasks remain (include todo state)
- What decisions were made
- What files were modified (include git diff/stat + status)
- What patterns, constraints, or preferences were established

---

# PHASE 2: EXTRACT CONTEXT

Write the summary from first person ("I did...", "I told you...").

Focus on:
- Capabilities and behavior, not file-by-file implementation details
- What matters for continuing the work
- Avoiding excessive implementation detail (variable names, storage keys, constants) unless critical
- USER REQUESTS (AS-IS) must be verbatim (do not paraphrase, do not invent)
- EXPLICIT CONSTRAINTS must be verbatim only

---

# PHASE 3: FORMAT OUTPUT

Generate a handoff summary using this exact format:

```
HANDOFF CONTEXT
===============

USER REQUESTS (AS-IS)
---------------------
- [Exact verbatim user requests - NOT paraphrased]

GOAL
----
[One sentence describing what should be done next]

WORK COMPLETED
--------------
- [First person bullets of what was done]
- [Include specific file paths when relevant]
- [Note key implementation decisions]

CURRENT STATE
-------------
- [Current state of the codebase or task]
- [Build/test status if applicable]
- [Any environment or configuration state]

PENDING TASKS
-------------
- [Tasks planned but not completed]
- [Next logical steps]
- [Blockers or issues encountered]
- [Current todo state from todoread()]

KEY FILES
---------
- [path/to/file] - [brief role description]
(Maximum 10 files, prioritized by importance)

IMPORTANT DECISIONS
-------------------
- [Technical decisions and why]
- [Trade-offs considered]
- [Patterns or conventions established]

EXPLICIT CONSTRAINTS
--------------------
- [Verbatim constraints only - from user or AGENTS.md]
- If none, write: None

CONTEXT FOR CONTINUATION
------------------------
- [What the next session needs to know]
- [Warnings or gotchas]
- [References to documentation if relevant]
```

Rules for the summary:
- Plain text with bullets
- No markdown `#` headers (use the dash format above)
- No bold, italic, or code fences within content
- Use workspace-relative paths
- USER REQUESTS (AS-IS) and EXPLICIT CONSTRAINTS must be verbatim only

---

# PHASE 4: PROVIDE INSTRUCTIONS

After generating the summary, instruct the user:

```
---

TO CONTINUE IN A NEW SESSION:

1. Start a new session in opencode
2. Paste the HANDOFF CONTEXT above as your first message
3. Add your request: "Continue from the handoff context above. [Your next task]"
```

---

# IMPORTANT CONSTRAINTS

- DO NOT attempt to programmatically create sessions (no such tool for agents)
- DO provide a self-contained summary that works without this session
- DO include workspace-relative file paths
- DO NOT include secrets (API keys, credentials)
- DO NOT exceed 10 files in KEY FILES
- DO keep GOAL to a single sentence or short paragraph

# EXECUTE NOW

Begin by gathering programmatic context, then synthesize the handoff summary.
