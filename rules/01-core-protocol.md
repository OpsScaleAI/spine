---
description: "Core protocol for solo-lean operation: focus on delivery, testing, and memory."
globs: 
alwaysApply: true
---

# CORE PROTOCOL (Solo Lean)

## 1. Mandatory minimum flow
1. **Sync:** read the context in `docs/memory/` (global + ledger + active task).
   - If `graphify-out/graph.json` exists, query graph first for exploration and architecture mapping before broad file scanning.
2. **Plan:** create/update `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md` with scope, acceptance criteria, and a branch suggestion (`Branch: feature/<descriptive-name>`, `Base: develop`). Do not create the branch during planning.
3. **Branch:** at execution time, create or switch to the branch specified in the task file, based on `Base`.
4. **Test:** define a test strategy (preferably TDD).
5. **Execute:** implement atomically and validate tests.
6. **Harvest:** update `progress.md` and `decision-log.md` when applicable.

## 2. Definition of Done
- [ ] Isolated branch created from `develop`
- [ ] `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md` with scope and acceptance criteria
- [ ] Tests executed and passing
- [ ] `docs/memory/ledger/progress.md` updated
- [ ] `docs/memory/global/decision-log.md` updated (if there was an architectural decision)

## 3. Guard rails
- Never use `git push --force`.
- Never assume an ambiguous requirement without confirmation.
- No silent decisions: architectural decisions require a recorded "why".
- Avoid overengineering: prefer simple, evolvable solutions.

## 4. Commits
Preferir Conventional Commits:
- `feat:`
- `fix:`
- `refactor:`
- `test:`
- `docs:`
- `chore:`