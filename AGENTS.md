# AGENTS.md — Spine Agent Operating Guide

This file provides instructions for agentic coding agents operating in this repository.
Spine is a workflow framework (agent OS) that governs AI-assisted development cycles.
It is composed primarily of Markdown rules, Bash scripts, and Python test scaffolding.

---

## 1. Repository Layout

```
spine/
├── templates/ # Setup templates for spine-bootstrap
│   └── docs/
│       ├── memory/ # Empty memory bank templates
│       │   ├── global/
│       │   ├── ledger/
│       │   └── active_tasks/
│       ├── governance/ # Skills policy (allowlist, trial criteria)
│       ├── quality/ # Guardrails documentation
│       └── workflow/ # GitFlow and delivery cycle guides
├── docs/ # Local memory bank (NOT versioned - see .gitignore)
│   ├── memory/ # Source-of-truth for Spine development
│   ├── governance/ # (symlink to templates/ - optional)
│   ├── quality/ # (symlink to templates/ - optional)
│   └── workflow/ # (symlink to templates/ - optional)
├── commands/ # Slash-command templates (/spine-bootstrap, /spine-plan, etc.)
├── rules/ # Source-of-truth rules in .md (consumed by Cursor, Claude Code, OpenCode)
├── skills/ # 30+ curated AI skill definitions (each has a SKILL.md)
└── tests/ # pytest scaffold (conftest.py + unit/ + integration/)
```

**Important:** 
- `templates/` contains setup files for new projects (versioned)
- `docs/` is the local memory bank for Spine development (NOT versioned)
- `.gitignore` excludes: `docs/`, `.cursor/`, `AGENTS.md`, `CLAUDE.md`

---

## 2. Build / Lint / Test Commands

Spine has no compiled artifact.

### Global Installation

```bash
# Install Spine globally (symlinks to Cursor, OpenCode, Claude Code)
bash install.sh
# With --force to replace existing directories (creates .spine-backup)
bash install.sh --force
# Preview without making changes
bash install.sh --dry-run
```

### Running Tests (pytest)

```bash
# Full test suite
pytest tests/

# All tests with verbose output
pytest -v tests/

# Single test file
pytest tests/unit/test_<module>.py

# Single test by node ID (preferred for TDD cycles)
pytest tests/unit/test_<module>.py::test_<function_name>

# Single test — verbose + stop on first failure
pytest -v -x tests/unit/test_<module>.py::test_<function_name>

# Async tests (pytest-asyncio)
pytest --asyncio-mode=auto tests/
```

### Linting and Formatting (expected in consumer projects)

```bash
# Sort imports
isort .

# Format code (black or ruff — configure at consumer project level)
black .
# or
ruff format .

# Type checking
mypy src/
```

No `pyproject.toml`, `Makefile`, or `tox.ini` exists at the Spine root; these are
configured in the consumer projects that symlink or vendor Spine.

---

## 3. Code Style Guidelines

### Language and Encoding
- All code, comments, docstrings, commit messages, and generated file content must be in **English**.
  _(Cursor rule: `.cursor/rules/english.md`)_
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
| Element | Convention | Example |
|---|---|---|
| Functions / methods | `snake_case`, descriptive | `calculate_total_price()` |
| Variables | `snake_case` | `order_items` |
| Classes | `PascalCase` | `OrderService` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_RETRY_COUNT` |
| Test functions | behavior sentence | `test_create_task_returns_201_with_valid_data` |
| Feature branches | `feature/<descriptive-name>` | `feature/social-login` |
| Hotfix branches | `hotfix/<descriptive-name>` | `hotfix/fix-null-pointer-auth` |
| Active task files | `<seq>-<descriptive-name>.md` | `007-social-login-adjustment.md` |

Avoid abbreviations: `calculate_total` not `calc_tot`.

### Docstrings
- Google style, mandatory on all **public** functions, methods, and classes.
- Include `Args:`, `Returns:`, and `Raises:` sections where applicable.

```python
def create_order(user_id: int, items: list[OrderItem]) -> Order:
    """Create a new order for the given user.

    Args:
        user_id: The ID of the user placing the order.
        items: Line items to include in the order.

    Returns:
        The persisted Order instance.

    Raises:
        UserNotFoundError: If no user matches `user_id`.
    """
