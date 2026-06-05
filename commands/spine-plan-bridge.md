---
description: Enforce SPINE task and approval flow for native planning modes and conversational changes
agent: build
---

# Slash Command: /spine-plan-bridge
Act as a Workflow Governor for SPINE.

Goal: preserve SPINE execution discipline even when work starts outside `/spine-plan` (for example, Cursor Plan mode, Opencode Plan mode, or direct conversational edits).

## Core Rule
Every meaningful change must be traceable to an active task in `docs/memory/active_tasks/` and pass an approval gate before non-trivial execution.

## 1) Classify the incoming request
Before implementing, classify the request as one of:
- **MICRO_CHANGE**: small conversational adjustment with low risk.
- **STRUCTURED_TASK**: multi-step, risky, or broader-impact delivery.

Use these practical thresholds:
- `MICRO_CHANGE` if all are true:
  - touches at most 2 files,
  - no schema/infrastructure/security/auth changes,
  - no architectural decision required,
  - can be validated with quick local checks.
- Otherwise classify as `STRUCTURED_TASK`.

## 2) Mandatory task artifact for both classes
Always ensure `docs/memory/active_tasks/` exists.
Always create or update:
- `docs/memory/active_tasks/<sequential-number>-<descriptive-name>.md`

The task must include:
- Objective
- Inputs
- Expected outputs
- Acceptance criteria
- Test strategy
- Status (`PLANNING`, `IN_PROGRESS`, `REVIEW`, `DONE`)

## 3) Behavior for MICRO_CHANGE
- Create/update a lightweight active task entry.
- Set status to `PLANNING`.
- Ask for a quick approval gate before execution:
  - "Light task recorded at docs/memory/active_tasks/<id>-<name>.md. Can I execute?"
- After approval, execute and update status flow:
  - `IN_PROGRESS` -> `REVIEW` -> `DONE` (at harvest/closure).

## 4) Behavior for STRUCTURED_TASK
- Build a full plan equivalent to `/spine-plan` (regardless of planning source).
- Apply the same discovery rules as `/spine-plan`: run `@grill-me` when scope is ambiguous, multi-domain, explicitly requested (`grill me`, `grill:`, `grill with docs`, `grill:docs`, `stress-test`, `challenge this`), or when unresolved architectural/security/schema/infra decisions remain. Skip when scope is clear and single-domain, or when the user opts out (`skip discovery`, `no grill`, `direct plan`).
- If the plan came from native Plan mode (Cursor/Opencode), normalize it into the active task file. If open decision branches remain after normalization, run `@grill-me` before finalizing the task artifact.
- When `@grill-me` is active: read memory bank global files (`domain-glossary.md`, `product-context.md`, `system-patterns.md`, `decision-log.md`); promote terms and decisions per the skill. When `grill with docs` or `grill:docs` was requested, expect inline glossary and decision-log updates.
- Record `@grill-me` outcomes under `## Discovery notes` when discovery ran; note any `domain-glossary.md` or `decision-log.md` promotions.
- Include explicit test strategy (positive, negative, regression).
- Stop at approval gate:
  - "Plan created at docs/memory/active_tasks/<id>-<name>.md. Can I execute?"
- Only execute after explicit human approval.

## 5) Native Plan mode bridge requirement
If the user uses host-native planning (not `/spine-plan`), you must still:
- materialize the active task artifact,
- preserve SPINE status lifecycle,
- enforce approval gate before implementation.

Do not skip SPINE governance steps due to host-mode differences.

## 6) Commit gate safeguard
Before committing, verify:
- there is an active task linked to the delivery,
- status is at least `REVIEW`,
- validations listed in task were executed,
- any architectural decision is recorded in `docs/memory/global/decision-log.md` when applicable.

If any item is missing, stop and request completion before commit.

## 7) Anti-overengineering guardrail
Prefer the smallest compliant path:
- keep MICRO_CHANGE lightweight but documented,
- escalate to STRUCTURED_TASK only when thresholds are exceeded.

## 8) Final report format (mandatory)
Always report:
- Classification used (`MICRO_CHANGE` or `STRUCTURED_TASK`)
- Task file path
- Approval checkpoint evidence
- Test evidence summary
- Any decisions logged
