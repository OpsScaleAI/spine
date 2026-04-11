---
description: Initial assessment and memory-bank bootstrap; optional $ARGUMENTS for project briefing
agent: build
model: opencode-go/glm-5.1
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

## 0b. OpenCode project configuration

After seeding `docs/`, configure OpenCode so the project receives Spine rules as instructions.

### 0b.1 Spine rules via remote URLs

Spine rules are loaded via remote URLs from GitHub. This makes the project portable (no local path or symlink dependency) and automatically updated (the agent fetches the latest version on each session).

Base URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/`

Rule files:
- `01-core-protocol.md`
- `02-memory-bank.md`
- `03-handoff-protocol.md`
- `04-code-quality.md`
- `05-testing.md`
- `06-gitflow.md`

### 0b.2 opencode.json creation

1. Check if `opencode.json` already exists in `PROJECT_ROOT`.
2. If it exists:
   - Parse it as JSON.
   - If `"instructions"` key is present, preserve it but ensure it includes all Spine rule URLs and `"./AGENTS.md"`. Avoid duplicates.
   - Merge other keys from the existing file; do not remove user-defined settings.
3. If it does NOT exist:
   - Create a new `opencode.json` with:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/01-core-protocol.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/02-memory-bank.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/03-handoff-protocol.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/04-code-quality.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/05-testing.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/06-gitflow.md",
    "./AGENTS.md"
  ]
}
```

### 0b.3 Principles

- **Opt-in per project:** The `instructions` array with Spine rules only exists in projects that ran `/spine-bootstrap`. The global OpenCode config (`~/.config/opencode/opencode.json`) should NOT contain Spine instructions — this ensures non-Spine projects remain unaffected.
- **Portability:** Remote URLs work on any machine without a local Spine clone.
- **Auto-update:** OpenCode fetches rule content from the URL on each session, so `git push` on Spine propagates changes automatically.
- **Version pinning:** To lock to a specific version, replace `refs/heads/master` with `refs/tags/v1.0.0` in the URLs.

---

## 0c. Per-project symlinks (install.sh --project)

After creating `opencode.json`, run the Spine install script in project mode to create symlinks for skills, commands, and tool-specific configuration.

### 0c.1 Prerequisite

The `install.sh` script must be accessible from the project. This typically means:
- A `.spine` symlink exists at `PROJECT_ROOT/.spine` pointing to the Spine repository, OR
- The script is invoked with an explicit `--spine-dir=/path/to/spine` flag.

### 0c.2 Command

```bash
bash .spine/install.sh --project [--skills=core|all|list] [--targets=cursor,opencode,claude]
```

Default behavior (`--project` without `--skills`): installs **core skills** only.

Core skills (always installed by default):
- `writing-plans`
- `executing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`

### 0c.3 What gets created

| Path | Type | Purpose |
|---|---|---|
| `.spine` | symlink | Points to Spine repository |
| `.agents/skills/<name>` | per-skill symlink | Cross-tool skill hub (OpenCode + Claude Code native, Cursor via symlink) |
| `.claude/skills` | dir symlink → `.agents/skills/` | Claude Code reads skills here natively |
| `.cursor/rules/<file>.md` | per-file symlink | Cursor picks up rule files |
| `.cursor/commands` | dir symlink → `.spine/commands/` | Cursor slash commands |
| `.cursor/skills` | dir symlink → `.agents/skills/` | Cursor picks up skills hub |
| `.opencode/commands` | dir symlink → `.spine/commands/` | OpenCode slash commands |
| `.gitignore` | entries added | Machine-specific dirs excluded from version control |

### 0c.4 Skill selection

- **`--skills=core`** (default): Only core skills.
- **`--skills=all`**: All available skills from the Spine repository.
- **`--skills=python-patterns,fastapi-pro`**: Specific comma-separated skills.
- **`--add-skill=NAME`**: Add one skill to an existing install.
- **`--remove-skill=NAME`**: Remove one skill from the project.
- **`--list-skills`**: Show available and currently installed skills.

If the project has `docs/governance/skills-policy.md`, use it as a guide for which skills to select.

### 0c.5 Tool targets

- **`--targets=cursor,opencode,claude`** (default): Install for all three tools.
- **`--targets=opencode`**: Only OpenCode.
- **`--targets=cursor,claude`**: Only Cursor and Claude Code.
- Etc.

### 0c.6 Idempotency

- Re-running `--project` skips symlinks that are already correct.
- Use `--force` to replace mismatched or broken symlinks.
- Use `--dry-run` to preview changes without making them.

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
- [ ] After bootstrap, `opencode.json` exists in `PROJECT_ROOT` with `instructions` array containing all Spine rule URLs and `"./AGENTS.md"`.
- [ ] If `opencode.json` already existed, existing user settings are preserved and Spine rule URLs are merged without duplicates.
- [ ] The global `~/.config/opencode/opencode.json` does NOT contain Spine-specific `instructions` (project-level only).
- [ ] After bootstrap, per-project symlinks are created via `bash .spine/install.sh --project` (step 0c): `.agents/skills/` with per-skill symlinks, `.claude/skills` and `.cursor/skills` pointing to `.agents/skills/`, `.cursor/rules/` with per-file rule symlinks, `.cursor/commands` and `.opencode/commands` pointing to `.spine/commands/`.
- [ ] The `.gitignore` in the project includes entries for `.spine`, `.agents/`, `.cursor/`, `.claude/`, `.opencode/`, `AGENTS.md`, and `CLAUDE.md` (machine-specific files excluded from version control).
- [ ] Final summary clearly distinguishes: downloaded files, failed downloads, preserved content, gaps filled during assessment, and symlinks created in step 0c.
