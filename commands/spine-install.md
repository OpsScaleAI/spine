---
description: Project setup command; installs rules, commands, skills, and downloads docs templates
agent: build
---

# Slash Command: /spine-install
Act as the project's Setup Installer.

Goal: perform project setup (installation) only. Do not run project assessment in this command.

---

## 0. Automatic seed (GitHub raw download)

Before any Memory Bank assessment, download the template from the canonical Spine repository on GitHub and materialize `docs/` at the root of the project where the command was invoked.

### 0.1 Source repository

- Spine is hosted at: `https://github.com/OpsScaleAI/spine`
- Raw content base URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master`
- This is the canonical source; no local path resolution required.

### 0.2 Target project

- Treat the workspace/repository root where the user ran the command as `PROJECT_ROOT`.
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
   - `mkdir -p "$PROJECT_ROOT/docs/documentation"` (for project documentation, supporting documents, and discoveries)
3. Download files sequentially:
   - Memory Bank global files (project-brief, product-context, system-patterns, tech-context, decision-log)
   - Memory Bank ledger files (roadmap, progress)
   - Governance and workflow docs (skills-policy, guardrails, gitflow-operacional, ciclo-de-entrega)
4. Create empty `.gitkeep` in `docs/memory/active_tasks/`.
5. Download command: prefer `curl -fsSL <URL> -o <path>`, fallback to `wget -q <URL> -O <path>`.

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

### 0.5 AGENTS.md handling

After downloading `docs/` templates, handle the project-level `AGENTS.md`:

1. Check if `PROJECT_ROOT/AGENTS.md` already exists.
2. If it exists and does **not** contain the Spine header (`# AGENTS.md` line followed by the Spine description phrase):
   - Rename the existing file to `PROJECT_ROOT/AGENTS-original.md`.
   - Download `templates/AGENTS.md` from GitHub to `PROJECT_ROOT/AGENTS.md`.
   - Inform the user that the original file was preserved as `AGENTS-original.md`.
3. If it exists and **already contains** the Spine header (idempotent re-run):
   - Skip — do not overwrite.
4. If it does not exist:
   - Download `templates/AGENTS.md` from GitHub to `PROJECT_ROOT/AGENTS.md`.
5. Never overwrite an existing `AGENTS-original.md`.

Source URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/templates/AGENTS.md`

### 0.6 opencode.json handling (template download)

After handling `AGENTS.md`, handle the project-level `opencode.json`:

1. Check if `PROJECT_ROOT/opencode.json` already exists.
2. If it exists:
   - Parse it as JSON.
   - If `"instructions"` key is present, preserve it but ensure it includes all Spine rule URLs and `"./AGENTS.md"`. Avoid duplicates.
   - Merge other keys from the existing file; do not remove user-defined settings.
3. If it does not exist:
   - Download `templates/opencode.json` from GitHub to `PROJECT_ROOT/opencode.json`.
   - This provides the minimal template with `$schema` and Spine rule instructions only.

Source URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/templates/opencode.json`

### 0.7 Error handling

- If GitHub is unreachable: output clear message with manual download instructions (full GitHub repo URL).
- If an individual file download fails: continue with remaining files and report failures in summary.
- Never fail entire setup because of one file.

### 0.8 Idempotency

- First run without `docs/`: full download from GitHub.
- Subsequent runs with `docs/` present: only fill missing files.
- Never overwrite existing content.

---

## 1. OpenCode rules reference

### 1.1 Spine rules via remote URLs

Base URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/`

Rule files:
- `01-core-protocol.md`
- `02-memory-bank.md`
- `03-handoff-protocol.md`
- `04-code-quality.md`
- `05-testing.md`
- `06-gitflow.md`

### 1.2 Principles

- Opt-in per project only; do not add Spine instructions to global `~/.config/opencode/opencode.json`.
- Remote URLs provide portability and auto-update behavior.
- Version pinning is supported by replacing `refs/heads/master` with a tag.
- `$schema`, `model`, `permission`, `command`, and `compaction` settings are project-specific and should be configured by the user in `opencode.json` after setup.

---

## 2. Per-project symlink installation

Run the Spine installer in project mode to create symlinks for skills, commands, and tool-specific configuration.

### 2.1 Command

```bash
bash .spine/install.sh --project [--skills=all|core|list] [--targets=cursor,opencode,claude]
```

Use this as the single supported installer entrypoint for project setup.

### 2.2 Defaults and behavior

- Default skill selection is `--skills=all`.
- `--skills=core` uses the base profile.
- Supports `--add-skill`, `--remove-skill`, and `--list-skills`.
- Re-running is idempotent; use `--force` for mismatched/broken symlinks.
- Use `--dry-run` to preview changes.

---

## 3. Mandatory summary

Always include:

- Source (GitHub raw and existing project files)
- Downloaded files (docs templates + AGENTS.md + opencode.json)
- Failed downloads (if any)
- `AGENTS.md` status (created, preserved original as `AGENTS-original.md`, skipped)
- `opencode.json` status (created, merged, unchanged)
- Symlinks created/skipped/replaced
- Preserved files
- Gaps and manual follow-up needed

---

## Acceptance criteria (command behavior)

- [ ] With `PROJECT_ROOT/docs` missing, flow downloads templates from GitHub raw URLs using `curl` or `wget` (auto-detected).
- [ ] Directory structure is created before downloads.
- [ ] With `docs/` already present, only missing files are filled without overwriting existing content.
- [ ] GitHub unavailability produces clear manual instructions.
- [ ] Individual file failures do not block full setup.
- [ ] If `AGENTS.md` already exists and is not a Spine template, it is renamed to `AGENTS-original.md` and a new Spine `AGENTS.md` is downloaded.
- [ ] If `AGENTS.md` already exists and is a Spine template (re-run), it is not overwritten.
- [ ] If `AGENTS.md` does not exist, it is downloaded from `templates/AGENTS.md`.
- [ ] Existing `AGENTS-original.md` is never overwritten.
- [ ] `opencode.json` exists in `PROJECT_ROOT` with `$schema`, Spine rule URLs, and `"./AGENTS.md"` in `instructions`.
- [ ] Existing `opencode.json` settings are preserved while Spine URLs are merged without duplicates.
- [ ] Global OpenCode config does not receive Spine-specific instructions.
- [ ] Per-project symlinks are created via `bash .spine/install.sh --project`.
- [ ] Final summary clearly reports setup artifacts and remaining gaps.
