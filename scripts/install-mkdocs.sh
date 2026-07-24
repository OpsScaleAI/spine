#!/usr/bin/env bash
set -uo pipefail

# MkDocs + Spine co-install for consumer projects.
#
# Usage:
#   bash scripts/install-mkdocs.sh --project-root=PATH [--init-mkdocs] [--targets=cursor,opencode,claude]
#   bash scripts/install-mkdocs.sh --project-root=PATH --uninstall [--purge-mkdocs]

PROJECT_ROOT=""
INIT_MKDOCS=false
UNINSTALL=false
PURGE_MKDOCS=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --project-root=*) PROJECT_ROOT="${arg#--project-root=}" ;;
        --init-mkdocs) INIT_MKDOCS=true ;;
        --uninstall) UNINSTALL=true ;;
        --purge-mkdocs) PURGE_MKDOCS=true ;;
        --dry-run) DRY_RUN=true ;;
        -h|--help)
            echo "Usage: bash scripts/install-mkdocs.sh --project-root=PATH [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --init-mkdocs    Seed templates and verify mkdocs build"
            echo "  --uninstall      Remove MkDocs files from project"
            echo "  --purge-mkdocs   With --uninstall, also remove docs/mkdocs/site/"
            echo "  --dry-run        Preview without making changes"
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
TEMPLATE_MKDOCS_DIR="$SPINE_DIR/templates/docs/mkdocs"
TARGET_MKDOCS_DIR="$PROJECT_ROOT/docs/mkdocs"

run_cmd() {
    if $DRY_RUN; then
        echo "    [DRY-RUN] Would run: $*"
        return 0
    fi
    (cd "$PROJECT_ROOT" && "$@")
}

mkdocs_cli_available() {
    if command -v uv >/dev/null 2>&1; then
        (cd "$PROJECT_ROOT" && uv run --extra docs mkdocs --version >/dev/null 2>&1) && return 0
    fi
    [[ -x "$PROJECT_ROOT/.venv/bin/mkdocs" ]] && return 0
    command -v mkdocs >/dev/null 2>&1
}

# Build from project root using the -f flag pointing to docs/mkdocs/mkdocs.yml
# Prefer uv / project venv — bare mkdocs is often missing from PATH.
run_mkdocs_build() {
    local strict=""
    if ${1:-true}; then
        strict="--strict"
    fi
    local cmd=()
    if command -v uv >/dev/null 2>&1; then
        cmd=(uv run --extra docs mkdocs build -f docs/mkdocs/mkdocs.yml $strict)
    elif [[ -x "$PROJECT_ROOT/.venv/bin/mkdocs" ]]; then
        cmd=("$PROJECT_ROOT/.venv/bin/mkdocs" build -f docs/mkdocs/mkdocs.yml $strict)
    else
        cmd=(mkdocs build -f docs/mkdocs/mkdocs.yml $strict)
    fi
    if $DRY_RUN; then
        echo "    [DRY-RUN] Would run: ${cmd[*]}"
        return 0
    fi
    (cd "$PROJECT_ROOT" && "${cmd[@]}")
}

ensure_gitignore_entry() {
    local gitignore="$PROJECT_ROOT/.gitignore"
    local entry="docs/mkdocs/site/"

    if $DRY_RUN; then
        echo "    [DRY-RUN] Would add '$entry' to .gitignore"
        return 0
    fi

    if [[ ! -f "$gitignore" ]]; then
        echo "$entry" > "$gitignore"
        echo "    added '$entry' to .gitignore"
        return 0
    fi

    if grep -qF "$entry" "$gitignore" 2>/dev/null; then
        echo "    .gitignore already contains '$entry'"
        return 0
    fi

    echo "$entry" >> "$gitignore"
    echo "    added '$entry' to .gitignore"
}

remove_gitignore_entry() {
    local gitignore="$PROJECT_ROOT/.gitignore"
    local entry="docs/mkdocs/site/"

    if $DRY_RUN; then
        echo "    [DRY-RUN] Would remove '$entry' from .gitignore"
        return 0
    fi

    if [[ ! -f "$gitignore" ]]; then
        return 0
    fi

    if grep -qF "$entry" "$gitignore" 2>/dev/null; then
        local tmp
        tmp="$(mktemp)"
        grep -vF "$entry" "$gitignore" > "$tmp" || true
        mv "$tmp" "$gitignore"
        echo "    removed '$entry' from .gitignore"
    fi
}

replace_placeholder() {
    local file="$1"
    local project_name="$2"
    if $DRY_RUN; then
        echo "    [DRY-RUN] Would replace PROJECT_NAME_PLACEHOLDER with '$project_name' in $file"
        return 0
    fi
    if [[ -f "$file" ]]; then
        sed -i "s/PROJECT_NAME_PLACEHOLDER/$project_name/g" "$file"
    fi
}

get_project_name() {
    local name
    name="$(cd "$PROJECT_ROOT" && basename "$(pwd)")"
    echo "$name"
}

