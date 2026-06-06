# AGENTS.md — Spine Agent Operating Guide

This file provides instructions for agentic coding agents working **on the Spine repository** or maintaining the Spine framework.

**Scope:**
- **This file** — operating guide for the Spine repo and framework maintenance.
- **Consumer projects** — use `docs/memory/` plus 3 URL rules in `opencode.json`. Do **not** copy this file into consumer repos.
- **Public setup guide** — [`README.md`](README.md).

Spine is a workflow framework (agent OS) composed primarily of Markdown rules, Bash scripts, and Python test scaffolding.

---

## 1. Repository Layout

```
spine/
├── templates/              # Setup templates seeded by install.sh; filled via /spine-bootstrap
│   ├── opencode.json       # Canonical consumer OpenCode config
│   └── docs/
│       ├── memory/
│       │   ├── global/     # project-brief, product-context, domain-glossary, etc.
│       │   ├── ledger/
│       │   ├── active_tasks/
│       │   └── completed_tasks/
│       ├── governance/     # Skills policy (allowlist, trial criteria)
│       ├── quality/        # Guardrails documentation
│       └── workflow/       # GitFlow and delivery cycle guides
├── docs/                   # Local memory bank for Spine development (NOT versioned)
├── commands/               # Slash-command templates (/spine-plan, /spine-bootstrap, etc.)
├── rules/                  # Source-of-truth rules in .md (Cursor, Claude Code, OpenCode)
├── skills/                 # Curated AI skill definitions (each has a SKILL.md)
├── scripts/                # link-spine.sh, update.sh, install-graphify.sh
├── agents/                 # OpenCode agent definitions (e.g. ask.md)
└── tests/                  # pytest scaffold (conftest.py + unit/ + integration/)
```

**Important:**
- `templates/` contains setup files for new consumer projects (versioned)
- `docs/` is the local memory bank for Spine development (NOT versioned — see `.gitignore`)
- `.gitignore` excludes: `docs/`, `.cursor/`, `CLAUDE.md`, local `opencode.json`
- `AGENTS.md` is versioned in this repository

---

## 2. Build / Lint / Test Commands

Spine has no compiled artifact. Run tests from the Spine repo root:

```bash
pytest tests/
pytest -v tests/
pytest -v -x tests/unit/test_<module>.py::test_<function_name>
pytest --asyncio-mode=auto tests/
```

### Linting and Formatting (expected in consumer projects)

```bash
isort .
black .    # or: ruff format .
mypy src/
```

No `pyproject.toml`, `Makefile`, or `tox.ini` exists at the Spine root; configure these in consumer projects.

---

## 3. Code Style Guidelines

### Language and Encoding
- All code, comments, docstrings, commit messages, and generated file content must be in **English**.
  _(Cursor rule: `.cursor/rules/english.mdc`)_
- Exception: preserve user-provided literals (translations, UI copy) exactly as given.

### Imports
Order enforced by **isort**:
1. Standard library
2. Third-party packages
3. Local application imports

Never mix groups; use a blank line between each group.

### Type Annotations
- **Strict by default**: annotate all function parameters and return types.
- Avoid bare `Any`, `object`, or unparameterized `dict`; justify exceptions in a comment.
- Prefer `dict[str, int]` over `Dict[str, int]` (Python 3.10+ built-in generics).
- Local variables may rely on inference; public API boundaries must be explicit.
- Use Pydantic v2 for external input validation (request bodies, env config, etc.).

### Naming Conventions
- Functions / methods: `snake_case`
- Variables: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Test functions: behavior sentence (e.g., `test_create_task_returns_201_with_valid_data`)

### Docstrings
- Google style, mandatory on all **public** functions, methods, and classes.
- Include `Args:`, `Returns:`, and `Raises:` sections where applicable.

### Formatting
- Prefer short, cohesive functions; one logical concern per function.
- No magic numbers — define named constants.
- Line length: follow configured formatter (black/ruff default = 88).

---

## 4. Architecture Rules

_These rules apply to consumer **application** repositories, not Spine itself (Markdown/Bash/Python scaffold)._

