#!/usr/bin/env bash
set -uo pipefail

# Validate MkDocs + Spine integration in a consumer project.
#
# Usage (from project root):
#   bash .spine/scripts/validate-mkdocs-integration.sh
#   bash .spine/scripts/validate-mkdocs-integration.sh --dry-run

DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: bash .spine/scripts/validate-mkdocs-integration.sh [--dry-run]"
            echo "Checks MkDocs configuration, CLI, and build in a consumer project."
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

if $DRY_RUN; then
    echo "[DRY-RUN] Would validate MkDocs integration from: $(pwd)"
fi

errors=0
warnings=0
fail() { echo "ERROR: $*" >&2; errors=$((errors + 1)); }
warn() { echo "WARNING: $*" >&2; warnings=$((warnings + 1)); }
ok() { echo "  $1: OK ($2)"; }

# Resolve mkdocs without requiring it on PATH (uv / venv preferred).
resolve_mkdocs_build() {
    if command -v uv >/dev/null 2>&1; then
        echo "uv run --extra docs mkdocs build -f docs/mkdocs/mkdocs.yml --strict"
        return 0
    fi
    if [[ -x .venv/bin/mkdocs ]]; then
        echo ".venv/bin/mkdocs build -f docs/mkdocs/mkdocs.yml --strict"
        return 0
    fi
    if command -v mkdocs >/dev/null 2>&1; then
        echo "mkdocs build -f docs/mkdocs/mkdocs.yml --strict"
        return 0
    fi
    return 1
}

echo "MkDocs integration report"

# --- MkDocs config ---
if [[ -f docs/mkdocs/mkdocs.yml ]]; then
    ok "Config" "docs/mkdocs/mkdocs.yml"
else
    fail "missing docs/mkdocs/mkdocs.yml (run bash .spine/install.sh and answer yes at MkDocs prompt; non-interactive: --with-mkdocs)"
fi

# --- MkDocs source files ---
if [[ -f docs/mkdocs/index.md ]]; then
    ok "Index" "docs/mkdocs/index.md"
else
    if [[ -f docs/mkdocs/mkdocs.yml ]]; then
        warn "missing docs/mkdocs/index.md (run bash .spine/install.sh --update)"
    fi
fi

# --- CLI ---
MKDOCS_BUILD_CMD=""
if MKDOCS_BUILD_CMD="$(resolve_mkdocs_build)"; then
    if command -v uv >/dev/null 2>&1 && uv run --extra docs mkdocs --version >/dev/null 2>&1; then
        version="$(uv run --extra docs mkdocs --version 2>/dev/null | head -1 || echo 'unknown version')"
        ok "CLI" "uv run --extra docs mkdocs — $version"
    elif [[ -x .venv/bin/mkdocs ]]; then
        version="$(.venv/bin/mkdocs --version 2>/dev/null | head -1 || echo 'unknown version')"
        ok "CLI" ".venv/bin/mkdocs — $version"
    else
        version="$(mkdocs --version 2>/dev/null | head -1 || echo 'unknown version')"
        ok "CLI" "mkdocs — $version"
    fi
else
    fail "mkdocs not available via uv, .venv/bin/mkdocs, or PATH (uv sync --extra docs / uv pip install -r requirements-docs.txt)"
fi

# --- Build ---
if [[ -f docs/mkdocs/mkdocs.yml && -n "$MKDOCS_BUILD_CMD" ]]; then
    if eval "$MKDOCS_BUILD_CMD" >/dev/null 2>&1; then
        ok "Build" "$MKDOCS_BUILD_CMD passes"
    else
        warn "mkdocs build --strict failed (check docs/mkdocs/*.md for broken links or invalid YAML)"
    fi

    if [[ -d docs/mkdocs-site ]]; then
        ok "Output" "docs/mkdocs-site/ present"
    elif [[ -d docs/mkdocs/site ]]; then
        ok "Output" "docs/mkdocs/site/ present"
    else
        warn "site output not found (expected docs/mkdocs-site/ or docs/mkdocs/site/)"
    fi
fi

# --- Gitignore ---
if [[ -f .gitignore ]] && grep -qE 'docs/mkdocs(-site|/site)/' .gitignore 2>/dev/null; then
    ok "Gitignore" "MkDocs site output is gitignored"
else
    warn "docs/mkdocs/site/ or docs/mkdocs-site/ not in .gitignore (output may be accidentally committed)"
fi

if [[ $errors -gt 0 ]]; then
    echo "MkDocs integration check failed with $errors error(s), $warnings warning(s)." >&2
    exit 1
fi

if [[ $warnings -gt 0 ]]; then
    echo "OK: MkDocs integration passed with $warnings warning(s)."
else
    echo "OK: MkDocs integration complete."
fi
exit 0
