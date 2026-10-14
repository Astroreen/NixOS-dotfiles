---
description: "Intelligent refactoring with LSP, AST-grep, codemap, and TDD verification"
---

<!-- astrocode builtin command (ported from oh-my-openagent) -->
# Intelligent Refactor Command

## Usage

```
/refactor <refactoring-target> [--scope=<file|module|project>] [--strategy=<safe|aggressive>]

Arguments:
  refactoring-target: What to refactor. Can be:
    - File path: src/auth/handler.ts
    - Symbol name: "AuthService class"
    - Pattern: "all functions using deprecated API"
    - Description: "extract validation logic into separate module"

Options:
  --scope: Refactoring scope (default: module)
    - file: Single file only
    - module: Module/directory scope
    - project: Entire codebase

  --strategy: Risk tolerance (default: safe)
    - safe: Conservative, maximum test coverage required
    - aggressive: Allow broader changes with adequate coverage
```

## What This Command Does

Performs intelligent, deterministic refactoring with full codebase awareness:
1. Understands your intent
2. Maps the codebase before touching anything
3. Assesses risk and determines a verification strategy
4. Plans meticulously (Prometheus)
5. Executes precisely with LSP and AST-grep
6. Verifies constantly

---

# PHASE 0: INTENT GATE (MANDATORY FIRST STEP)

**BEFORE ANY ACTION, classify and validate the request.**

## Step 0.1: Parse Request Type

| Signal | Classification | Action |
|--------|----------------|--------|
| Specific file/symbol | Explicit | Proceed to codebase analysis |
| "Refactor X to Y" | Clear transformation | Proceed to codebase analysis |
| "Improve", "Clean up" | Open-ended | **MUST ask**: "What specific improvement?" |
| Ambiguous scope | Uncertain | **MUST ask**: "Which modules/files?" |
| Missing context | Incomplete | **MUST ask**: "What's the desired outcome?" |

## Step 0.2: Validate Understanding

- [ ] Target is clearly identified
- [ ] Desired outcome is understood
- [ ] Scope is defined (file/module/project)
- [ ] Success criteria can be articulated

If ANY of the above is unclear, ASK using the clarification protocol below:

```
I want to make sure I understand the refactoring goal correctly.

**What I understood**: [interpretation]
**What I'm unsure about**: [specific ambiguity]

Options I see:
1. [Option A] - [implications]
2. [Option B] - [implications]

**My recommendation**: [suggestion with reasoning]

Should I proceed with [recommendation], or would you prefer differently?
```

## Step 0.3: Create Initial Todos

IMMEDIATELY after understanding the request, register phase todos with `todowrite`:
PHASE 1 codebase analysis, PHASE 2 codemap, PHASE 3 test assessment, PHASE 4 plan,
PHASE 5 execution, PHASE 6 final verification.

---

# PHASE 1: CODEBASE ANALYSIS

Mark phase-1 in_progress. Fire parallel investigation via `task(...)` (synchronous; issue the
independent calls together in one message):

```
task(subagent_type="explore", description="Find refactor target", prompt="Find all occurrences
and definitions of [TARGET]. Report file paths, line numbers, usage patterns.")

task(subagent_type="explore", description="Find dependencies", prompt="Find all code that
imports, uses, or depends on [TARGET]. Report dependency chains and import graphs.")

task(subagent_type="explore", description="Find conventions", prompt="Find similar code patterns
to [TARGET]. Report analogous implementations and established conventions.")

task(subagent_type="explore", description="Find tests", prompt="Find all test files related to
[TARGET]. Report test file paths, case names, coverage indicators.")

task(subagent_type="explore", description="Find architecture", prompt="Find architectural
patterns and module organization around [TARGET]. Report module boundaries and design patterns.")
```

Use direct tools for precision:
- `lsp` - where is it defined
- `lsp` - all usages across the workspace
- `lsp` - file/workspace outline and symbol search
- `lsp` - current errors/warnings before you start
- `grep` / `glob` - text and file discovery
- the `ast-grep` skill (load it via the `skill` tool) for structural patterns

Mark phase-1 completed after results are collected.

---

# PHASE 2: BUILD CODEMAP

Mark phase-2 in_progress. Construct, based on Phase 1:

```
## CODEMAP: [TARGET]

### Core Files (Direct Impact)
- path/to/file.ts:L10-L50 - Primary definition
- path/to/file2.ts:L25 - Key usage

### Dependency Graph
[TARGET]
- imports from: module-a (types), module-b (utils)
- imported by: consumer-1.ts, consumer-2.ts, consumer-3.ts
- used by: handler.ts (direct call), service.ts (dependency injection)

### Impact Zones
| Zone | Risk Level | Files Affected | Test Coverage |
|------|------------|----------------|---------------|
| Core | HIGH | 3 files | 85% |
| Consumers | MEDIUM | 8 files | 70% |
| Edge | LOW | 2 files | 50% |

### Established Patterns
- Pattern A: [description] - used in N places
- Pattern B: [description] - established convention
```

