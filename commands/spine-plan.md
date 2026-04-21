---
description: Plan a task, create memory-bank artifact, and prepare test strategy
agent: build
model: opencode-go/glm-5.1
---

# Slash Command: /spine-plan
Act as a Senior Software Architect. Follow the instructions provided in $ARGUMENTS.

1. **Context Sync:** Read the following files mandatorily:
   - `docs/memory/global/project-brief.md`
   - `docs/memory/global/product-context.md`
   - `docs/memory/global/system-patterns.md`
   - `docs/memory/global/tech-context.md`
   - `docs/memory/global/decision-log.md`
   - `docs/memory/ledger/roadmap.md`
   - `docs/memory/ledger/progress.md`
2. **Recommended Skill (mandatory for plan quality):**
   - Use the `@writing-plans` skill to structure the plan into small, testable, executable tasks.
   - Select additional skills while respecting `docs/governance/skills-policy.md` (allowlist/trial/per-project limit).
   - For UI/E2E tasks with Playwright, explicitly define in the active task:
     - use `playwright-cli` for quick exploration, targeted debugging, and short actions;
     - use `playwright-skill` only when there is a multi-step flow, multiple validations, or need for a re-runnable script.
   - Anti-overengineering rule: when in doubt, start with `playwright-cli` and only escalate to `playwright-skill` if real complexity emerges.
   - If there is a conflict between a skill and this command, **this command takes precedence** to preserve the project workflow.
3. **Task Plan in the Memory Bank:**
   - Ensure the folder `docs/memory/active_tasks/` exists.
   - Determine the next sequential number by inspecting existing task files in `docs/memory/active_tasks/`.
   - Create:
     - `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md`
   - Example:
     - task: `docs/memory/active_tasks/007-social-login-adjustment.md`
   - Create the task file with:
     - `## Branch: feature/<descriptive-name>` — specifies which branch will be created at execution time. Never create the branch during planning.
     - `## Base: develop` — the branch will be created from this base.
     - Initial status: `PLANNING`
     - Objective
     - Inputs
     - Expected outputs (artifacts and target directories)
     - Acceptance criteria (checklist)
     - Test strategy (positive, negative, regression)
   - Include this line at the top of the task:
     - `Suggested execution skill: @executing-plans`
4. **Test Strategy:** Define which tests will be created/updated in `tests/` and the execution command.
   - If there is UI/E2E, record in the strategy which Playwright skill will be used and why.
5. **Approval Gate:** Stop and ask for confirmation:
   - "Plan created at docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md. Can I execute?"
