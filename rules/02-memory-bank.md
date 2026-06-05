---
description: "Defines structure and practical use of the Memory Bank as the operational source of truth."
globs: 
alwaysApply: true
---

# MEMORY BANK V2.0 - State API

The `docs/memory/` directory is the **operational source of truth**.
The memory bank remains mandatory even when Graphify is available.

## Estrutura

```
docs/memory/
  global/                    # Stable base (changes with explicit justification)
    project-brief.md         # Scope, goals, project boundaries
    product-context.md       # Why the project exists, problems it solves, UX goals
    domain-glossary.md       # Ubiquitous language: canonical domain terms (language only)
    system-patterns.md       # Stack, architecture, design patterns, dependencies
    tech-context.md          # Dev setup, technical constraints, infra
    decision-log.md          # Record of architectural decisions with WHY
  ledger/                    # Current state (updated on each task)
    roadmap.md               # Prioritized backlog and milestones
    progress.md              # Current status: what works, what is missing, known issues
  active_tasks/              # Task execution
    <sequential-number>-<descriptive-name>.md
```

## Access Rules (pragmatic)

| Layer | Author | When it changes |
|---|---|---|
| `global/` | Human or agent with explicit approval | Scope/architecture changes |
| `ledger/` | Executing agent | Every delivery cycle |
| `active_tasks/` | Executing agent | Created in PLAN and updated until DONE |

## Reading Rules (SYNC)

At the start of EVERY session or task, read in this order:

1. `global/project-brief.md` (scope)
2. `global/product-context.md` (product context)
3. `global/domain-glossary.md` (domain language — create lazily during `@grill-me` or `@spine-bootstrap` if missing)
4. `global/system-patterns.md` (how to build)
5. `global/tech-context.md` (constraints)
6. `global/decision-log.md` (previous decisions)
7. `ledger/roadmap.md` (direction)
8. `ledger/progress.md` (where we are)
9. `active_tasks/` (what is in progress)

If `graphify-out/graph.json` exists, it can be used as an auxiliary discovery layer (graph-first exploration), but it does not replace reading and maintaining the memory bank.

If a file does not exist, create it only if it is part of the current task flow.

After SYNC, before any code change, state:
- Key assumptions about the task derived from the memory bank.
- Any ambiguities, gaps, or conflicts found in the context.
- The simplest approach that satisfies the requirements.

## Template: active_tasks/<sequential-number>-<descriptive-name>.md

```markdown
# <sequential-number>-<descriptive-name>

## Objective
[What must be done]

## Inputs
- [Input files/data]

## Expected Outputs
- [Files/artifacts that must be generated]

## Acceptance Criteria (verifiable, TDD-ready)
- [ ] [Criterion 1]
  - Test: [specific test that proves this criterion]
- [ ] [Criterion 2]
  - Test: [specific test that proves this criterion]

## Status: [PLANNING | IN_PROGRESS | REVIEW | DONE]
```