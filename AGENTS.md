# AGENTS.md — Spine Agent Operating Guide

This file provides instructions for agentic coding agents operating in this repository.
Spine is a workflow framework (agent OS) that governs AI-assisted development cycles.
It is composed primarily of Markdown rules, Bash scripts, and Python test scaffolding.

---

## 1. Repository Layout

```
spine/
├── commands/          # Slash-command templates (/spine-bootstrap, /spine-plan, etc.)
├── docs/
│   ├── governance/    # Skills policy (allowlist, trial criteria)
│   ├── memory/        # Source-of-truth memory bank (see §6)
│   │   ├── global/    # Stable project facts — change with explicit justification only
│   │   ├── ledger/    # Living state — updated on every delivery cycle
│   │   └── active_tasks/  # Per-task execution contracts
│   ├── quality/       # Guardrails documentation
│   └── workflow/      # GitFlow and delivery cycle guides
├── oc_rules/          # Symlinks to rules/*.mdc (renamed .md) consumed by OpenCode
├── rules/             # Source-of-truth rules in .mdc (consumed by Cursor)
├── scripts/           # Maintenance utilities (sync_oc_rules.sh)
├── skills/            # 30+ curated AI skill definitions (each has a SKILL.md)
└── tests/             # pytest scaffold (conftest.py + unit/ + integration/)
```

---

## 2. Build / Lint / Test Commands

Spine has no compiled artifact. The only maintenance script is:

```bash
# Rebuild oc_rules/ symlinks from rules/*.mdc
bash scripts/sync_oc_rules.sh
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
2. **Branch** — `git checkout develop && git pull && git checkout -b feature/<name>`.
3. **Plan** — create `docs/memory/active_tasks/<seq>-<name>.md` with scope and
   acceptance criteria.
4. **Test** — write the failing test first (TDD: Red → Green → Refactor).
5. **Execute** — implement atomically; keep commits small and focused.
6. **Harvest** — update `docs/memory/ledger/progress.md` and
   `docs/memory/global/decision-log.md` when an architectural decision was made.

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
