---
description: Plan a task, create memory-bank artifact, and prepare test strategy
agent: build
---

# Slash Command: /spine-plan

Act as a Senior Software Architect. Follow the instructions provided in $ARGUMENTS.

**Native Plan input:** If `$ARGUMENTS` contains a native Plan draft (from Cursor Plan mode or similar), treat it as input to normalize into the active task artifact. Native Plan = draft; `/spine-plan` = versioned contract in `docs/memory/active_tasks/`. Discovery and GitFlow rules below still apply.

1. **Discovery (conditional — `@grill-me`):**
   Run `@grill-me` **before** `@writing-plans` when **any** of the following applies. Otherwise skip discovery and proceed to step 2.

   **Trigger precedence (first match wins):**

   1. **Explicit opt-out:** if `$ARGUMENTS` contains (case-insensitive) `skip discovery`, `no grill`, or `direct plan`, skip `@grill-me` regardless of scope clarity.
   2. **Explicit opt-in:** if `$ARGUMENTS` contains (case-insensitive) `grill me`, `grill:`, `grill -`, `grill with docs`, `grill:docs`, `stress-test`, or `challenge this`, run `@grill-me` even when scope appears clear. Strip the trigger phrase; use the remainder as the task briefing. When `grill with docs` or `grill:docs` is used, expect inline updates to `domain-glossary.md` and `decision-log.md` per the skill.
   3. **Implicit:** run `@grill-me` when scope is ambiguous, broad, multi-domain, or when major architectural/security/auth/schema/infrastructure decisions are unresolved.

   **When `@grill-me` is active:**

   - Use the `@grill-me` skill: one question at a time; provide a recommended answer; explore the codebase when the answer is discoverable there.
   - Read memory bank global files (`domain-glossary.md`, `product-context.md`, `system-patterns.md`, `decision-log.md`); promote canonical terms and architectural decisions per the skill's knowledge-promotion rules.
   - Do **not** write the full plan until discovery is complete.
   - Record outcomes in `## Discovery notes` on the task file (create the file early with frontmatter `status: PLANNING` if needed to capture notes incrementally). Note any updates made to `domain-glossary.md` or `decision-log.md`.

   **Retroactive opt-in:** if the user asks to be grilled mid-session before the plan is written, switch to `@grill-me` and resume planning after discovery completes.

   **Shared context rules (always apply):**

   - If `$ARGUMENTS` contains non-empty content, treat it as a project briefing and incorporate it into scope without contradicting facts already present in memory bank files.
   - If `graphify-out/graph.json` exists in the project, query graph first for exploration and architecture discovery, then use direct file reads for implementation details. If graph is missing/stale, fallback to normal repository reading.

2. **Planning Skill (mandatory):**
   - Use the `@writing-plans` skill to structure the plan into small, testable, executable tasks.
   - Run only after discovery is complete or skipped.
   - If there is a conflict between a skill and this command, **this command takes precedence** to preserve the project workflow.

3. **Execution Skill Selection (contextual):**
   - Based on the task's domain and technology, select the most appropriate execution skill:
     - Default: `@executing-plans` (generic implementation workflow)
     - Domain-specific: choose based on the task nature and available skills in `docs/governance/skills-policy.md`
     - Examples: `@terraform-infrastructure` for IaC tasks, `@fastapi-pro` for API tasks, `@django-pro` for Django projects, `@ansible` for Ansible playbooks
   - For UI/E2E tasks with Playwright:
     - Default to `playwright-cli` for quick exploration, targeted debugging, and short actions
     - Escalate to `playwright-skill` only for multi-step flows, multiple validations, or re-runnable scripts
     - Anti-overengineering rule: when in doubt, start simple and escalate only if real complexity emerges
   - Record in frontmatter as `execution_skill: <skill-name>` (without `@` prefix).

4. **Task Plan in the Memory Bank:**
   - **GitFlow is mandatory (not optional):** every plan must follow GitFlow branch conventions.
   - **Mandatory branch policy:** `feature/<descriptive-name>` as execution branch, `develop` as base. Never create the branch during planning.
   - Ensure `docs/memory/active_tasks/` exists.
   - **Sequential numbering:** scan `docs/memory/active_tasks/` **and** `docs/memory/completed_tasks/` for max `NNN`. Ignore `_task-template.md` and files not matching `^\d{3}-`.
   - Create: `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md`
   - Example: `docs/memory/active_tasks/007-social-login-adjustment.md`
   - Create the task file with **Obsidian-style YAML frontmatter** per `02-memory-bank.md` and `docs/governance/memory-tags-policy.md`:
     - `task_id`, `title`, `goal`, `status: PLANNING`
     - `tags:` YAML list (1–5 tags; grep `learnings.md` and recent progress for related tags before inventing new ones)
     - `branch`, `base: develop`, `execution_skill`
     - `created_at`, `updated_at` (today, `YYYY-MM-DD`)
     - `completed_at:` (empty), `related_learnings: []`
   - Body sections (no inline `## Branch`, `## Base`, or `## Status`):
     - `## Discovery notes` (when `@grill-me` ran)
     - Objective, Inputs, Expected outputs, Acceptance criteria, Test strategy

5. **Scope Validation:** After writing the plan, evaluate whether it is well-scoped before presenting it for approval:
   - **More than 2 execution skills needed?** → Suggest splitting into separate plans, each with a single primary skill.
   - **More than 7 acceptance criteria?** → Suggest splitting into smaller plans with tighter scope.
   - **Domains mixed** (e.g., infrastructure + UI + backend in the same plan)? → Suggest splitting along domain boundaries.
   - Present your evaluation to the user: "This plan covers [X domains / Y acceptance criteria]. I recommend splitting into [N] smaller plans. Proceed as-is or split?"
   - If the user chooses to split: create the first plan immediately and note the remaining plans as suggestions in `docs/memory/ledger/roadmap.md`.

6. **Test Strategy:** Define which tests will be created/updated in `tests/` and the execution command.
   - If there is UI/E2E, record in the strategy which Playwright skill will be used and why.

7. **Approval Gate:** Stop and ask for confirmation:
   - "Plan created at docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md. Can I execute?"
