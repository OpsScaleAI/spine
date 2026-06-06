#!/usr/bin/env bash
set -uo pipefail

# Validate consumer project readiness for /spine-bootstrap (setup artifacts only).
#
# Usage (from project root):
#   bash .spine/scripts/validate-bootstrap-ready.sh
#   bash .spine/scripts/validate-bootstrap-ready.sh --dry-run

DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: bash .spine/scripts/validate-bootstrap-ready.sh [--dry-run]"
            echo "Checks install.sh seed artifacts and Spine symlinks before bootstrap."
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

if $DRY_RUN; then
    echo "[DRY-RUN] Would validate bootstrap readiness from: $(pwd)"
fi

errors=0
fail() { echo "ERROR: $*" >&2; errors=$((errors + 1)); }

# --- Spine link ---
if [[ ! -e .spine ]]; then
    fail "missing .spine (run link-spine.sh then bash .spine/install.sh)"
fi

if [[ ! -f .spine/scripts/validate-task.sh ]]; then
    fail "missing .spine/scripts/validate-task.sh (run bash .spine/scripts/update.sh)"
fi

# --- Slash commands ---
if [[ ! -f .cursor/commands/spine-bootstrap.md ]] && [[ ! -f .opencode/commands/spine-bootstrap.md ]]; then
    fail "spine-bootstrap slash command not found (.cursor/commands/ or .opencode/commands/)"
fi

# --- opencode.json ---
if [[ ! -f opencode.json ]]; then
    fail "missing opencode.json (run bash .spine/install.sh)"
fi

# --- docs/ seed paths (must match install.sh get_docs_seed_paths) ---
seed_paths=(
    docs/memory/global/project-brief.md
    docs/memory/global/product-context.md
    docs/memory/global/domain-glossary.md
    docs/memory/global/system-patterns.md
    docs/memory/global/tech-context.md
    docs/memory/global/decision-log.md
    docs/memory/ledger/roadmap.md
    docs/memory/ledger/progress.md
    docs/memory/ledger/learnings.md
    docs/memory/active_tasks/_task-template.md
    docs/governance/skills-policy.md
    docs/governance/memory-tags-policy.md
    docs/quality/guardrails.md
    docs/workflow/gitflow-operacional.md
    docs/workflow/ciclo-de-entrega.md
)

for path in "${seed_paths[@]}"; do
    if [[ ! -f "$path" ]]; then
        fail "missing seed file: $path (run bash .spine/install.sh)"
    fi
done

# --- Required directories ---
for dir in docs/memory/active_tasks docs/memory/completed_tasks; do
    if [[ ! -d "$dir" ]]; then
        fail "missing directory: $dir (run bash .spine/install.sh)"
    fi
done

if [[ $errors -gt 0 ]]; then
    echo "Bootstrap readiness check failed with $errors error(s)." >&2
    exit 1
fi

echo "OK: project is ready for /spine-bootstrap."