```

### Formatting
- Prefer **short, cohesive functions**; refactor when readability is impaired.
- One logical concern per function.
- No magic numbers — define named constants.
- Line length: follow configured formatter (black default = 88, ruff default = 88).

---

## 4. Architecture Rules

- **Business logic lives exclusively in `services/`**. Routes and endpoints are thin
  dispatchers only.
- Layer order: `models/` → `schemas/` → `services/` → `api/`
- Repository pattern is optional — apply only when data-access complexity warrants it.
- No new abstraction without at least **two real use cases**.
- Prefer the simplest compliant solution; avoid speculative generality.

---

## 5. Error Handling

- Use **specific exception types** — never `except Exception:` as a bare catch-all.
- Define domain-specific exceptions in a dedicated `exceptions.py` module.
- Raise in the service layer; catch and transform at the API/handler layer.
- Error responses must include: programmatic code, human-readable message, field-level
  detail when applicable. Never expose stack traces to clients.
- Structured logging at critical boundaries: API entry, DB failures, external calls.

```python
# Good
except UserNotFoundError as exc:
    raise HTTPException(status_code=404, detail=str(exc)) from exc

# Bad
except Exception:
    pass
```

---

## 6. Memory Bank (mandatory read at session start)

**Note:** For Spine development, use `docs/memory/` (local). For consumer projects, the memory bank is created by `/spine-bootstrap` from `templates/docs/`.

Read in this order at the start of every session or task:

1. `docs/memory/global/project-brief.md`
2. `docs/memory/global/product-context.md`
3. `docs/memory/global/system-patterns.md`
4. `docs/memory/global/tech-context.md`
5. `docs/memory/global/decision-log.md`
6. `docs/memory/ledger/roadmap.md`
7. `docs/memory/ledger/progress.md`
8. `docs/memory/active_tasks/` (any in-progress task files)

---

## 7. Task Execution Protocol

Every non-trivial change must follow this cycle:

1. **Sync** — read memory bank (§6).
2. **Plan** — create `docs/memory/active_tasks/<seq>-<name>.md` with scope, acceptance criteria, and branch suggestion (`Branch: feature/<name>`, `Base: develop`). Do not create the branch during planning.
3. **Branch** — at execution time, create or switch to the branch specified in the task file, based on the `Base` field.
4. **Test** — write the failing test first (TDD: Red → Green → Refactor).
5. **Execute** — implement atomically; keep commits small and focused.
6. **Harvest** — update `docs/memory/ledger/progress.md` and `docs/memory/global/decision-log.md` when an architectural decision was made.

### Test Rules
- Every public function needs at least one success test and one failure test.
- Tests live in `tests/unit/` (no I/O) or `tests/integration/` (DB, external APIs).
- Use pytest fixtures for setup/teardown; define shared fixtures in `conftest.py`.
- Prefer one assertion per test.
- Names must embed expected behavior: `test_<action>_<expected_result>`.

---

## 8. Git / Commit Rules

- Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Each commit = one complete, testable logical change.
- **Never** `git push --force`.
- **Never** commit directly to `main`, `production`, `staging`, or `develop`.
- Every merge to `develop` requires a Pull Request.
- Update memory bank when `develop` is promoted to `staging`.

---

## 9. Security

- Never commit secrets, tokens, or passwords.
- All sensitive config via environment variables.
- Validate **all** external inputs (request bodies, query params, headers) — use Pydantic.

---

## 10. Development vs Installation

### Development (this repository)
- `docs/` is the local memory bank for Spine development (ignored by git)
- `.cursor/`, `AGENTS.md`, `CLAUDE.md`, `opencode.json` are local development configs (ignored by git)
- Changes to `templates/`, `commands/`, `skills/`, `rules/` should be versioned
- Use `docs/memory/` to track Spine's own development progress
- `templates/AGENTS.md` and `templates/opencode.json` are the canonical templates for consumer projects

### Installation — Global (one-time)

Run `bash install.sh` to create global symlinks for OpenCode, Cursor, and Claude Code:

```bash
bash install.sh            # conservative, never overwrites
bash install.sh --force    # replaces existing dirs (creates .spine-backup)
bash install.sh --dry-run  # preview without changes
```

This makes skills and commands available in **all** projects via `/skill` and `/command`, but does **not** inject Spine rules into any project.

**Important:** The global `~/.config/opencode/opencode.json` must NOT contain Spine `instructions`. Rules are opt-in per project (see below).

### Installation — Per Project (opt-in)

Each project that follows the Spine framework must explicitly opt in. This involves two commands:

1. `/spine-install` — downloads templates, creates `AGENTS.md`, `opencode.json`, and runs `install.sh --project`
2. `/spine-bootstrap` — assesses the project and fills the memory bank and `AGENTS.md` with project-specific context

#### What `/spine-install` creates

| File | Source | Versioned in consumer project? |
|---|---|---|
| `docs/` (memory bank) | GitHub `templates/docs/` | Yes |
| `AGENTS.md` | GitHub `templates/AGENTS.md` | Yes |
| `opencode.json` | GitHub `templates/opencode.json` | Yes |
| `.spine`, `.agents/`, etc. | Symlinks via `install.sh --project` | No (machine-specific) |
| `AGENTS-original.md` | Renamed from existing `AGENTS.md` (if any) | No (gitignored) |

If the project already has an `AGENTS.md`, it is renamed to `AGENTS-original.md` (preserved as reference) and a new Spine `AGENTS.md` is downloaded.

#### What `/spine-bootstrap` fills

- `docs/memory/` files with project context from assessment
- `AGENTS.md` placeholder sections (Repository Layout, Build Commands, Code Style, Architecture, Error Handling)
- Content from `AGENTS-original.md` (if it exists) is merged into the new `AGENTS.md`

#### Per-project symlinks (`install.sh --project`)

```bash
# From the project root (after creating .spine symlink)
ln -s /path/to/spine .spine
bash .spine/install.sh --project

