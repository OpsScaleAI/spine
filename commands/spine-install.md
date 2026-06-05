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
   - Memory Bank global files (project-brief, product-context, domain-glossary, system-patterns, tech-context, decision-log)
   - Memory Bank ledger files (roadmap, progress)
   - Governance and workflow docs (skills-policy, guardrails, gitflow-operacional, ciclo-de-entrega)
4. Create empty `.gitkeep` in `docs/memory/active_tasks/`.
5. Download command: prefer `curl -fsSL <URL> -o <path>`, fallback to `wget -q <URL> -O <path>`.

### 0.4 Files to download

Base URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/`

Paths:
- `templates/docs/memory/global/project-brief.md`
- `templates/docs/memory/global/product-context.md`
- `templates/docs/memory/global/domain-glossary.md`
- `templates/docs/memory/global/system-patterns.md`
- `templates/docs/memory/global/tech-context.md`
- `templates/docs/memory/global/decision-log.md`
- `templates/docs/memory/ledger/roadmap.md`
- `templates/docs/memory/ledger/progress.md`
- `templates/docs/governance/skills-policy.md`
- `templates/docs/quality/guardrails.md`
- `templates/docs/workflow/gitflow-operacional.md`
- `templates/docs/workflow/ciclo-de-entrega.md`

### 0.5 opencode.json handling (template download)

After downloading `docs/` templates, handle the project-level `opencode.json`:

1. Check if `PROJECT_ROOT/opencode.json` already exists.
2. If it exists:
   - Parse it as JSON.
   - If `"instructions"` key is present, preserve it but ensure it includes all Spine rule URLs. Avoid duplicates.
   - Merge other keys from the existing file; do not remove user-defined settings.
3. If it does not exist:
   - Download `templates/opencode.json` from GitHub to `PROJECT_ROOT/opencode.json`.
   - This provides the minimal template with `$schema` and Spine rule instructions only.

Source URL: `https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/templates/opencode.json`

### 0.6 Optional Graphify onboarding (consumer projects)

Graphify is an optional enhancement for consumer projects that need lower context/token cost during exploration.

- Do not make Graphify mandatory for setup completion.
- Keep Spine core instruction loading unchanged (3 core rules via `instructions`).
- Full guide: Spine repository README, section **Optional: Graphify**.

**New project onboarding:**

1. Install Graphify globally on the developer machine (`uv tool install graphifyy` recommended; alternatives: `pipx install graphifyy`, `pip install graphifyy`).
2. Run project setup with Graphify opt-in: `bash .spine/install.sh --with-graphify --graphify-init`.
3. Verify: `test -f graphify-out/graph.json && echo "Graphify active"`.

**Existing project already using Spine** (`.spine` and `docs/memory/` already present):

- Do not re-run full template download for Graphify alone.
- Suggest: `bash .spine/install.sh --with-graphify --graphify-init` from the project root.
- Alternative: `bash .spine/scripts/update.sh --graphify-init` (pulls Spine and enables Graphify in one step).
- Manual fallback on old Spine clones: `bash .spine/scripts/install-graphify.sh --project-root=. --init-graph`.
- After setup, verify `graphify-out/graph.json` exists. Refresh when stale: `graphify update .`.

- Preserve user-owned `opencode.json` keys when merging setup changes.

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
- `03-code-quality.md`

### 1.2 Principles

- Opt-in per project only; do not add Spine instructions to global `~/.config/opencode/opencode.json`.
- Do not symlink Spine agents into global `~/.config/opencode/agents/`; `install.sh` deploys them to project `.opencode/agents/` only.
- Remote URLs provide portability and auto-update behavior.
- Version pinning is supported by replacing `refs/heads/master` with a tag.
- `$schema`, `model`, `permission`, `command`, and `compaction` settings are project-specific and should be configured by the user in `opencode.json` after setup.

---

## 2. Link Spine repository and install symlinks

### 2.0 Link `.spine` (prerequisite)

Before running the installer, create the `.spine` symlink in the project root:

```bash
bash <PATH_TO_SPINE_REPO>/scripts/link-spine.sh
```

Run from `PROJECT_ROOT`, or pass `--project-root=PATH` and optionally `--spine-dir=PATH`.

If `.spine` already exists but points elsewhere, use `--force` to replace.

### 2.1 Install command

```bash
bash .spine/install.sh [--core] [--skills=all|core|a,b,c] [--targets=cursor,opencode,claude]
```

Use this as the single supported installer entrypoint for project setup.

### 2.2 Defaults and behavior

- Default skill selection is **all** skills in the Spine catalog.
- `--core` or `--skills=core` installs the minimal 5-skill base profile only.
- Supports `--add-skill`, `--remove-skill`, and `--list-skills`.
- Deploys OpenCode agents from `agents/` to project `.opencode/agents/` only (per-file symlinks; e.g. `ask.md` for read-only exploration). Warns if legacy global `~/.config/opencode/agents/` Spine symlinks exist.
- Re-running is idempotent; use `--force` for mismatched/broken symlinks.
- Use `--dry-run` to preview changes.

---

## 3. Mandatory summary

Always include:

- Source (GitHub raw and existing project files)
- Downloaded files (docs templates + opencode.json)
- Failed downloads (if any)
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
- [ ] `opencode.json` exists in `PROJECT_ROOT` with `$schema` and Spine rule URLs in `instructions`.
- [ ] Existing `opencode.json` settings are preserved while Spine URLs are merged without duplicates.
- [ ] Global OpenCode config does not receive Spine-specific instructions.
- [ ] `.spine` symlink is created via `scripts/link-spine.sh` (or already present).
- [ ] Per-project symlinks are created via `bash .spine/install.sh`.
- [ ] Final summary clearly reports setup artifacts and remaining gaps.
