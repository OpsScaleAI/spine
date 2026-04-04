---
description: Initial assessment and memory-bank bootstrap; optional $ARGUMENTS for project briefing
agent: build
model: opencode/qwen3.6-plus-free
---

# Slash Command: /spine-bootstrap
Act as the project's Initial Setup Architect.

Goal: execute an initial assessment and populate the Memory Bank with a reliable baseline.

**Optional context (`$ARGUMENTS`):** The user may provide free text after the command (Cursor injects it into `$ARGUMENTS`). If there is **non-empty** content, treat it as a project briefing: domain, stack, constraints, stakeholders, links, open questions. Incorporate it into the assessment (step 1) and when filling `project-brief.md`, `product-context.md`, `system-patterns.md`, and `tech-context.md`, without contradicting facts already present in files. If **`$ARGUMENTS` is absent or empty**, ignore this line and rely only on what can be inferred from the repository and the step 0 seed.

**General rule:** Absence of `docs/` or `docs/memory` in the invoked project **is not an error** — it is the expected condition for this command. Do not stop due to "missing-context blockage"; execute step 0 first.

---

## 0. Automatic seed (template + recursive copy)

Before any Memory Bank read in the target project, resolve the template source and, if needed, materialize `docs/` at the root of the project where the command was invoked.

### 0.1 Resolve template path (symlink-aware)

- This command file lives at `.../<spine-repo>/commands/spine-bootstrap.md` (or a **symbolic link** pointing to it).
- Resolve the **absolute and canonical** path of this file, **following symlinks** (e.g., `realpath`, `readlink -f`, or equivalent in the environment).
- The Spine source repository is the **parent** directory of `commands/`:  
  `SPINE_REPO_ROOT = dirname(dirname(<caminho-resolvido-de-spine-bootstrap.md>))`
- The documentation template directory is:  
  `TEMPLATE_DOCS = SPINE_REPO_ROOT/docs`  
  (that is, `docs/` at the root of the Spine repository; do **not** assume this content already exists in the target project.)

### 0.2 Target project

- Treat the **workspace/repository root** where the user ran the command as `PROJECT_ROOT`.
- The seed destination is: `PROJECT_ROOT/docs`.

### 0.3 When to copy

- If **`PROJECT_ROOT/docs` does not exist** (or is intentionally empty for first bootstrap — treat "does not exist" as missing/nonexistent directory):
  - Copy **all** template content recursively: every file and subdirectory under `TEMPLATE_DOCS` must be mirrored in `PROJECT_ROOT/docs`.
  - Use recursive copy in shell, for example:  
    `cp -R "$TEMPLATE_DOCS/." "$PROJECT_ROOT/docs/"`  
    (create `PROJECT_ROOT/docs` first if needed; preserve structure and files such as `.gitkeep`.)
- If **`PROJECT_ROOT/docs` already exists** with content:
  - Do **not** delete or overwrite the entire tree by default.
  - Go directly to assessment and incremental enrichment (next steps): fill gaps without destroying already-valid documented context.

### 0.4 Idempotency

- First run without `docs/`: full seed via recursive copy.
- Subsequent runs with `docs/` present: only incremental updates and gap filling.

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

- **Seed:** What was copied in step 0 (the `docs/` tree from template), if applicable.
- **Created vs. updated:** What was created in this run vs. what was only updated in assessment.
- **Preserved:** What remained untouched because it was already valid.
- **Gaps:** Information still dependent on the human.

---

## Acceptance criteria (command behavior)

- [ ] With `PROJECT_ROOT/docs` missing, flow does not block: it performs recursive seed from `SPINE_REPO_ROOT/docs` resolved via the real path of `commands/spine-bootstrap.md`.
- [ ] With `commands/` as a symbolic link, template is still found (symlink-aware resolution of command file).
- [ ] With `docs/` already present in target project, there is no destructive mass copy; only incremental enrichment in steps 2-3.
- [ ] After bootstrap, required paths for `spine-plan`, `spine-execute`, and `spine-harvest` commands exist (structure under `docs/memory/` according to copied or existing baseline).
- [ ] Final summary clearly distinguishes initial seed from enrichment.