# Or specify skill selection
bash .spine/install.sh --project --skills=python-patterns,fastapi-pro

# Preview without changes
bash .spine/install.sh --project --dry-run
```

This creates the following structure:

```
PROJECT_ROOT/
├── .spine                  → /path/to/spine         (symlink to repo)
├── .agents/
│   └── skills/                                  (per-skill symlinks hub)
│       ├── python-patterns  → ../../.spine/skills/python-patterns
│       └── fastapi-pro      → ../../.spine/skills/fastapi-pro
├── .claude/
│   └── skills              → ../.agents/skills/    (Claude Code native path)
├── .cursor/
│   ├── rules/                                   (per-file rule symlinks)
│   │   └── 01-core-protocol.md → ../../.spine/rules/01-core-protocol.md
│   ├── commands             → ../.spine/commands/
│   └── skills               → ../.agents/skills/
├── .opencode/
│   └── commands             → ../.spine/commands/
├── opencode.json                                 (GitHub URLs for rules)
├── AGENTS.md                                     (project-level instructions)
├── docs/memory/...                               (memory bank)
└── .gitignore                                    (spine entries: .spine, .agents/, etc.)
```

**Why `.agents/skills/` as the hub?**
- OpenCode discovers skills from `.agents/skills/<name>/SKILL.md` natively
- Claude Code discovers skills from `.claude/skills/<name>/SKILL.md` natively
- Cursor picks up skills via `.cursor/skills → .agents/skills/` symlink
- One symlink per skill in `.agents/skills/`, then each tool points to this hub

**Why per-skill symlinks instead of directory-level?**
- Projects only see the skills they need (isolated per project)
- Adding a new skill to the Spine repo doesn't automatically propagate to all projects
- Follows the `docs/governance/skills-policy.md` allowlist (core skills + project-specific)

**Skill management commands:**
```bash
bash .spine/install.sh --project --list-skills          # Show available/installed
bash .spine/install.sh --project --add-skill=astro       # Add one skill
bash .spine/install.sh --project --remove-skill=astro    # Remove one skill
bash .spine/install.sh --project --skills=all             # Install all skills
bash .spine/install.sh --project --targets=opencode      # Only OpenCode tooling
```

**Core skills** (installed by default with `--project`):
- `writing-plans`
- `executing-plans`
- `test-driven-development`
- `systematic-debugging`
- `verification-before-completion`

### Gitignore in consumer projects

Files versioned in the consumer project (committed to git):
- `AGENTS.md` — project-level agent instructions
- `opencode.json` — project-level OpenCode configuration
- `docs/` — memory bank and governance docs

Files gitignored in the consumer project (machine-specific):
- `.spine` — symlink to Spine repository
- `.agents/`, `.cursor/`, `.claude/`, `.opencode/` — symlinks
- `AGENTS-original.md` — preserved reference, not versioned

**Non-Spine projects** (e.g., LLM Wiki, experiments, third-party repos) simply don't include Spine URLs in their `opencode.json` and don't run the install script. They remain completely free of Spine rules while still having access to the global skills and commands catalog.

### Consumer projects
- Memory bank created at `$PROJECT_ROOT/docs/` by `/spine-install`
- `/spine-bootstrap` assesses the project and fills `AGENTS.md` and memory bank
- Consumer projects maintain their own memory bank independently
- `opencode.json` and `AGENTS.md` in the project root are versioned and committed
- Symlinks (`.spine`, `.agents/`, `.cursor/`, `.claude/`, `.opencode/`) are machine-specific and gitignored
