#!/usr/bin/env bash
set -uo pipefail

# Validate a Memory Bank active task file against the v2.1 contract.
#
# Usage:
#   bash scripts/validate-task.sh docs/memory/active_tasks/007-foo.md
#   bash scripts/validate-task.sh --dry-run path/to/task.md

DRY_RUN=false
TASK_FILE=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: bash scripts/validate-task.sh [--dry-run] TASK.md"
            exit 0
            ;;
        *)
            TASK_FILE="$arg"
            ;;
    esac
done

if [[ -z "$TASK_FILE" ]]; then
    echo "ERROR: task file path required." >&2
    exit 1
fi

if [[ ! -f "$TASK_FILE" ]]; then
    echo "ERROR: file not found: $TASK_FILE" >&2
    exit 1
fi

if $DRY_RUN; then
    echo "[DRY-RUN] Would validate: $TASK_FILE"
    exit 0
fi

errors=0
warn() { echo "WARNING: $*" >&2; }
fail() { echo "ERROR: $*" >&2; errors=$((errors + 1)); }

content="$(cat "$TASK_FILE")"

if [[ "$content" != ---* ]]; then
    fail "missing YAML frontmatter (file must start with ---)"
else
    fm="${content#---}"
    fm="${fm%%---*}"
    required_keys=(task_id title goal status tags branch base created_at updated_at)
    for key in "${required_keys[@]}"; do
        if ! grep -q "^${key}:" <<< "$fm"; then
            fail "frontmatter missing key: $key"
        fi
    done

    branch_line="$(grep -E '^branch:' <<< "$fm" | head -1 || true)"
    if [[ -n "$branch_line" ]] && [[ ! "$branch_line" =~ feature/ ]]; then
        warn "branch does not start with feature/ (non-standard GitFlow): $branch_line"
    fi

    base_line="$(grep -E '^base:' <<< "$fm" | head -1 || true)"
    if [[ -n "$base_line" ]] && [[ "$base_line" != *develop* ]]; then
        warn "base is not develop: $base_line"
    fi

    tag_count="$(grep -E '^[[:space:]]+- ' <<< "$fm" | wc -l | tr -d ' ')"
    if [[ "$tag_count" -lt 1 ]]; then
        fail "tags list empty (need 1-5 tags)"
    elif [[ "$tag_count" -gt 5 ]]; then
        fail "too many tags ($tag_count; max 5)"
    fi
fi

for pattern in '^\*\*Status:\*\*' '^\*\*Branch:\*\*'; do
    if grep -qE "$pattern" "$TASK_FILE"; then
        fail "legacy pattern found: $pattern"
    fi
done

if grep -iE 'superpowers:' "$TASK_FILE" | grep -viE 'do not|never use|`superpowers' | grep -q .; then
    fail "promotional superpowers: reference found (use execution_skill in frontmatter)"
fi

for section in "## Objective" "## Acceptance Criteria"; do
    if ! grep -q "$section" "$TASK_FILE"; then
        fail "missing required section: $section"
    fi
done

if grep -qE '^### Task [0-9]+:' "$TASK_FILE"; then
    if ! grep -q '## Implementation Plan' "$TASK_FILE"; then
        fail "Task N blocks found outside ## Implementation Plan section"
    fi
fi

if [[ $errors -gt 0 ]]; then
    echo "Validation failed with $errors error(s)." >&2
    exit 1
fi

echo "OK: $TASK_FILE matches Memory Bank v2.1 task contract."
