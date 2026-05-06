---
description: "Code quality standards. Applies to all Python files in the project."
globs: "**/*.py"
alwaysApply: false
---

# Code Quality Standards

## Recommended Skills
    - Follow the recommendations in `docs/governance/skills-policy.md`

## Style

- Strict typing by default in functions (parameters and return), with justified exceptions when necessary
- Avoid `Any`, `object`, and `dict` without internal typing; use only when justified
- Prefer short, cohesive functions; refactor when readability is compromised
- No features beyond what was explicitly requested. No speculative generality.
- No error handling for impossible scenarios.
- Self-review before committing: "Would a senior engineer call this overcomplicated?"
- Mandatory docstrings in public functions (Google style)
- Organized imports: stdlib, third-party, local (use isort)
- Descriptive names: `calculate_total_price()` not `calc()`

## Architecture

- Follow what is defined in `docs/memory/global/system-patterns.md` strictly
- Clear layer separation when applicable (`models/`, `schemas/`, `services/`, `api/`)
- Business logic NEVER in routes/endpoints. Always in `services/`
- Database access through the appropriate ORM/layer; repository pattern is optional, based on complexity

## Change Discipline (Surgical Changes)

- Touch only files directly related to the task.
- Do not "improve" adjacent code, comments, or formatting.
- Do not refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- When your changes create orphans (unused imports, dead variables): remove only those YOUR changes made unused. Mention, but do not delete, pre-existing dead code unless asked.
- Every changed line must trace directly to a task requirement.

## Error Handling

- Specific exceptions, never generic `except Exception`
- Clear, actionable error messages
- Structured logging at critical points (API entry, DB failures, external integrations)

## Security

- Never commit secrets, tokens, or passwords
- Use environment variables for sensitive configuration
- Validate ALL external inputs (request bodies, query params, headers)
