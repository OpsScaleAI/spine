#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# Spine — Global Installation Script
#
# Creates directory-level symlinks from the Spine repository into the global
# configuration directories of Cursor, OpenCode, and Claude Code, making
# skills, commands, and rules available in every project session.
#
# Total: 7 symlinks (3 Cursor + 2 OpenCode + 2 Claude Code)
#
# Idempotent: re-running skips items that are already correctly linked.
# Non-destructive by default: never overwrites existing directories.
# Use --force to replace existing directories with symlinks (creates backup).
#
# Usage:
#   bash install.sh            # conservative, never overwrites
#   bash install.sh --force   # replaces real dirs with symlinks (backups first)
#   bash install.sh --dry-run # preview without making changes
# =============================================================================

# ---------------------------------------------------------------------------
# Parse Arguments
# ---------------------------------------------------------------------------

FORCE=false
DRY_RUN=false

for arg in "$@"; do
    case "$arg" in
        --force)   FORCE=true ;;
        --dry-run) DRY_RUN=true ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Usage: bash install.sh [--force] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve Spine Repository Root
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPINE_DIR="$(cd "$SCRIPT_DIR" && pwd)"

if [[ ! -d "$SPINE_DIR/rules" || ! -d "$SPINE_DIR/skills" || ! -d "$SPINE_DIR/commands" ]]; then
    echo "ERROR: Cannot find rules/, skills/, or commands/ in $SPINE_DIR" >&2
    echo "       Make sure install.sh is inside the Spine repository root." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# OS Detection
# ---------------------------------------------------------------------------

detect_os() {
    local uname_out
    uname_out="$(uname -s)"
    case "$uname_out" in
        Linux*)
            if grep -qi "microsoft" /proc/version 2>/dev/null; then
                echo "wsl"
            else
                echo "linux"
            fi
            ;;
        Darwin*)
            echo "macos"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

OS="$(detect_os)"

# ---------------------------------------------------------------------------
# Path Configuration
# ---------------------------------------------------------------------------

# Cursor: ~/.cursor/
CURSOR_DIR="$HOME/.cursor"
CURSOR_RULES="$CURSOR_DIR/rules"
CURSOR_SKILLS="$CURSOR_DIR/skills"
CURSOR_COMMANDS="$CURSOR_DIR/commands"

# OpenCode: respects XDG_CONFIG_HOME
OC_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
OC_SKILLS="$OC_CONFIG_DIR/skills"
OC_COMMANDS="$OC_CONFIG_DIR/commands"

# Claude Code: ~/.claude/
CLAUDE_DIR="$HOME/.claude"
CLAUDE_RULES="$CLAUDE_DIR/rules"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"

# Source directories in Spine repo
SPINE_RULES="$SPINE_DIR/rules"
SPINE_SKILLS="$SPINE_DIR/skills"
SPINE_COMMANDS="$SPINE_DIR/commands"

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------

LINKED=0
SKIPPED=0
CONFLICTS=0
BACKED_UP=0
WARNINGS=0

# ---------------------------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------------------------

log_linked()   { printf "  \033[32m+\033[0m %s\n" "$1"; }
log_skipped()  { printf "  \033[34m=\033[0m %s\n" "$1"; }
log_conflict() { printf "  \033[31m✗\033[0m %s\n" "$1"; }
log_warn()     { printf "  \033[33m!\033[0m %s\n" "$1"; }
log_backup()   { printf "  \033[33m↗\033[0m %s (backed up to %s)\n" "$1" "$2"; }

mkdir_p() {
    local dir="$1"
    if $DRY_RUN; then
        echo "  [DRY-RUN] Would create directory: $dir"
    else
        mkdir -p "$dir"
    fi
}

