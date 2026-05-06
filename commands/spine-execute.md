---
description: Execute the active task with implementation, validation, and status updates in the memory-bank
agent: build
---

# Slash Command: /spine-execute <plan_file_path>
Act as a Software Engineer focused on rigorous implementation.

1. **Active Task Selection:** Use the provided `<plan_file_path>` argument.
   - Validate if the file exists and has a `.md` extension.
2. **Branch Setup:** Read the `Branch` and `Base` fields from the active task file.
   - **GitFlow is mandatory (not optional) during execution.**
   - `Base` must be `develop` and `Branch` must follow `feature/<descriptive-name>`.
   - Ensure you are on the `Base` branch. Run `git checkout <base> && git pull`.
   - If the specified `Branch` does not exist yet, create it: `git checkout -b <branch>`.
   - If the `Branch` already exists, switch to it: `git checkout <branch>`.
   - If `Branch` or `Base` fields are missing, stop and request a plan correction before implementation.
   - If `Base` is not `develop` or `Branch` does not match `feature/<descriptive-name>`, stop and request correction to comply with GitFlow.
3. **Context Reading:** Read the selected active task (`<sequential-number>-<descriptive-name>.md`) and related tests mandatorily.
4. **Execution Skill Selection:**
   - Use the skill specified in the `Suggested execution skill` field of the active task.
   - If no skill is specified, default to `@executing-plans`.
   - Respect `docs/governance/skills-policy.md` to validate allowlist/trial and per-project skill limits.
   - For UI/E2E with Playwright, follow the decision defined in the active task:
     - keep `playwright-cli` for short/interactive tasks;
     - use `playwright-skill` only for multi-step flows, multiple validations, and re-runnable scripts.
   - Do not switch from `playwright-cli` to `playwright-skill` (or vice versa) without recording an objective justification in the active task.
5. **Atomic Implementation:** Implement the required code by following `docs/memory/global/system-patterns.md` and the active task guidelines.
6. **Validation Cycle:**
   - Run the test command defined in the active task (`<sequential-number>-<descriptive-name>.md`).
   - If it fails, analyze the error and fix the code (not the test, unless the test is logically wrong).
   - Repeat until all tests pass.
7. **Execution Status:** Update `<sequential-number>-<descriptive-name>.md` to `IN_PROGRESS` at the beginning and `REVIEW` when implementation is complete.
   - When marking `REVIEW`, record a minimal checklist with:
     - tests executed
     - test results
8. **Restriction:** Do not perform refactors outside the active task scope. If you find a necessary improvement, record it in "Notes" in the task itself.
9. **Completion Gate (mandatory):**
   - Before sending the final execution response, verify that the active task file status is `REVIEW`.
   - If status is not `REVIEW`, stop and update it before completion.
   - `REVIEW` is valid only if evidence is present:
     - `Tests executed` list
     - `Test results` summary
   - If test evidence is missing, stop and update the active task file before completion.
