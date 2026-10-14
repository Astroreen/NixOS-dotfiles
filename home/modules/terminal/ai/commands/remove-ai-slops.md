---
description: "Remove AI-generated code smells from branch changes and review the results"
---

<!-- astrocode builtin command (ported from oh-my-openagent) -->
# Remove AI Slops Command

## What this command does
Analyzes all files changed in the current branch (compared to the parent), removes AI-generated
code smells, then critically reviews the changes to ensure safety and behavior preservation.
Fixes any issues found during review.

## Step 0: Task Planning

Use `todowrite` to create the task list:
1. Get changed files from the branch
2. Remove AI slops on each file
3. Critically review all changes
4. Fix any issues found

## Role Definition
You are a senior code quality engineer specialized in identifying and removing AI-generated code
patterns while preserving original functionality. Deep expertise in code review, refactoring
safety, and behavioral preservation.

## Process

### Phase 1: Identify Changed Files
Detect the repository base branch dynamically, then list changed files:

```bash
BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff $(git merge-base "$BASE_BRANCH" HEAD)..HEAD --name-only
```

If the symbolic-ref lookup is unavailable, detect the base branch from the repo's configured
remote default; only fall back to `main` as a last resort.

### Phase 2: AI Slop Removal
If a `remove-ai-slops` skill is installed, load it once via the `skill` tool and apply its
detection criteria. Otherwise apply the criteria defined by this command directly.

For each changed file, delegate the removal with the real task tool, naming the skill in the
prompt's CONTEXT so the subagent loads it itself:

```
task(subagent_type="hephaestus", description="Remove AI slops from {filename}", prompt="CONTEXT:
load the remove-ai-slops skill via the skill tool before starting. GOAL: remove AI-generated
slops from this file while preserving behavior. FILE: {file_path}")
```

Issue the per-file calls together in one message to run them concurrently.

Before each pass, save a file-specific rollback artifact capturing only the delta of the
slop-removal pass (e.g. generate a per-file patch and reverse-apply on failure). Do NOT use
`git checkout -- {file_path}` — that would discard pre-existing branch changes.

### Phase 3: Critical Review
After the removal passes, review with this checklist:

**Safety Verification**
- [ ] No functional logic accidentally removed
- [ ] All error handling preserved
- [ ] Type hints remain correct and complete
- [ ] Import statements still valid
- [ ] No breaking changes to public APIs

**Behavior Preservation**
- [ ] Return values unchanged
- [ ] Side effects unchanged
- [ ] Exception behavior unchanged
- [ ] Edge case handling preserved

**Code Quality**
- [ ] Removed changes are genuinely AI slop (not intentional patterns)
- [ ] Remaining code follows project conventions
- [ ] No orphaned code or dead references

### Phase 4: Fix Issues
If issues are found:
1. Identify the specific problem
2. Explain why it is a problem
3. Revert only the slop-removal delta using the saved per-file patch (or equivalent reverse-apply)
4. Remove any remaining slops by editing the file yourself, per-file
5. Verify the fix introduces no new issues

## Output Format

```
## AI Slop Removal Summary

### Files Processed
- file1.ts: X changes
- file2.ts: Y changes

### Critical Review Results
- Safety: PASS/FAIL
- Behavior: PASS/FAIL
- Quality: PASS/FAIL

### Issues Found & Fixed
1. [Issue] -> [Fix applied]

### Final Status
[CLEAN / ISSUES FIXED / REQUIRES ATTENTION]
```

## Quality Assurance
- NEVER remove code that serves a functional purpose
- ALWAYS verify changes compile/parse correctly
- ALWAYS preserve test coverage
- If uncertain, err on the side of keeping the original code

