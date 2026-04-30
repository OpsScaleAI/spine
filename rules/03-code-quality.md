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
- Mandatory docstrings in public functions (Google style)
- Organized imports: stdlib, third-party, local (use isort)
- Descriptive names: `calculate_total_price()` not `calc()`

## Architecture

- Follow what is defined in `docs/memory/global/system-patterns.md` strictly
- Clear layer separation when applicable (`models/`, `schemas/`, `services/`, `api/`)
- Business logic NEVER in routes/endpoints. Always in `services/`
- Database access through the appropriate ORM/layer; repository pattern is optional, based on complexity

## Error Handling

- Specific exceptions, never generic `except Exception`
- Clear, actionable error messages
- Structured logging at critical points (API entry, DB failures, external integrations)

## Security

- Never commit secrets, tokens, or passwords
- Use environment variables for sensitive configuration
- Validate ALL external inputs (request bodies, query params, headers)
