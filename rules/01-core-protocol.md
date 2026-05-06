---
description: "Core protocol for solo-lean operation: focus on delivery, testing, and memory."
globs: 
alwaysApply: true
---

# CORE PROTOCOL (Solo Lean)

## 1. Mandatory minimum flow
1. **Sync:** read the context in `docs/memory/` (global + ledger + active task).
   - If `graphify-out/graph.json` exists, query graph first for exploration and architecture mapping before broad file scanning.
2. **Clarify:** before any code change, state:
   - Key assumptions about the task.
   - Any ambiguities or conflicting interpretations — present them, don't pick silently.
   - The simplest approach identified. If a simpler alternative exists, name it and push back.
3. **Plan:** create/update `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md` with scope, verifiable acceptance criteria (each paired with a test), and a branch suggestion (`Branch: feature/<descriptive-name>`, `Base: develop`). Do not create the branch during planning.
4. **Branch:** at execution time, create or switch to the branch specified in the task file, based on `Base`.
5. **Test (TDD):**
   a. Write a failing test for the first acceptance criterion.
   b. Implement the minimum code to make it pass.
   c. Refactor if needed while keeping tests green.
   d. Repeat for each acceptance criterion.
6. **Execute:** implement atomically and validate all tests pass.
7. **Harvest:** update `progress.md` and `decision-log.md` when applicable.

## 2. Definition of Done
- [ ] Isolated branch created from `develop`
- [ ] `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md` with scope and acceptance criteria
- [ ] Tests executed and passing
- [ ] `docs/memory/ledger/progress.md` updated
- [ ] `docs/memory/global/decision-log.md` updated (if there was an architectural decision)

## 3. Guard rails
- Never use `git push --force`.
- Never assume an ambiguous requirement without confirmation. Surface assumptions and tradeoffs first.
- No silent decisions: architectural decisions require a recorded "why".
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If an implementation exceeds 3x the minimum viable lines, justify why.

## 4. Commits
Prefer Conventional Commits:
- `feat:`
- `fix:`
- `refactor:`
- `test:`
- `docs:`
- `chore:`