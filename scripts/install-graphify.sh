#!/usr/bin/env bash
set -uo pipefail

PROJECT_ROOT=""
INIT_GRAPH=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --project-root=*) PROJECT_ROOT="${arg#--project-root=}" ;;
        --init-graph) INIT_GRAPH=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: bash scripts/install-graphify.sh --project-root=PATH [--init-graph] [--dry-run]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$PROJECT_ROOT" ]]; then
    echo "ERROR: --project-root is required." >&2
    exit 1
fi

if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo "ERROR: Project root not found: $PROJECT_ROOT" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPINE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE="$SPINE_DIR/templates/dot.graphifyignore"
TARGET="$PROJECT_ROOT/.graphifyignore"

echo "  - Graphify CLI check"
if command -v graphify >/dev/null 2>&1; then
    echo "    graphify detected: $(command -v graphify)"
else
    echo "    WARNING: graphify CLI not found."
    echo "    Install globally (recommended):"
    echo "      uv tool install graphifyy"
    echo "    Alternatives:"
    echo "      pipx install graphifyy"
    echo "      pip install graphifyy"
fi

echo "  - .graphifyignore"
if [[ ! -f "$TEMPLATE" ]]; then
    echo "    WARNING: template not found: $TEMPLATE"
else
    if [[ -f "$TARGET" ]]; then
        echo "    exists, preserving: $TARGET"
    else
        if $DRY_RUN; then
            echo "    [DRY-RUN] Would copy $TEMPLATE -> $TARGET"
        else
            cp "$TEMPLATE" "$TARGET"
            echo "    copied: $TARGET"
        fi
    fi
fi

if $INIT_GRAPH; then
    echo "  - initial graph build"
    if ! command -v graphify >/dev/null 2>&1; then
        echo "    skipped: graphify CLI not available"
    else
        if $DRY_RUN; then
            echo "    [DRY-RUN] Would run: graphify update . (in $PROJECT_ROOT)"
        else
            (cd "$PROJECT_ROOT" && graphify update .) || {
                echo "    WARNING: initial graph build failed. You can rerun manually: graphify update ." >&2
            }
        fi
    fi
fi