- **Business logic lives exclusively in `services/`**. Routes and endpoints are thin dispatchers only.
- Layer order: `models/` → `schemas/` → `services/` → `api/`
- Repository pattern is optional — apply only when data-access complexity warrants it.
- No new abstraction without at least **two real use cases**.
- Prefer the simplest compliant solution; avoid speculative generality.

---

## 5. Error Handling

_Applies to consumer application code._

- Use **specific exception types** — never `except Exception:` as a bare catch-all.
- Define domain-specific exceptions in a dedicated `exceptions.py` module.
- Raise in the service layer; catch and transform at the API/handler layer.
- Error responses must include: programmatic code, human-readable message, field-level detail when applicable.
- Structured logging at critical boundaries: API entry, DB failures, external calls.

---

## 6. Development vs Consumer Installation

### Development (this repository)

- `docs/` is the local memory bank for Spine development (ignored by git)
- `.cursor/`, `CLAUDE.md`, and root `opencode.json` are local dev configs (ignored by git)
- Version changes in `templates/`, `commands/`, `skills/`, `rules/`, `AGENTS.md`
- Use `docs/memory/` to track Spine's own development progress
- `templates/opencode.json` is the canonical template for consumer projects

### Consumer installation (v1.3 — project-only)

Spine installs **per project only**. There is no global installer (`--global` and `--project` flags were removed in v1.3.0).

**Setup flow:**

```bash
# 1. Clone Spine once on the machine (outside consumer trees)
git clone https://github.com/OpsScaleAI/spine.git ~/Workspace/ide/spine

# 2. From consumer project root — link .spine
bash ~/Workspace/ide/spine/scripts/link-spine.sh

# 3. Full deterministic setup (all skills by default; --core for minimal 5-skill profile)
bash .spine/install.sh
bash .spine/install.sh --core

# 4. In the agent IDE (slash commands exist only after step 3)
/spine-bootstrap  # deep assessment; fill docs/memory/ global + progress (agent-optimized context)
/spine-plan       # first delivery task and plan
```

**Bootstrap vs plan:** `/spine-bootstrap` builds agent context (code + Graphify assessment, alterations, risks, opportunities in `global/`). It does not modify `roadmap.md` or create `active_tasks/`. `/spine-plan` owns delivery planning.

Readiness: `bash .spine/scripts/validate-bootstrap-ready.sh`

After step 2, only `bash .spine/install.sh` works from the terminal — `/spine-*` commands are not available until step 3 creates `.cursor/commands/` and `.opencode/commands/` symlinks.

**Update an existing consumer project:**

```bash
bash .spine/scripts/update.sh
```

#### What `install.sh` creates

| File | Source | Versioned in consumer project? |
|---|---|---|
| `docs/` (memory bank templates) | `templates/docs/` via `.spine` | Yes |
| `opencode.json` | `templates/opencode.json` (create or merge) | Yes |
| `.spine`, `.agents/`, etc. | Symlinks via `install.sh` | No (machine-specific) |

#### Consumer project structure

```
PROJECT_ROOT/
├── .spine                  → Spine repository (symlink)
├── .agents/skills/         per-skill symlinks hub
├── .cursor/rules/          core rule symlinks
├── .cursor/commands/       → .spine/commands/
├── .cursor/skills/         → .agents/skills/
├── .opencode/commands/     → .spine/commands/
├── .opencode/agents/       per-file symlinks to .spine/agents/ (project-only; not ~/.config/opencode/agents/)
├── .claude/skills/         → .agents/skills/
├── opencode.json           (3 rule URLs + compaction)
├── docs/memory/...         (memory bank)
└── .graphifyignore         (optional — Graphify)
```

**Skill management:**

```bash
bash .spine/install.sh --list-skills
bash .spine/install.sh --add-skill=grill-me
bash .spine/install.sh --remove-skill=astro
bash .spine/install.sh --skills=python-patterns,fastapi-pro
bash .spine/install.sh --skills=all             # explicit all (default)
bash .spine/install.sh --skills=core            # minimal 5-skill profile
bash .spine/install.sh --update
bash .spine/install.sh --uninstall
bash .spine/install.sh --targets=cursor,opencode,claude
bash .spine/install.sh --with-graphify --graphify-init
```

