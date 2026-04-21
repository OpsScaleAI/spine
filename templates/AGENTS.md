# AGENTS.md

This file provides instructions for agentic coding agents operating in this project.
It is governed by the Spine framework and consumed as an instruction source by OpenCode.

---

## 1. Repository Layout

<!-- TODO: /spine-bootstrap will fill this section with the project directory structure -->

---

## 2. Build / Lint / Test Commands

<!-- TODO: /spine-bootstrap will fill this section with project-specific commands -->

---

## 3. Code Style Guidelines

<!-- TODO: /spine-bootstrap will fill this section based on the project stack -->

---

## 4. Architecture Rules

<!-- TODO: /spine-bootstrap will fill this section based on the project architecture -->

---

## 5. Error Handling

<!-- TODO: /spine-bootstrap will fill this section based on the project patterns -->

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

1. **Sync** — read memory bank (section 6).
2. **Plan** — create `docs/memory/active_tasks/<seq>-<name>.md` with scope, acceptance criteria, and branch suggestion (`Branch: feature/<name>`, `Base: develop`). Do not create the branch during planning.
3. **Branch** — at execution time, create or switch to the branch specified in the task file, based on the `Base` field.
4. **Test** — write the failing test first (TDD: Red -> Green -> Refactor).
5. **Execute** — implement atomically; keep commits small and focused.
6. **Harvest** — update `docs/memory/ledger/progress.md` and `docs/memory/global/decision-log.md` when an architectural decision was made.

---

## 8. Git / Commit Rules

- Conventional Commits: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- Each commit = one complete, testable logical change.
- **Never** `git push --force`.
- **Never** commit directly to `main`, `production`, `staging`, or `develop`.
- Every merge to `develop` requires a Pull Request.

---

## 9. Security

- Never commit secrets, tokens, or passwords.
- All sensitive config via environment variables.
- Validate **all** external inputs (request bodies, query params, headers).