seed_mkdocs_templates() {
    echo "  - MkDocs templates"

    if [[ ! -d "$TEMPLATE_MKDOCS_DIR" ]]; then
        echo "    WARNING: template directory not found: $TEMPLATE_MKDOCS_DIR" >&2
        return 1
    fi

    local project_name
    project_name="$(get_project_name)"

    # Create target directory
    if [[ ! -d "$TARGET_MKDOCS_DIR" ]]; then
        if $DRY_RUN; then
            echo "    [DRY-RUN] Would create: $TARGET_MKDOCS_DIR"
        else
            mkdir -p "$TARGET_MKDOCS_DIR"
            echo "    created: $TARGET_MKDOCS_DIR"
        fi
    fi

    # Copy template files (skip .gitkeep and .gitignore)
    for template_file in "$TEMPLATE_MKDOCS_DIR"/*; do
        local basename
        basename="$(basename "$template_file")"

        # Skip .gitkeep and .gitignore in copy — they're processed separately
        if [[ "$basename" == ".gitkeep" ]]; then
            continue
        fi

        local target_file="$TARGET_MKDOCS_DIR/$basename"

        if [[ "$basename" == ".gitignore" ]]; then
            # Merge .gitignore contents
            if $DRY_RUN; then
                echo "    [DRY-RUN] Would copy .gitignore: $template_file -> $target_file"
            elif [[ ! -f "$target_file" ]]; then
                cp "$template_file" "$target_file"
                echo "    copied: $target_file"
            else
                echo "    exists, preserving: $target_file"
            fi
            continue
        fi

        if [[ -f "$target_file" ]]; then
            echo "    exists, preserving: $target_file"
        else
            if $DRY_RUN; then
                echo "    [DRY-RUN] Would copy: $template_file -> $target_file"
            else
                cp "$template_file" "$target_file"
                replace_placeholder "$target_file" "$project_name"
                echo "    copied: $target_file"
            fi
        fi
    done
}

install_mkdocs() {
    echo "  - MkDocs CLI check"
    if mkdocs_cli_available; then
        local version
        version="$(mkdocs --version 2>/dev/null | head -1 || echo 'version unknown')"
        echo "    mkdocs detected: $(command -v mkdocs) ($version)"
    else
        echo "    WARNING: mkdocs CLI not found."
        echo "    Install:"
        echo "      pip install mkdocs"
        echo "    Or for Material theme:"
        echo "      pip install mkdocs-material"
    fi

    seed_mkdocs_templates

    ensure_gitignore_entry

    echo "  - MkDocs build"
    if ! mkdocs_cli_available; then
        echo "    skipped: mkdocs CLI not available"
    else
        if run_mkdocs_build true; then
            echo "    build passed (--strict)"
        else
            echo "    WARNING: mkdocs build --strict failed. Docs may have issues." >&2
        fi

        if [[ -d "$TARGET_MKDOCS_DIR/site" ]]; then
            echo "    site: docs/mkdocs/site/"
        fi
    fi

    echo "  - Integration verify"
    local validate_script="$SPINE_DIR/scripts/validate-mkdocs-integration.sh"
    if [[ -f "$validate_script" ]] && ! $DRY_RUN; then
        bash "$validate_script" || echo "    WARNING: validate-mkdocs-integration.sh reported issues" >&2
    fi
}

uninstall_mkdocs() {
    echo "MkDocs uninstall:"

    echo "  - MkDocs templates"
    if [[ -d "$TARGET_MKDOCS_DIR" ]]; then
        local files_to_remove=(
            "mkdocs.yml"
            "index.md"
            "architecture.md"
        )
        for file in "${files_to_remove[@]}"; do
            local target="$TARGET_MKDOCS_DIR/$file"
            if [[ -f "$target" ]]; then
                if $DRY_RUN; then
                    echo "    [DRY-RUN] Would remove: $target"
                else
                    rm "$target"
                    echo "    removed: $target"
                fi
            fi
        done

        if $PURGE_MKDOCS; then
            echo "  - Purge MkDocs output"
            if $DRY_RUN; then
                echo "    [DRY-RUN] Would remove: $TARGET_MKDOCS_DIR/site/"
            else
                rm -rf "$TARGET_MKDOCS_DIR/site"
                echo "    removed: $TARGET_MKDOCS_DIR/site/"
            fi
        else
            echo "  - Preserved docs/mkdocs/site/ (use --purge-mkdocs to remove)"
        fi

        # Remove directory if empty
        if ! $DRY_RUN; then
            local remaining
            remaining="$(find "$TARGET_MKDOCS_DIR" -maxdepth 1 -not -name '.' -not -name '..' | head -1)"
            if [[ -z "$remaining" ]]; then
                rmdir "$TARGET_MKDOCS_DIR" 2>/dev/null || true
                echo "    removed empty directory: $TARGET_MKDOCS_DIR"
            fi
        fi
    else
        echo "    no docs/mkdocs/ directory found"
    fi

    remove_gitignore_entry
}

if $UNINSTALL; then
    uninstall_mkdocs
    exit 0
fi

install_mkdocs