# create_dir_symlink source_dir target_dir label
# Returns: 0=created, 1=skipped, 2=warning, 3=conflict
create_dir_symlink() {
    local source="$1"
    local target="$2"
    local label="$3"

    # --- Target does not exist ---
    if [[ ! -e "$target" && ! -L "$target" ]]; then
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would link: $label"
            echo "             $target -> $source"
        else
            ln -s "$source" "$target"
            log_linked "$label"
        fi
        return 0
    fi

    # --- Target is a symlink ---
    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"

        # Resolve to absolute path for comparison
        local resolved
        if [[ "$current" = /* ]]; then
            resolved="${current%/}"
        else
            resolved="$(cd "$(dirname "$target")" && pwd)/${current%/}"
        fi

        local source_clean="${source%/}"

        if [[ "$resolved" == "$source_clean" ]]; then
            log_skipped "$label (already linked)"
            return 1
        else
            if $FORCE; then
                if $DRY_RUN; then
                    echo "  [DRY-RUN] Would remove old symlink: $target"
                    echo "  [DRY-RUN] Would link: $label"
                    echo "             $target -> $source"
                else
                    rm "$target"
                    ln -s "$source" "$target"
                    log_warn "$label (old symlink replaced)"
                fi
                return 0
            else
                log_warn "$label"
                echo "             Symlink exists but points to: $current" >&2
                echo "             Expected: $source" >&2
                echo "             Use --force to replace, or remove manually." >&2
                return 2
            fi
        fi
    fi

    # --- Target is a real directory ---
    if [[ -d "$target" ]]; then
        if $FORCE; then
            local backup="${target}.spine-backup"
            if $DRY_RUN; then
                echo "  [DRY-RUN] Would back up: $target -> $backup"
                echo "  [DRY-RUN] Would link: $label"
                echo "             $target -> $source"
            else
                mv "$target" "$backup"
                ln -s "$source" "$target"
                log_backup "$label" "$backup"
            fi
            return 0
        else
            log_conflict "$label"
            echo "             Conflict: $target is a real directory, not a symlink." >&2
            echo "             Use --force to back it up and replace with a symlink." >&2
            return 3
        fi
    fi

    # --- Target is a regular file (shouldn't happen for dirs) ---
    log_conflict "$label"
    echo "             Conflict: $target exists and is a regular file." >&2
    echo "             Remove or rename it, then re-run install.sh." >&2
    return 3
}

# ---------------------------------------------------------------------------
# Ensure Executable Permissions
# ---------------------------------------------------------------------------

chmod_scripts() {
    local count=0

    if [[ -f "$SPINE_DIR/install.sh" ]]; then
        if ! $DRY_RUN; then chmod +x "$SPINE_DIR/install.sh"; fi
        count=$((count + 1))
    fi

    local script
    for script in "$SPINE_DIR"/scripts/*.sh; do
        if [[ -f "$script" ]]; then
            if ! $DRY_RUN; then chmod +x "$script"; fi
            count=$((count + 1))
        fi
    done

    if $DRY_RUN; then
        echo "  [DRY-RUN] Would chmod +x on $count script(s)"
    else
        printf "  \033[32m+\033[0m chmod +x on %d script(s)\n" "$count"
    fi
}

# ---------------------------------------------------------------------------
# Increment counter from return code
# ---------------------------------------------------------------------------

tally() {
    local rc=$1
    case $rc in
        0) LINKED=$((LINKED + 1)) ;;
        1) SKIPPED=$((SKIPPED + 1)) ;;
        2) WARNINGS=$((WARNINGS + 1)) ;;
        3) CONFLICTS=$((CONFLICTS + 1)) ;;
    esac
}

# ---------------------------------------------------------------------------
# Install Sections
# ---------------------------------------------------------------------------

install_cursor() {
    echo ""
    echo "=== Cursor ==="
    echo "Config dir: $CURSOR_DIR"

    # Don't auto-create ~/.cursor — it likely already exists from Cursor itself
    # Only create parent dirs for our symlinks
    mkdir_p "$(dirname "$CURSOR_RULES")"

    echo ""
    echo "Rules:"
    create_dir_symlink "$SPINE_RULES" "$CURSOR_RULES" "rules"; tally $?

    echo ""
    echo "Skills:"
    create_dir_symlink "$SPINE_SKILLS" "$CURSOR_SKILLS" "skills"; tally $?

    echo ""
    echo "Commands:"
    create_dir_symlink "$SPINE_COMMANDS" "$CURSOR_COMMANDS" "commands"; tally $?
}

install_opencode() {
    echo ""
    echo "=== OpenCode ==="
    echo "Config dir: $OC_CONFIG_DIR"

    mkdir_p "$OC_CONFIG_DIR"

    echo ""
    echo "Skills:"
    create_dir_symlink "$SPINE_SKILLS" "$OC_SKILLS" "skills"; tally $?

    echo ""
    echo "Commands:"
    create_dir_symlink "$SPINE_COMMANDS" "$OC_COMMANDS" "commands"; tally $?
}

install_claude() {
    echo ""
    echo "=== Claude Code ==="
    echo "Config dir: $CLAUDE_DIR"

    mkdir_p "$CLAUDE_DIR"

    echo ""
    echo "Rules:"
    create_dir_symlink "$SPINE_RULES" "$CLAUDE_RULES" "rules"; tally $?

    echo ""
    echo "Skills:"
    create_dir_symlink "$SPINE_SKILLS" "$CLAUDE_SKILLS" "skills"; tally $?
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

print_summary() {
    echo ""
    echo "==========================================="
    echo "  Spine Global Install Summary"
    echo "==========================================="
    echo ""
    echo "Detected OS: $OS"
    echo "Spine repo : $SPINE_DIR"
    echo "Mode       : $([ "$FORCE" = true ] && echo "force" || echo "conservative")"
    echo ""
    echo "  Linked   : $LINKED"
    echo "  Skipped  : $SKIPPED (already correct)"
    echo "  Backed up: $BACKED_UP"
    echo "  Conflicts: $CONFLICTS"
    echo "  Warnings : $WARNINGS"
    echo ""

    if [[ $CONFLICTS -gt 0 ]]; then
        printf "\033[33m⚠ %d conflict(s) detected.\033[0m\n" "$CONFLICTS"
        echo "  Real directories blocked symlink creation."
        echo "  Re-run with --force to back them up and replace with symlinks."
        echo ""
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        printf "\033[33m⚠ %d warning(s) detected.\033[0m\n" "$WARNINGS"
        echo "  Some symlinks point to unexpected targets."
        echo "  Re-run with --force to replace them."
        echo ""
    fi

    echo "Symlink map:"
    echo "  Cursor:    $CURSOR_RULES -> $SPINE_RULES"
    echo "              $CURSOR_SKILLS -> $SPINE_SKILLS"
    echo "              $CURSOR_COMMANDS -> $SPINE_COMMANDS"
    echo "  OpenCode:   $OC_SKILLS -> $SPINE_SKILLS"
    echo "              $OC_COMMANDS -> $SPINE_COMMANDS"
    echo "  Claude Code: $CLAUDE_RULES -> $SPINE_RULES"
    echo "               $CLAUDE_SKILLS -> $SPINE_SKILLS"
    echo ""
    echo "==========================================="
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo "Spine Global Installer"
echo "Repository: $SPINE_DIR"
echo "OS: $OS"
if $FORCE; then echo "Mode: force (will back up real directories)"; fi

chmod_scripts
install_cursor
install_opencode
install_claude
print_summary

if $DRY_RUN; then
    echo ""
    echo "This was a dry run. No changes were made."
    echo "Run without --dry-run to apply."
fi