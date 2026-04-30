---
description: Update an already-installed Spine consumer project while preserving memory docs
agent: build
---

# Slash Command: /spine-update
Act as the project's Update Operator.

Goal: update an existing Spine-enabled consumer project safely, preserving `docs/memory/`.

---

## 1. Preconditions

- Project must be a git repository.
- `.spine` symlink must exist in the project root.
- If `.spine` is missing, stop and ask the user to run `/spine-install` first.

---

## 2. Default update flow

Run from project root:

```bash
bash .spine/scripts/update.sh
```

This performs:
1. update Spine source via `.spine` (`git pull`);
2. reconcile project symlinks (`install.sh --project --update --force`);
3. sync `opencode.json` with current Spine template (merge mode);
4. preserve `docs/memory/` (non-destructive).

---

## 3. Optional modes

- Dry run:

```bash
bash .spine/scripts/update.sh --dry-run
```

- Skip `.spine` pull:

```bash
bash .spine/scripts/update.sh --no-pull
```

- Replace `opencode.json` (instead of merge):

```bash
bash .spine/scripts/update.sh --replace-opencode
```

- Include Graphify setup:

```bash
bash .spine/scripts/update.sh --with-graphify
```

- Include Graphify setup + initial graph build:

```bash
bash .spine/scripts/update.sh --graphify-init
```

---

## 4. Mandatory summary

Always report:

- Whether `.spine` pull was executed or skipped.
- Symlink reconciliation result.
- `opencode.json` mode used (merge or replace).
- Confirmation that `docs/memory/` was preserved.
- Any blockers and exact command to recover.

---

## Acceptance criteria (command behavior)

- [ ] Fails fast with clear message if project is not Spine-enabled (`.spine` missing).
- [ ] Uses `scripts/update.sh` as the single update entrypoint.
- [ ] Preserves `docs/memory/` and does not wipe project memory.
- [ ] Supports dry-run and replacement modes for `opencode.json`.
- [ ] Produces a clear operational summary for the user.
