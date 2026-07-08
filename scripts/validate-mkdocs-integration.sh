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
if command -v mkdocs >/dev/null 2>&1; then
    version="$(mkdocs --version 2>/dev/null | head -1 || echo 'unknown version')"
    ok "CLI" "mkdocs — $version"
else
    fail "mkdocs CLI not on PATH (pip install mkdocs)"
fi

# --- Build ---
if [[ -f docs/mkdocs/mkdocs.yml ]]; then
    if command -v mkdocs >/dev/null 2>&1; then
        if mkdocs build -f docs/mkdocs/mkdocs.yml --strict >/dev/null 2>&1; then
            ok "Build" "mkdocs build --strict passes"
        else
            warn "mkdocs build --strict failed (check docs/mkdocs/*.md for broken links or invalid YAML)"
        fi
    fi

    if [[ -d docs/mkdocs/site ]]; then
        ok "Output" "docs/mkdocs/site/ present"
    else
        warn "docs/mkdocs/site/ not found (run mkdocs build -f docs/mkdocs/mkdocs.yml)"
    fi
fi

# --- Gitignore ---
if [[ -f .gitignore ]] && grep -qF "docs/mkdocs/site/" .gitignore 2>/dev/null; then
    ok "Gitignore" "docs/mkdocs/site/ is gitignored"
else
    warn "docs/mkdocs/site/ not in .gitignore (output may be accidentally committed)"
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
