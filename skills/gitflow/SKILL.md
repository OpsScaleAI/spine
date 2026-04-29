---
name: gitflow
description: "Reference for Git branching strategy — branch structure, naming, and promotion flow"
risk: low
source: spine
date_added: "2026-04-29"
---

# GitFlow Reference

## When to Use
- When creating or managing branches
- When promoting code through staging/production
- When unsure about branch naming or merge strategy

## Branch Structure

| Branch | Purpose | Origin | Merges to |
|---|---|---|---|
| `production` | Live code | `staging` | — |
| `main` | Canonical branch; stable mirror of `production` | `production` | — |
| `staging` | QA and pre-production | `develop` | `production` |
| `develop` | Integration branch | `main`/`production` | `staging` |
| `feature/*` | New features | `develop` | `develop` |
| `hotfix/*` | Urgent fixes | `production` | `production`, `main`, `develop` |

## Rules
1. Every change starts with: `git checkout develop && git pull && git checkout -b feature/<name>`
2. Atomic commits — one logical change per commit
3. Never push directly to `production`, `main`, `staging`, or `develop`
4. Never `git push --force`
5. Merge to `develop` requires a Pull Request (or solo validation)
6. Memory bank must be updated when promoting `develop` to `staging`

## Naming
- Features: `feature/<descriptive-name>` (e.g., `feature/social-login`)
- Hotfixes: `hotfix/<descriptive-name>` (e.g., `hotfix/fix-null-pointer`)
- Releases: `release/vX.Y.Z`

## Promotion Flow
`feature/*` → `develop` → `staging` → `production` → `main`

## Reference
Full operational guide: `docs/workflow/gitflow-operacional.md`