**Core skills** (the `--core` profile):

- `writing-plans`
- `executing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`

**Trial skill (opt-in):** `grill-me` — conditional discovery before `/spine-plan`; sharpens domain language and promotes terms to `domain-glossary.md`. Install with `--add-skill=grill-me`.

### Memory Bank v2.1 (consumer)

Operational source of truth: `docs/memory/`. Canonical spec: `rules/02-memory-bank.md`. Tags: `docs/governance/memory-tags-policy.md`.

```
docs/memory/
  global/           # Stable base
  ledger/
    roadmap.md
    progress.md     # Current state + delivery log (append-only)
    learnings.md    # LEARN-NNN recurrence registry
  active_tasks/     # Open work only
  completed_tasks/  # DONE (git mv at harvest)
```

**Task files:** Obsidian-style YAML frontmatter (`task_id`, `title`, `goal`, `status`, `tags`, `branch`, `base`, `created_at`, `updated_at`, …). Template: `templates/docs/memory/active_tasks/_task-template.md`.

**Tiered SYNC:**

| Tier | When | Read |
|------|------|------|
| Core | Every session | global 1–6, progress Current state, open `active_tasks/` |
| Extended | Plan, harvest, ambiguous scope | `roadmap.md`, full delivery log |
| On demand | Debugging, recurrence | `learnings.md`, `completed_tasks/` |

**Harvest outcomes:** delivery log append, `learnings.md` when applicable, frontmatter `status: DONE`, `git mv` to `completed_tasks/`.

### OpenCode configuration (consumer)

Canonical template: `templates/opencode.json`

- **3 instructions** (URL-based, opt-in per project):
  - `01-core-protocol.md`
  - `02-memory-bank.md`
  - `03-code-quality.md`
- **model** / **small_model** — default LLM (`provider/model-id` format)
- **default_agent:** `ask` (read-only exploration first; switch to `build` for implementation)
- **agent.ask** — read-only primary; default model variant (no override); `prompt: "{file:.spine/agents/ask.md}"`; deny `edit`
- **agent.plan** / **agent.build** — `variant: medium` for balanced reasoning cost
- **compaction:** `enabled: true`, `strategy: summarize`, `threshold: 16000`
- **Never** add Spine `instructions` to global `~/.config/opencode/opencode.json`
- Pin to `refs/heads/master` for latest, or `refs/tags/vX.Y.Z` for stability
- Customize `model` / `variant` per [OpenCode models](https://opencode.ai/docs/models/) (`opencode models` CLI)

### Optional tooling

**Graphify** (retrieval optimization — optional):

- Install CLI: `uv tool install graphifyy`
- Enable in project: `bash .spine/install.sh --with-graphify --graphify-init` or `bash .spine/scripts/update.sh --graphify-init`
- Verify: `test -f graphify-out/graph.json`
- Refresh: `graphify update .`
- Full guide: README § **Optional: Graphify**

When `graphify-out/graph.json` exists, agents query the graph first (see `01-core-protocol.md`, `02-memory-bank.md`). Memory bank remains mandatory.

### Slash commands

Available in `commands/`:

- `install.sh` — deterministic setup: symlinks, `docs/` seed, `opencode.json`, Graphify opt-in
- `/spine-update` — safe refresh via `scripts/update.sh`
- `/spine-bootstrap` — initial assessment and memory bank fill
- `/spine-plan` — task plan in memory bank (native Plan draft as input; conditional `@grill-me` discovery)
- `/spine-execute` — implement active task with validation
- `/spine-harvest` — consolidate learnings and close task
- `/spine-commit` — commit with branch safety checks
- `/spine-promote` — GitFlow branch promotion

### Gitignore in consumer projects

**Versioned:** `opencode.json`, `docs/`, `.graphifyignore`

**Machine-specific (gitignored):** `.spine`, `.agents/`, `.cursor/`, `.claude/`, `.opencode/`, `graphify-out/` (recommended)

**Non-Spine projects** omit Spine URLs from `opencode.json` and do not run the install script. They remain free of Spine rules.
