---
description: Execute the active task with implementation, validation, and status updates in the memory-bank
agent: build
---

# Slash Command: /spine-execute <plan_file_path>
Act as a Software Engineer focused on rigorous implementation.

1. **Active Task Selection:** Use the provided `<plan_file_path>` argument.
   - Validate if the file exists and has a `.md` extension.
   - File must be under `docs/memory/active_tasks/` (open tasks only; completed tasks live in `completed_tasks/`).
2. **Branch Setup:** Read `branch` and `base` from task YAML frontmatter (fallback: legacy `## Branch:` / `## Base:` if present).
   - **GitFlow is mandatory (not optional) during execution.**
   - `base` must be `develop` and `branch` must follow `feature/<descriptive-name>`.
   - Ensure you are on the `base` branch. Run `git checkout <base> && git pull`.
   - If the specified `branch` does not exist yet, create it: `git checkout -b <branch>`.
   - If the `branch` already exists, switch to it: `git checkout <branch>`.
   - If `branch` or `base` are missing, stop and request a plan correction before implementation.
   - If `base` is not `develop` or `branch` does not match `feature/<descriptive-name>`, stop and request correction to comply with GitFlow.
3. **Context Reading:** Read the selected active task mandatorily:
   - YAML frontmatter (`goal`, `tags`, `execution_skill`, …)
   - `## Acceptance Criteria`, `## Test Strategy`
   - `## Implementation Plan` when present — use Task/Step blocks as the execution checklist (batch via `@executing-plans`)
   - If Implementation Plan is **missing** and there are **>3** acceptance criteria, stop and ask to extend the plan or proceed criterion-by-criterion
4. **Execution Skill Selection:**
   - Use the skill specified in frontmatter `execution_skill` (fallback: legacy `Suggested execution skill` field).
   - If no skill is specified, default to `@executing-plans`.
   - Respect `docs/governance/skills-policy.md` to validate allowlist/trial and per-project skill limits.
   - For UI/E2E with Playwright, follow the decision defined in the active task:
     - keep `playwright-cli` for short/interactive tasks;
     - use `playwright-skill` only for multi-step flows, multiple validations, and re-runnable scripts.
   - Do not switch from `playwright-cli` to `playwright-skill` (or vice versa) without recording an objective justification in the active task.
5. **Code discovery (when locating implementation targets):** If `graphify-out/graph.json` exists and the target file/module is unclear, follow the **Graphify Discovery Protocol** in `02-memory-bank.md` before broad Glob/grep scans.
6. **Atomic Implementation:** Implement the required code by following `docs/memory/global/system-patterns.md` and the active task guidelines.
7. **Validation Cycle:**
   - Run the test command defined in the active task.
   - If it fails, analyze the error and fix the code (not the test, unless the test is logically wrong).
   - Repeat until all tests pass.
8. **Execution Status:** Update frontmatter at start and end:
   - At beginning: `status: IN_PROGRESS`, bump `updated_at`.
   - When complete: `status: REVIEW`, bump `updated_at`.
   - When marking `REVIEW`, record a minimal checklist with tests executed and test results in the task body.
9. **Restriction:** Do not perform refactors outside the active task scope. If you find a necessary improvement, record it in "Notes" in the task itself.
10. **Completion Gate (mandatory):**
   - Before sending the final execution response, verify frontmatter `status` is `REVIEW`.
   - If status is not `REVIEW`, stop and update it before completion.
   - `REVIEW` is valid only if evidence is present: `Tests executed` list and `Test results` summary.
   - If test evidence is missing, stop and update the active task file before completion.
