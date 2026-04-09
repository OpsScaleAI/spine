---
description: Initial assessment and memory-bank bootstrap; optional $ARGUMENTS for project briefing
agent: build
model: nvidia/z-ai/glm5
---

# Slash Command: /spine-bootstrap
Act as the project's Initial Setup Architect.

Goal: execute an initial assessment and populate the Memory Bank with a reliable baseline.

**Optional context (`$ARGUMENTS`):** The user may provide free text after the command (Cursor injects it into `$ARGUMENTS`). If there is **non-empty** content, treat it as a project briefing: domain, stack, constraints, stakeholders, links, open questions. Incorporate it into the assessment (step 1) and when filling `project-brief.md`, `product-context.md`, `system-patterns.md`, and `tech-context.md`, without contradicting facts already present in files. If **`$ARGUMENTS` is absent or empty**, ignore this line and rely only on what can be inferred from the repository and the step 0 seed.

**General rule:** Absence of `docs/` or `docs/memory` in the invoked project **is not an error** — it is the expected condition for this command. Do not stop due to "missing-context blockage"; execute step 0 first.

---

## 0. Automatic seed (GitHub raw download)

Before any Memory Bank read in the target project, download the template from the canonical Spine repository on GitHub and materialize `docs/` at the root of the project where the command was invoked.

### 0.1 Source repository

- Spine is hosted at: `https://github.com/OpsScaleAI/spine`
- Raw content base URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master`
- This is the canonical source; no local path resolution required.

### 0.2 Target project

- Treat the **workspace/repository root** where the user ran the command as `PROJECT_ROOT`.
- The seed destination is: `PROJECT_ROOT/docs`.

### 0.3 Download mechanism

1. Detect available tool: check `curl` first, fallback to `wget`.
2. Create directory structure:
   - `mkdir -p "$PROJECT_ROOT/docs/memory/global"`
   - `mkdir -p "$PROJECT_ROOT/docs/memory/ledger"`
   - `mkdir -p "$PROJECT_ROOT/docs/memory/active_tasks"`
   - `mkdir -p "$PROJECT_ROOT/docs/governance"`
   - `mkdir -p "$PROJECT_ROOT/docs/quality"`
   - `mkdir -p "$PROJECT_ROOT/docs/workflow"`
3. Download files sequentially (in order of importance):
   - Memory Bank global files (project-brief, product-context, system-patterns, tech-context, decision-log)
   - Memory Bank ledger files (roadmap, progress)
   - Governance and workflow docs (skills-policy, guardrails, gitflow-operacional, ciclo-de-entrega)
   - Create empty `.gitkeep` in `active_tasks/` (download or create if not available)
4. Download command: prefer `curl -fsSL <URL> -o <path>`, fallback to `wget -q <URL> -O <path>`.

### 0.4 Files to download

Base URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/`

Paths:
- `templates/docs/memory/global/project-brief.md`
- `templates/docs/memory/global/product-context.md`
- `templates/docs/memory/global/system-patterns.md`
- `templates/docs/memory/global/tech-context.md`
- `templates/docs/memory/global/decision-log.md`
- `templates/docs/memory/ledger/roadmap.md`
- `templates/docs/memory/ledger/progress.md`
- `templates/docs/governance/skills-policy.md`
- `templates/docs/quality/guardrails.md`
- `templates/docs/workflow/gitflow-operacional.md`
- `templates/docs/workflow/ciclo-de-entrega.md`
- Create `.gitkeep` in `docs/memory/active_tasks/` (no download needed)

### 0.5 Error handling

- If GitHub unreachable: output clear message with manual download instructions (provide full GitHub repo URL).
- If individual file fails: continue with remaining files, report in summary.
- Never fail entire bootstrap because of one file.

### 0.6 Idempotency

- First run without `docs/`: full download from GitHub.
- Subsequent runs with `docs/` present: only fill missing files.
- Never overwrite existing content.

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

- **Source:** Downloaded from GitHub (raw URLs) or preserved from existing `docs/`.
- **Downloaded:** List of files successfully downloaded from GitHub in step 0.
- **Failed downloads:** List any files that could not be downloaded (if any).
- **Created vs. updated:** What was created in this run vs. what was only updated in assessment.
- **Preserved:** What remained untouched because it was already valid.
- **Gaps:** Information still dependent on the human.

---

## Acceptance criteria (command behavior)

- [ ] With `PROJECT_ROOT/docs` missing, flow downloads template from GitHub raw URLs using `curl` or `wget` (auto-detected).
- [ ] Download mechanism creates required directory structure before downloading files.
- [ ] With `docs/` already present in target project, only fills gaps without overwriting existing content.
- [ ] GitHub unavailability produces clear error message with manual download instructions (GitHub repo URL).
- [ ] Individual file download failures do not block the entire bootstrap; remaining files continue to download.
- [ ] After bootstrap, required paths for `spine-plan`, `spine-execute`, and `spine-harvest` commands exist (structure under `docs/memory/`).
- [ ] Final summary clearly distinguishes: downloaded files, failed downloads, preserved content, and gaps filled during assessment.