Identify constraints: MUST follow existing patterns, MUST NOT break critical dependencies,
safe-to-change zones, changes requiring migration. Mark phase-2 completed.

---

# PHASE 3: TEST ASSESSMENT

Mark phase-3 in_progress.

Detect test infrastructure (`bash`): inspect package.json scripts, pytest/pyproject, go tests.
Analyze coverage for the target via `task(subagent_type="explore", prompt="Analyze test coverage
for [TARGET]: which test files cover it, what cases exist, integration tests, edge cases,
estimated coverage %") - use it synchronously.

| Coverage | Strategy |
|----------|----------|
| HIGH (>80%) | Run existing tests after each step |
| MEDIUM (50-80%) | Run tests + add safety assertions |
| LOW (<50%) | **PAUSE**: propose adding tests first |
| NONE | **BLOCK**: refuse aggressive refactoring |

If coverage is LOW/NONE, ask the user which approach they prefer (add tests first / proceed with
caution / abort).

Document a verification plan: test command, type check, lsp checkpoints after each
step, and explicit regression indicators. Mark phase-3 completed.

---

# PHASE 4: PLAN GENERATION

Mark phase-4 in_progress. Delegate to astrocode's planner:

```
task(subagent_type="prometheus", description="Refactor plan", prompt="Create a detailed
refactoring plan.

## Refactoring Goal
[User's original request]

## Codemap (from Phase 2)
[Insert codemap]

## Test Coverage (from Phase 3)
[Insert verification plan]

## Constraints
- MUST follow existing patterns: [list]
- MUST NOT break: [critical paths]
- MUST run tests after each step

## Requirements
1. Break down into atomic refactoring steps
2. Each step independently verifiable
3. Order steps by dependency
4. Specify exact files and line ranges per step
5. Include a rollback strategy per step
6. Define commit checkpoints")
```

Review and validate the plan (completeness, safety, order, verification), then register each step
as granular todos. Mark phase-4 completed.

---

# PHASE 5: EXECUTE REFACTORING

Mark phase-5 in_progress.

For EACH step:
- Pre-step: mark todo in_progress, read the current file state, confirm lsp baseline.
- Execute:
  - Symbol renames: use `lsp` to enumerate every usage, then apply precise
    `edit` changes (there is no LSP rename tool available).
  - Pattern transformations: preview with the `ast-grep` skill before applying.
  - Structural changes: use `edit` with exact surrounding context.
- Post-step (MANDATORY): `lsp` on changed files (clean or same as baseline), run the
  test command, run the type check.
- Completion: verification passes -> mark todo completed; fails -> STOP AND FIX.

Failure recovery: STOP, REVERT the failed change, DIAGNOSE, then either fix and retry, skip if
optional, consult `oracle`, or ask the user. NEVER proceed with broken tests.

Commit checkpoints after each logical group of changes.

---

# PHASE 6: FINAL VERIFICATION

Mark phase-6 in_progress.

- Full test suite
- Full type check
- Lint
- Build (if applicable)
- `lsp` on every changed file

Generate a summary: what changed, files modified, verification results (tests/type/lint/build),
and a no-regressions statement. Mark phase-6 completed.

---

# CRITICAL RULES

## NEVER DO
- Skip lsp after changes
- Proceed with failing tests
- Make changes without understanding impact
- Use `as any`, `@ts-ignore`, `@ts-expect-error`
- Delete tests to make them pass
- Commit broken code
- Refactor without understanding existing patterns

## ALWAYS DO
- Understand before changing
- Preview structural rewrites before applying
- Verify after every change
- Follow existing codebase patterns
- Keep todos updated in real time
- Commit at logical checkpoints
- Report issues immediately

## ABORT CONDITIONS
Stop and consult the user if: test coverage is zero for the target, changes would break a public
API, scope is unclear, 3 consecutive verification failures occur, or user constraints are violated.

---

# Tool Usage Philosophy

## LSP Tools
- `lsp` to grasp context
- `lsp` for impact analysis before modifying
- `lsp` for outlines and symbol search
- `lsp` continuously after changes

## AST-Grep
Use the `ast-grep` skill helper (or the `sg` CLI) for structural transformations.
Always preview first, review, then execute.

## Agents
- `explore`: codebase pattern discovery
- `prometheus`: detailed refactoring plan generation
- `oracle`: read-only consultation for complex architectural decisions and debugging
- `librarian`: use proactively for deprecated methods or library migration; query official docs
  and OSS examples for modern replacements

## Deprecated Code & Library Migration
1. Fire `librarian` to find the recommended modern alternative
2. DO NOT auto-upgrade to the latest version unless the user explicitly requests migration
3. If migration is requested, fetch latest API docs via `librarian` before changing code

---

**Remember: Refactoring without tests is reckless. Refactoring without understanding is destructive.**

<user-request>
$ARGUMENTS
</user-request>
