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
2. **Scope Clarification:** Before writing the plan, validate the scope of `$ARGUMENTS`:
   - If `$ARGUMENTS` is clear and specific (single deliverable, single domain): proceed directly.
   - If `$ARGUMENTS` is ambiguous or broad (multiple deliverables, unclear boundaries, vague description): ask the user to clarify before planning:
     - "What is the minimum viable deliverable that makes this task done?"
     - "What is explicitly out of scope for this plan?"
     - "Which domain is the primary focus? (e.g., backend API, frontend UI, infrastructure, database)"
   - Principle: one plan should be completable in a single execution session. If the scope feels too large, suggest splitting into multiple plans upfront.
   - If `$ARGUMENTS` contains non-empty content, treat it as a project briefing and incorporate it into the scope definition without contradicting facts already present in memory bank files.
3. **Planning Skill (mandatory):**
   - Use the `@writing-plans` skill to structure the plan into small, testable, executable tasks.
   - If there is a conflict between a skill and this command, **this command takes precedence** to preserve the project workflow.
4. **Execution Skill Selection (contextual):**
   - Based on the task's domain and technology, select the most appropriate execution skill:
     - Default: `@executing-plans` (generic implementation workflow)
     - Domain-specific: choose based on the task nature and available skills in `docs/governance/skills-policy.md`
     - Examples: `@terraform-infrastructure` for IaC tasks, `@fastapi-pro` for API tasks, `@django-pro` for Django projects, `@ansible` for Ansible playbooks
   - For UI/E2E tasks with Playwright:
     - Default to `playwright-cli` for quick exploration, targeted debugging, and short actions
     - Escalate to `playwright-skill` only for multi-step flows, multiple validations, or re-runnable scripts
     - Anti-overengineering rule: when in doubt, start simple and escalate only if real complexity emerges
   - Record the selected skill in the task file as: `Suggested execution skill: @<skill-name>`
5. **Task Plan in the Memory Bank:**
   - Ensure the folder `docs/memory/active_tasks/` exists.
   - Determine the next sequential number by inspecting existing task files in `docs/memory/active_tasks/`.
   - Create:
     - `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md`
   - Example:
     - task: `docs/memory/active_tasks/007-social-login-adjustment.md`
   - Create the task file with:
     - `Suggested execution skill: @<skill-name>` — the skill selected in step 4
     - `## Branch: feature/<descriptive-name>` — specifies which branch will be created at execution time. Never create the branch during planning.
     - `## Base: develop` — the branch will be created from this base.
     - Initial status: `PLANNING`
     - Objective
     - Inputs
     - Expected outputs (artifacts and target directories)
     - Acceptance criteria (checklist)
     - Test strategy (positive, negative, regression)
6. **Scope Validation:** After writing the plan, evaluate whether it is well-scoped before presenting it for approval:
   - **More than 2 execution skills needed?** → Suggest splitting into separate plans, each with a single primary skill.
   - **More than 7 acceptance criteria?** → Suggest splitting into smaller plans with tighter scope.
   - **Domains mixed** (e.g., infrastructure + UI + backend in the same plan)? → Suggest splitting along domain boundaries.
   - Present your evaluation to the user: "This plan covers [X domains / Y acceptance criteria]. I recommend splitting into [N] smaller plans. Proceed as-is or split?"
   - If the user chooses to split: create the first plan immediately and note the remaining plans as suggestions in `docs/memory/ledger/roadmap.md`.
7. **Test Strategy:** Define which tests will be created/updated in `tests/` and the execution command.
   - If there is UI/E2E, record in the strategy which Playwright skill will be used and why.
8. **Approval Gate:** Stop and ask for confirmation:
   - "Plan created at docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md. Can I execute?"
