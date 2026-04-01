---
description: Execute the active task with implementation, validation, and status updates in the memory-bank
agent: build
model: anthropic/claude-3-5-sonnet-20241022
---

# Slash Command: /execute
Act as a Software Engineer focused on rigorous implementation.

1. **Active Task Selection:** Identify the most recent task in `docs/memory/active_tasks/` with status `PLANNING` or `IN_PROGRESS`.
   - If there is more than one candidate task, STOP and ask for human confirmation.
2. **Context Reading:** Read the selected active task (`<sequential-number>-<descriptive-name>.md`) and related tests mandatorily.
3. **Execution Skill Selection:**
   - Prioritize the skill suggested in the active task (e.g., `Suggested execution skill: @executing-plans`).
   - Respect `docs/governance/skills-policy.md` to validate allowlist/trial and per-project skill limits.
   - For UI/E2E with Playwright, follow the decision defined in the active task:
     - keep `playwright-cli` for short/interactive tasks;
     - use `playwright-skill` only for multi-step flows, multiple validations, and re-runnable scripts.
   - Do not switch from `playwright-cli` to `playwright-skill` (or vice versa) without recording an objective justification in the active task.
4. **Atomic Implementation:** Implement the required code by following `docs/memory/global/system-patterns.md` and the active task guidelines.
5. **Validation Cycle:**
   - Run the test command defined in the active task (`<sequential-number>-<descriptive-name>.md`).
   - If it fails, analyze the error and fix the code (not the test, unless the test is logically wrong).
   - Repeat until all tests pass.
6. **Execution Status:** Update `<sequential-number>-<descriptive-name>.md` to `IN_PROGRESS` at the beginning and `REVIEW` when implementation is complete.
   - When marking `REVIEW`, record a minimal checklist with:
     - tests executed
     - test results
7. **Restriction:** Do not perform refactors outside the active task scope. If you find a necessary improvement, record it in "Notes" in the task itself.
