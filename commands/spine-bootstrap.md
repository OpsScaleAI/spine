---
description: Initial assessment and memory-bank bootstrap after setup; optional $ARGUMENTS for project briefing
agent: build
model: opencode-go/glm-5.1
---

# Slash Command: /spine-bootstrap
Act as the project's Initial Assessment Architect.

Goal: execute an initial assessment and populate the Memory Bank with a reliable baseline.

**Optional context (`$ARGUMENTS`):** The user may provide free text after the command (Cursor injects it into `$ARGUMENTS`). If there is **non-empty** content, treat it as a project briefing: domain, stack, constraints, stakeholders, links, open questions. Incorporate it into the assessment (step 1) and when filling `project-brief.md`, `product-context.md`, `system-patterns.md`, and `tech-context.md`, without contradicting facts already present in files.

**Precondition:** `/spine-install` should be executed in this project first.

**Bridge mode (transition-safe):**

- Before step 1, validate setup readiness:
  - `docs/memory/global/project-brief.md`
  - `docs/memory/ledger/roadmap.md`
  - `docs/governance/skills-policy.md`
  - `opencode.json`
- If any required setup artifact is missing:
  1. Stop assessment.
  2. Ask for confirmation: "Setup not found. Run `/spine-install` now?"
  3. If user confirms, execute `/spine-install`.
  4. Re-validate setup artifacts.
  5. Continue with assessment only after setup is valid.
- If user declines running `/spine-install`, end with a clear summary of missing setup artifacts.

---

## 1. Initial assessment (Project)

- If `$ARGUMENTS` has content, integrate it here as a priority source along with repo code and configs.
- Identify the primary stack (languages, frameworks, database, infrastructure).
- Identify project objective, scope, and boundaries.
- Identify initial technical risks and short-term priorities.

---

## 2. Memory Bank bootstrap (global)

- Check existing files before changing them.
- Fill missing fields without overwriting already-valid documented context.
- Fill/normalize when needed:
  - `docs/memory/global/project-brief.md`
  - `docs/memory/global/product-context.md`
  - `docs/memory/global/system-patterns.md`
  - `docs/memory/global/tech-context.md`
- Record initial decisions in:
  - `docs/memory/global/decision-log.md`

---

## 3. Memory Bank bootstrap (ledger)

- Initialize/update without deleting useful history:
  - `docs/memory/ledger/roadmap.md`
  - `docs/memory/ledger/progress.md`

---

## 4. Initial task (when there is delivery scope)

- Ensure the folder `docs/memory/active_tasks/` exists.
- Define the same `<descriptive-name>` as branch `feature/<descriptive-name>`.
- Create the initial task in this format:
  - `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md`
- Example:
  - branch: `feature/setup-memory-bank`
  - task: `docs/memory/active_tasks/001-setup-memory-bank.md`
- Structure the task with:
  - objective
  - inputs
  - expected outputs
  - acceptance criteria
  - test strategy
  - status `PLANNING`
- If the initial task includes UI/E2E, already record a Playwright guideline based on simplicity:
  - default to `playwright-cli` for quick exploration/validation;
  - escalate to `playwright-skill` only with real complexity (multi-step flow, multiple validations, frequent re-execution).

---

## 5. Mandatory summary

Always include:

- **Source:** Existing project files after setup.
- **Created vs. updated:** What was created in this run vs. what was only updated in assessment.
- **Preserved:** What remained untouched because it was already valid.
- **Gaps:** Information still dependent on the human.
- **Setup status:** Confirm `/spine-install` precondition was satisfied.

---

## Acceptance criteria (command behavior)

- [ ] Command validates setup readiness before assessment.
- [ ] If setup is missing, command asks confirmation to run `/spine-install` (bridge mode), then re-validates and continues only if setup is complete.
- [ ] Command performs only assessment and memory-bank bootstrap (no installation/setup side effects).
- [ ] Global memory files are filled/normalized without overwriting valid existing context.
- [ ] Ledger files (`roadmap`, `progress`) are initialized/updated without deleting useful history.
- [ ] If there is delivery scope, an initial active task is created in `docs/memory/active_tasks/`.
- [ ] Final summary clearly distinguishes: created vs. updated, preserved files, known gaps, and setup precondition status.
