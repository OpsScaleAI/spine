---
description: Initial assessment and memory-bank bootstrap after setup; optional $ARGUMENTS for project briefing
agent: build
---

# Slash Command: /spine-bootstrap
Act as the project's Initial Assessment Architect.

Goal: execute an initial assessment and populate the Memory Bank with a reliable baseline.

**Optional context (`$ARGUMENTS`):** The user may provide free text after the command (Cursor injects it into `$ARGUMENTS`). If there is **non-empty** content, treat it as a project briefing: domain, stack, constraints, stakeholders, links, open questions. Incorporate it into the assessment (step 1) and when filling `project-brief.md`, `product-context.md`, `domain-glossary.md`, `system-patterns.md`, and `tech-context.md`, without contradicting facts already present in files.

**Precondition:** `bash .spine/install.sh` must have completed in this project (symlinks, `docs/` templates, `opencode.json`).

**Bridge mode (transition-safe):**

- Before step 1, validate setup readiness:
  - `docs/memory/global/project-brief.md`
  - `docs/memory/ledger/roadmap.md`
  - `docs/governance/skills-policy.md`
  - `opencode.json`
  - `.cursor/commands/` or `.opencode/commands/` (slash commands available)
- If any required setup artifact is missing:
  1. Stop assessment.
  2. Ask for confirmation: "Setup not found. Run `bash .spine/install.sh` from the project root now?"
  3. If user confirms, instruct them to run `bash .spine/install.sh` in the terminal (deterministic setup — not a slash command), then reload the IDE.
  4. Re-validate setup artifacts.
  5. Continue with assessment only after setup is valid.
- If user declines, end with a clear summary of missing setup artifacts.

---

## 1. Initial assessment (Project)

- If `$ARGUMENTS` has content, integrate it here as a priority source along with repo code and configs.
- Identify the primary stack (languages, frameworks, database, infrastructure).
- Identify project objective, scope, and boundaries.
- Identify initial technical risks and short-term priorities.
- Detect whether Graphify is already in use (`graphify-out/`, `graphify-out/graph.json`, `.graphifyignore`) and record this as context, not as a setup blocker.

---

## 2. Memory Bank bootstrap (global)

- Check existing files before changing them.
- Fill missing fields without overwriting already-valid documented context.
- Fill/normalize when needed:
  - `docs/memory/global/project-brief.md`
  - `docs/memory/global/product-context.md`
  - `docs/memory/global/domain-glossary.md` (extract domain nouns from code and `$ARGUMENTS`; do not overwrite existing terms)
  - `docs/memory/global/system-patterns.md`
  - `docs/memory/global/tech-context.md`
- Record initial decisions in:
  - `docs/memory/global/decision-log.md`

---

## 3. Memory Bank bootstrap (ledger)

- Initialize/update without deleting useful history:
  - `docs/memory/ledger/roadmap.md`
  - `docs/memory/ledger/progress.md`
  - `docs/memory/ledger/learnings.md` (if missing)
- Ensure v2.1 directories exist: `docs/memory/completed_tasks/`
- Validate `docs/governance/memory-tags-policy.md` is present (seed via `bash .spine/install.sh --update` if missing)

---

## 4. Initial task (when there is delivery scope)

- Ensure the folder `docs/memory/active_tasks/` exists.
- Define the same `<descriptive-name>` as branch `feature/<descriptive-name>`.
- Create the initial task in this format:
  - `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md`
- Example:
  - branch: `feature/setup-memory-bank`
  - task: `docs/memory/active_tasks/001-setup-memory-bank.md`
- Follow [`templates/docs/memory/active_tasks/_task-template.md`](../../templates/docs/memory/active_tasks/_task-template.md): YAML frontmatter + body sections (`## Objective`, `## Inputs`, `## Expected Outputs`, `## Acceptance Criteria`, `## Test Strategy`; optional `## Implementation Plan` for multi-step work)
- If the initial task includes UI/E2E, already record a Playwright guideline based on simplicity:
  - default to `playwright-cli` for quick exploration/validation;
  - escalate to `playwright-skill` only with real complexity (multi-step flow, multiple validations, frequent re-execution).

---

## 5. Mandatory summary

Always include:

- **Source:** Existing project files after setup.
- **Created vs. updated:** What was created in this run vs. what was only updated in assessment.
- **Memory bank files filled:** List which `docs/memory/global/*` files were populated.
- **Preserved:** What remained untouched because it was already valid.
- **Gaps:** Information still dependent on the human.
- **Setup status:** Confirm `bash .spine/install.sh` precondition was satisfied.
- **Graphify status:** Report whether `graphify-out/` and `.graphifyignore` were detected and whether graph-first retrieval is currently available. When Graphify is not detected and the repo appears medium/large (many source files, or the user mentions token/exploration cost), suggest in **Gaps**: "Graphify not detected. To enable: see Spine README § Optional: Graphify, or run `bash .spine/scripts/update.sh --graphify-init`."

---

## Acceptance criteria (command behavior)

- [ ] Command validates setup readiness before assessment (`opencode.json`, `docs/memory/` structure).
- [ ] If setup is missing, command asks confirmation to run `bash .spine/install.sh` (bridge mode), then re-validates and continues only if setup is complete.
- [ ] Command performs only assessment and memory-bank bootstrap (no installation/setup side effects).
- [ ] Global memory files are filled/normalized without overwriting valid existing context.
- [ ] Ledger files (`roadmap`, `progress`, `learnings`) are initialized/updated without deleting useful history.
- [ ] `completed_tasks/` directory exists; `memory-tags-policy.md` is present or flagged in gaps.
- [ ] If there is delivery scope, an initial active task follows `_task-template.md` structure.
- [ ] Final summary clearly lists memory bank files filled, preserved files, known gaps, and setup precondition status.
