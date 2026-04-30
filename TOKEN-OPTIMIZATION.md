# Token Optimization Migration Guide

For agents operating in projects that use the Spine framework.

## What Changed

The system prompt was reduced by ~79% (from ~25KB to ~5.3KB per call).

| Before | After |
|---|---|
| 6 rules in `opencode.json` | 3 rules |
| `AGENTS.md` in system prompt | Eliminated |
| `compaction` not configured | threshold: 16000 |
| Cursor loads 6 rules | Cursor loads 3 rules |

## How to Update This Project

### Step 1: Update the Spine clone

```bash
git -C .spine pull origin master
```

### Step 2: Update `opencode.json`

Replace the contents of `opencode.json` in the project root with:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/01-core-protocol.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/02-memory-bank.md",
    "https://raw.githubusercontent.com/OpsScaleAI/spine/refs/heads/master/rules/04-code-quality.md"
  ],
  "compaction": {
    "enabled": true,
    "strategy": "summarize",
    "threshold": 16000
  }
}
```

### Step 3: Update Cursor (if applicable)

```bash
bash .spine/install.sh --project --update --targets=cursor
```

### Step 4: Remove `AGENTS.md` (optional)

```bash
rm AGENTS.md
```

The project context now lives exclusively in `docs/memory/` (filled by `/spine-bootstrap`).

### Step 5: Restart the session

Close and reopen OpenCode/Cursor for the new system prompt to take effect.

## What Was Removed and Why

| Removed | Reason |
|---|---|
| `03-handoff-protocol.md` | Solo mode is the default; rules already in `01-core-protocol.md`. Available as skill `handoff-protocol`. |
| `05-testing.md` | Covered by `docs/quality/guardrails.md` + skill `test-driven-development`. Available as skill `testing-guidelines`. |
| `06-gitflow.md` | Covered by `docs/workflow/gitflow-operacional.md` + `01-core-protocol.md`. Available as skill `gitflow`. |
| `AGENTS.md` | All content duplicated rules (`01-core-protocol`, `02-memory-bank`, `04-code-quality`) and `docs/memory/`. Single source of truth is now `docs/memory/`. |

## Rules Loaded (3 core)

| Rule | Responsibility |
|---|---|
| `01-core-protocol.md` | Execution cycle, definition of done, commits, guard rails |
| `02-memory-bank.md` | Structure and reading of `docs/memory/` |
| `04-code-quality.md` | Style, architecture, error handling, security |

## Skills Available on Demand

Load with `/skill <name>` when needed:

| Skill | Replaces |
|---|---|
| `gitflow` | Branch structure and promotion flow |
| `testing-guidelines` | Test patterns and quality guardrails |
| `handoff-protocol` | Multi-agent context separation |

## Memory Bank Is Single Source of Truth

Project context (repository layout, build commands, code style, architecture, error handling) lives in `docs/memory/global/` and is read by the agent at session start via `02-memory-bank.md`.

Do NOT recreate an `AGENTS.md` file.
