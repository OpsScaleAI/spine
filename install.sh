#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# Spine — Installation Script
#
# Supports two modes:
#
#   GLOBAL (default): Creates directory-level symlinks from the Spine repository
#   into the global configuration directories of Cursor, OpenCode, and Claude Code.
#
#   PROJECT (--project): Creates per-project symlinks using .agents/ as the
#   cross-tool hub. Skills are installed per-name for granular control.
#
# Usage:
#   bash install.sh                            # Global install (conservative)
#   bash install.sh --force                    # Global install (replace existing)
#   bash install.sh --dry-run                  # Preview without changes
#   bash install.sh --project                  # Project install (all skills)
#   bash install.sh --project --skills=all     # Project install (all skills)
#   bash install.sh --project --skills=a,b,c   # Project install (specific skills)
#   bash install.sh --project --add-skill=x   # Add a skill to existing project
#   bash install.sh --project --remove-skill=x # Remove a skill from project
#   bash install.sh --project --list-skills    # List available/installed skills
#   bash install.sh --project --dry-run        # Preview project install
# =============================================================================

# ---------------------------------------------------------------------------
# Parse Arguments
# ---------------------------------------------------------------------------

FORCE=false
DRY_RUN=false
PROJECT_MODE=false
SPINE_DIR_CUSTOM=""
SKILLS_ARG=""
ADD_SKILL=""
REMOVE_SKILL=""
LIST_SKILLS=false
TARGETS="cursor,opencode,claude"

for arg in "$@"; do
    case "$arg" in
        --force)          FORCE=true ;;
        --dry-run)        DRY_RUN=true ;;
        --project)        PROJECT_MODE=true ;;
        --spine-dir=*)    SPINE_DIR_CUSTOM="${arg#--spine-dir=}" ;;
        --skills=*)       SKILLS_ARG="${arg#--skills=}" ;;
        --add-skill=*)    ADD_SKILL="${arg#--add-skill=}" ;;
        --remove-skill=*) REMOVE_SKILL="${arg#--remove-skill=}" ;;
        --list-skills)    LIST_SKILLS=true ;;
        --targets=*)      TARGETS="${arg#--targets=}" ;;
        -h|--help)
            echo "Usage: bash install.sh [OPTIONS]"
            echo ""
            echo "Global mode (default):"
            echo "  --force              Replace existing directories with symlinks"
            echo "  --dry-run            Preview without making changes"
            echo ""
            echo "Project mode:"
            echo "  --project            Install per-project symlinks (inside git repo)"
            echo "  --spine-dir=PATH     Path to Spine repository (default: auto-detect)"
            echo "  --skills=core|all|a,b,c  Skill selection (default: all)"
            echo "  --add-skill=NAME     Add a single skill to existing project"
            echo "  --remove-skill=NAME  Remove a single skill from project"
            echo "  --list-skills        List available and installed skills"
            echo "  --targets=LIST      Comma-separated: cursor,opencode,claude"
            echo "  --dry-run            Preview without making changes"
            echo ""
            echo "Examples:"
            echo "  bash install.sh --project"
            echo "  bash install.sh --project --skills=python-patterns,fastapi-pro"
            echo "  bash install.sh --project --list-skills"
            echo "  bash install.sh --project --add-skill=astro"
            echo "  bash install.sh --project --remove-skill=astro"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            echo "Run with --help for usage." >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve Spine Repository Root
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPINE_DIR="$(cd "$SCRIPT_DIR" && pwd)"

if [[ -n "$SPINE_DIR_CUSTOM" ]]; then
    SPINE_DIR="$(cd "$SPINE_DIR_CUSTOM" 2>/dev/null || echo "")"
    if [[ -z "$SPINE_DIR" ]]; then
        echo "ERROR: --spine-dir not found: $SPINE_DIR_CUSTOM" >&2
        exit 1
    fi
fi

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
# Core Skills (base profile)
# ---------------------------------------------------------------------------

CORE_SKILLS=(
    "writing-plans"
    "executing-plans"
    "test-driven-development"
    "systematic-debugging"
    "verification-before-completion"
)

# ---------------------------------------------------------------------------
# Dynamic Discovery Functions
# ---------------------------------------------------------------------------

get_rule_files() {
    local rules_dir="$SPINE_DIR/rules"
    if [[ ! -d "$rules_dir" ]]; then
        return
    fi
    local rule_file
    for rule_file in "$rules_dir"/*.md; do
        [[ -f "$rule_file" ]] && basename "$rule_file"
    done | sort
}

get_command_files() {
    local commands_dir="$SPINE_DIR/commands"
    if [[ ! -d "$commands_dir" ]]; then
        return
    fi
    local command_file
    for command_file in "$commands_dir"/*.md; do
        [[ -f "$command_file" ]] && basename "$command_file"
    done | sort
}

# ---------------------------------------------------------------------------
# Gitignore entries for consumer projects (not versioned)
# ---------------------------------------------------------------------------

PROJECT_GITIGNORE_ENTRIES=(
    ".spine"
    ".agents/"
    ".cursor/"
    ".claude/"
    ".opencode/"
    "AGENTS.md"
    "CLAUDE.md"
)

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------

LINKED=0
SKIPPED=0
CONFLICTS=0
BACKED_UP=0
WARNINGS=0

# ---------------------------------------------------------------------------
# Helper Functions (Shared)
# ---------------------------------------------------------------------------

log_linked()   { printf "  \033[32m+\033[0m %s\n" "$1"; }
log_skipped()  { printf "  \033[34m=\033[0m %s\n" "$1"; }
log_conflict() { printf "  \033[31m✗\033[0m %s\n" "$1"; }
log_warn()     { printf "  \033[33m!\033[0m %s\n" "$1"; }
log_info()    { printf "  \033[36mℹ\033[0m %s\n" "$1"; }

mkdir_p() {
    local dir="$1"
    if $DRY_RUN; then
        echo "  [DRY-RUN] Would create directory: $dir"
    else
        mkdir -p "$dir"
    fi
}

# create_dir_symlink source_dir target_dir label
# For global mode (absolute paths). Returns: 0=created, 1=skipped, 2=warning, 3=conflict
create_dir_symlink() {
    local source="$1"
    local target="$2"
    local label="$3"

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

    if [[ -L "$target" ]]; then
        local current
        current="$(readlink "$target")"
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

    log_conflict "$label"
    echo "             Conflict: $target exists and is a regular file." >&2
    echo "             Remove or rename it, then re-run install.sh." >&2
    return 3
}

# create_relative_symlink rel_target link_path label
# For project mode. Creates symlinks with relative paths.
# Returns: 0=created, 1=skipped, 2=warning, 3=conflict
create_relative_symlink() {
    local rel_target="$1"
    local link_path="$2"
    local label="$3"

    local parent_dir
    parent_dir="$(dirname "$link_path")"
    mkdir_p "$parent_dir"

    if [[ -L "$link_path" ]]; then
        local current
        current="$(readlink "$link_path")"

        if [[ "$current" == "$rel_target" ]]; then
            log_skipped "$label (already linked)"
            return 1
        fi

        if $FORCE; then
            if $DRY_RUN; then
                echo "  [DRY-RUN] Would replace: $link_path"
                echo "             $current -> $rel_target"
            else
                rm "$link_path"
                ln -s "$rel_target" "$link_path"
                log_warn "$label (replaced: $current -> $rel_target)"
            fi
            return 0
        else
            log_warn "$label (points to $current, expected $rel_target)"
            echo "             Use --force to replace." >&2
            return 2
        fi

    elif [[ -e "$link_path" ]]; then
        log_conflict "$label ($link_path exists and is not a symlink)"
        echo "             Remove it and re-run install.sh." >&2
        return 3
    else
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would link: $link_path -> $rel_target"
        else
            ln -s "$rel_target" "$link_path"
            log_linked "$label"
        fi
        return 0
    fi
}

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

# ===========================================================================
# GLOBAL MODE: Install to user-level config directories
# ===========================================================================

CURSOR_DIR="$HOME/.cursor"
CURSOR_RULES="$CURSOR_DIR/rules"
CURSOR_SKILLS="$CURSOR_DIR/skills"
CURSOR_COMMANDS="$CURSOR_DIR/commands"

OC_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
OC_SKILLS="$OC_CONFIG_DIR/skills"
OC_COMMANDS="$OC_CONFIG_DIR/commands"

CLAUDE_DIR="$HOME/.claude"
CLAUDE_RULES="$CLAUDE_DIR/rules"
CLAUDE_SKILLS="$CLAUDE_DIR/skills"

SPINE_RULES="$SPINE_DIR/rules"
SPINE_SKILLS="$SPINE_DIR/skills"
SPINE_COMMANDS="$SPINE_DIR/commands"

install_cursor() {
    echo ""
    echo "=== Cursor ==="
    echo "Config dir: $CURSOR_DIR"

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
    echo "             $CURSOR_SKILLS -> $SPINE_SKILLS"
    echo "             $CURSOR_COMMANDS -> $SPINE_COMMANDS"
    echo "  OpenCode:   $OC_SKILLS -> $SPINE_SKILLS"
    echo "               $OC_COMMANDS -> $SPINE_COMMANDS"
    echo "  Claude Code: $CLAUDE_RULES -> $SPINE_RULES"
    echo "               $CLAUDE_SKILLS -> $SPINE_SKILLS"
    echo ""
    echo "==========================================="
}

# ===========================================================================
# PROJECT MODE: Install per-project symlinks with granular skill selection
# ===========================================================================

# --- Find project root (git worktree) ---

find_project_root() {
    local root
    root="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [[ -z "$root" ]]; then
        echo "ERROR: Not inside a git repository." >&2
        echo "       Project mode requires a git repo." >&2
        exit 1
    fi
    echo "$root"
}

# --- Ensure .spine symlink exists in project root ---

ensure_spine_symlink() {
    local project_root="$1"
    local spine_link="$project_root/.spine"

    if [[ -L "$spine_link" ]]; then
        local current resolved spine_resolved
        current="$(readlink "$spine_link")"
        if [[ "$current" = /* ]]; then
            resolved="${current%/}"
        else
            resolved="$(cd "$project_root" && cd "$(dirname "$current")" 2>/dev/null && pwd)/$(basename "$current")"
        fi
        spine_resolved="$(cd "$SPINE_DIR" && pwd)"

        if [[ "$resolved" == "$spine_resolved" ]]; then
            log_skipped ".spine symlink (already linked)"
            return 0
        else
            if $FORCE; then
                if $DRY_RUN; then
                    echo "  [DRY-RUN] Would replace .spine symlink: $current -> $SPINE_DIR"
                else
                    rm "$spine_link"
                    ln -s "$SPINE_DIR" "$spine_link"
                    log_warn ".spine (replaced: $current -> $SPINE_DIR)"
                fi
                return 0
            else
                log_warn ".spine (points to $current, expected $SPINE_DIR)"
                echo "             Use --force to replace." >&2
                return 2
            fi
        fi
    fi

    if [[ -d "$spine_link" && ! -L "$spine_link" ]]; then
        log_conflict ".spine"
        echo "             $spine_link is a real directory, not a symlink." >&2
        echo "             Remove it and re-run install.sh." >&2
        return 3
    fi

    if $DRY_RUN; then
        echo "  [DRY-RUN] Would link: .spine -> $SPINE_DIR"
    else
        ln -s "$SPINE_DIR" "$spine_link"
        log_linked ".spine -> $SPINE_DIR"
    fi
    return 0
}

# --- Get available skills from Spine repo ---

get_available_skills() {
    local skills_dir="$SPINE_DIR/skills"
    if [[ ! -d "$skills_dir" ]]; then
        return
    fi
    local skill_dir
    for skill_dir in "$skills_dir"/*/; do
        if [[ -f "$skill_dir/SKILL.md" ]]; then
            basename "$skill_dir"
        fi
    done | sort
}

# --- Get currently installed skills in project ---

get_installed_skills() {
    local project_root="$1"
    local agents_skills="$project_root/.agents/skills"
    if [[ ! -d "$agents_skills" ]]; then
        return
    fi
    local link
    for link in "$agents_skills"/*; do
        if [[ -L "$link" ]]; then
            basename "$link"
        fi
    done | sort
}

# --- Resolve skill list from argument ---

resolve_skills() {
    local skills_arg="$1"
    if [[ "$skills_arg" == "all" || -z "$skills_arg" ]]; then
        get_available_skills
    elif [[ "$skills_arg" == "core" ]]; then
        printf '%s\n' "${CORE_SKILLS[@]}"
    else
        echo "$skills_arg" | tr ',' '\n'
    fi
}

# --- Install skills in .agents/skills/ (per-skill symlinks) ---

install_project_skills() {
    local project_root="$1"
    local skill_list="$2"
    local agents_skills="$project_root/.agents/skills"

    mkdir_p "$agents_skills"

    echo ""
    echo "Skills (per-skill symlinks in .agents/skills/):"

    local skill
    echo "$skill_list" | while read -r skill; do
        [[ -z "$skill" ]] && continue

        local source_dir="$SPINE_DIR/skills/$skill"
        if [[ ! -d "$source_dir" ]]; then
            log_warn "Skill '$skill' not found in Spine repo, skipping"
            continue
        fi

        local link_path="$agents_skills/$skill"
        local rel_target="../../.spine/skills/$skill"

        create_relative_symlink "$rel_target" "$link_path" "skill: $skill"
    done
}

# --- Install Cursor rules, commands, and skills ---

install_project_cursor() {
    local project_root="$1"
    local cursor_rules="$project_root/.cursor/rules"
    local cursor_commands="$project_root/.cursor/commands"
    local cursor_skills="$project_root/.cursor/skills"

    echo ""
    echo "=== Cursor (project-level) ==="

    mkdir_p "$cursor_rules"

    echo ""
    echo "Rules (per-file symlinks):"
    local rule_file
    for rule_file in $(get_rule_files); do
        local source_abs="$SPINE_DIR/rules/$rule_file"
        if [[ ! -f "$source_abs" ]]; then
            log_warn "Rule '$rule_file' not found, skipping"
            continue
        fi
        local link_path="$cursor_rules/$rule_file"
        local rel_target="../../.spine/rules/$rule_file"
        create_relative_symlink "$rel_target" "$link_path" "rule: $rule_file"; tally $?
    done

    mkdir_p "$cursor_commands"

    echo ""
    echo "Commands (per-file symlinks):"
    local command_file
    for command_file in $(get_command_files); do
        local source_abs="$SPINE_DIR/commands/$command_file"
        if [[ ! -f "$source_abs" ]]; then
            log_warn "Command '$command_file' not found, skipping"
            continue
        fi
        local link_path="$cursor_commands/$command_file"
        local rel_target="../../.spine/commands/$command_file"
        create_relative_symlink "$rel_target" "$link_path" "command: $command_file"; tally $?
    done

    echo ""
    echo "Skills (symlink to .agents/skills/):"
    create_relative_symlink "../.agents/skills" "$cursor_skills" "skills"; tally $?
}

# --- Install Claude Code skills ---

install_project_claude() {
    local project_root="$1"
    local claude_skills="$project_root/.claude/skills"

    echo ""
    echo "=== Claude Code (project-level) ==="

    echo ""
    echo "Skills (symlink to .agents/skills/):"
    create_relative_symlink "../.agents/skills" "$claude_skills" "skills"; tally $?
}

# --- Install OpenCode commands ---

install_project_opencode() {
    local project_root="$1"
    local oc_commands="$project_root/.opencode/commands"

    echo ""
    echo "=== OpenCode (project-level) ==="

    mkdir_p "$oc_commands"

    echo ""
    echo "Commands (per-file symlinks):"
    local command_file
    for command_file in $(get_command_files); do
        local source_abs="$SPINE_DIR/commands/$command_file"
        if [[ ! -f "$source_abs" ]]; then
            log_warn "Command '$command_file' not found, skipping"
            continue
        fi
        local link_path="$oc_commands/$command_file"
        local rel_target="../../.spine/commands/$command_file"
        create_relative_symlink "$rel_target" "$link_path" "command: $command_file"; tally $?
    done
}

# --- Add gitignore entries for consumer project ---

add_gitignore_entries() {
    local project_root="$1"
    local gitignore="$project_root/.gitignore"

    echo ""
    echo "Gitignore:"

    if [[ ! -f "$gitignore" ]]; then
        if $DRY_RUN; then
            echo "  [DRY-RUN] Would create .gitignore with Spine entries"
        else
            printf "# Spine agent configuration (machine-specific)\n" > "$gitignore"
            local entry
            for entry in "${PROJECT_GITIGNORE_ENTRIES[@]}"; do
                printf "%s\n" "$entry" >> "$gitignore"
            done
            log_linked ".gitignore (created with Spine entries)"
        fi
        return 0
    fi

    local entry added=0
    for entry in "${PROJECT_GITIGNORE_ENTRIES[@]}"; do
        if ! grep -qxF "$entry" "$gitignore" 2>/dev/null; then
            if $DRY_RUN; then
                echo "  [DRY-RUN] Would add '$entry' to .gitignore"
            else
                echo "$entry" >> "$gitignore"
                log_linked ".gitignore: +$entry"
            fi
            added=$((added + 1))
        else
            log_skipped ".gitignore: $entry (already present)"
        fi
    done

    if [[ $added -gt 0 ]] && ! $DRY_RUN; then
        log_info "$added gitignore entries added"
    fi
}

# --- List available and installed skills ---

list_skills() {
    local project_root
    project_root="$(find_project_root)"

    echo ""
    echo "==========================================="
    echo "  Spine Skills"
    echo "==========================================="
    echo ""
    echo "Spine repo: $SPINE_DIR"
    echo "Project:    $project_root"
    echo ""

    echo "Core skills (installed by default with --project):"
    local core
    for core in "${CORE_SKILLS[@]}"; do
        local marker=" "
        if [[ -L "$project_root/.agents/skills/$core" ]]; then
            marker="✓"
        fi
        echo "  [$marker] $core"
    done

    echo ""
    echo "Available skills in Spine repo:"
    local available
    available="$(get_available_skills)"
    if [[ -z "$available" ]]; then
        echo "  (none found)"
    else
        echo "$available" | while read -r skill; do
            local marker=" "
            if [[ -L "$project_root/.agents/skills/$skill" ]]; then
                marker="✓"
            fi
            echo "  [$marker] $skill"
        done
    fi

    echo ""
    echo "==========================================="
}

# --- Add a single skill ---

add_skill() {
    local project_root="$1"
    local skill_name="$2"
    local source_dir="$SPINE_DIR/skills/$skill_name"

    if [[ ! -d "$source_dir" ]]; then
        echo "ERROR: Skill '$skill_name' not found in $SPINE_DIR/skills/" >&2
        echo "Available skills:" >&2
        get_available_skills >&2
        exit 1
    fi

    local agents_skills="$project_root/.agents/skills"
    local link_path="$agents_skills/$skill_name"
    local rel_target="../../.spine/skills/$skill_name"

    mkdir_p "$agents_skills"

    local rc
    create_relative_symlink "$rel_target" "$link_path" "skill: $skill_name"
    rc=$?

    echo ""
    echo "Skill '$skill_name' installed in .agents/skills/"
    echo "Restart your agent to pick up the new skill."
    return $rc
}

# --- Remove a single skill ---

remove_skill() {
    local project_root="$1"
    local skill_name="$2"
    local link_path="$project_root/.agents/skills/$skill_name"

    if [[ ! -L "$link_path" ]]; then
        echo "WARNING: '$skill_name' is not a symlink or not found in .agents/skills/" >&2
        return 1
    fi

    if $DRY_RUN; then
        echo "  [DRY-RUN] Would remove: $link_path"
    else
        rm "$link_path"
        log_linked "skill: $skill_name (removed)"
    fi
    return 0
}

# --- Project install summary ---

print_project_summary() {
    local project_root="$1"
    local skills_installed
    skills_installed="$(get_installed_skills "$project_root" | wc -l)"
    skills_installed="$(echo "$skills_installed" | tr -d ' ')"

    echo ""
    echo "==========================================="
    echo "  Spine Project Install Summary"
    echo "==========================================="
    echo ""
    echo "Detected OS: $OS"
    echo "Spine repo : $SPINE_DIR"
    echo "Project    : $project_root"
    echo "Targets    : $TARGETS"
    echo "Skills     : $skills_installed installed"
    echo ""
    echo "  Linked   : $LINKED"
    echo "  Skipped  : $SKIPPED (already correct)"
    echo "  Conflicts: $CONFLICTS"
    echo "  Warnings : $WARNINGS"
    echo ""

    if [[ $CONFLICTS -gt 0 ]]; then
        printf "\033[33m⚠ %d conflict(s) detected.\033[0m\n" "$CONFLICTS"
        echo "  Use --force to replace conflicting targets."
        echo ""
    fi

    if [[ $WARNINGS -gt 0 ]]; then
        printf "\033[33m⚠ %d warning(s) detected.\033[0m\n" "$WARNINGS"
        echo "  Use --force to replace mismatched symlinks."
        echo ""
    fi

    echo "Project structure:"
    echo "  .spine              -> (Spine repository)"
    echo "  .agents/skills/        (per-skill symlinks)"
    echo "  .claude/skills      -> .agents/skills/"
    echo "  .cursor/rules/         (per-file rule symlinks)"
    echo "  .cursor/commands/      (per-file command symlinks)"
    echo "  .cursor/skills      -> .agents/skills/"
    echo "  .opencode/commands/    (per-file command symlinks)"
    echo ""
    echo "  Rules:      opencode.json (GitHub URLs)"
    echo "  Skills:     docs/governance/skills-policy.md"
    echo ""
    echo "==========================================="
}

# ===========================================================================
# Main
# ===========================================================================

if $PROJECT_MODE; then
    # --- Project mode ---
    PROJECT_ROOT="$(find_project_root)"

    # Handle --list-skills
    if $LIST_SKILLS; then
        list_skills
        exit 0
    fi

    # Handle --add-skill
    if [[ -n "$ADD_SKILL" ]]; then
        add_skill "$PROJECT_ROOT" "$ADD_SKILL"
        exit $?
    fi

    # Handle --remove-skill
    if [[ -n "$REMOVE_SKILL" ]]; then
        remove_skill "$PROJECT_ROOT" "$REMOVE_SKILL"
        exit $?
    fi

    echo "Spine Project Installer"
    echo "Repository: $SPINE_DIR"
    echo "Project:    $PROJECT_ROOT"
    echo "Targets:    $TARGETS"
    echo "OS:         $OS"
    if $FORCE; then echo "Mode: force (will replace existing symlinks)"; fi
    if $DRY_RUN; then echo "Mode: dry-run (preview only)"; fi

    chmod_scripts

    # Resolve skill list
    SKILL_LIST="$(resolve_skills "${SKILLS_ARG:-all}")"

    echo ""
    echo "Skills to install:"
    echo "$SKILL_LIST" | while read -r skill; do
        [[ -n "$skill" ]] && echo "  - $skill"
    done

    # Ensure .spine symlink
    ensure_spine_symlink "$PROJECT_ROOT"

    # Parse targets
    INSTALL_CURSOR=false
    INSTALL_OPENCODE=false
    INSTALL_CLAUDE=false
    IFS=',' read -ra TARGET_ARRAY <<< "$TARGETS"
    for target in "${TARGET_ARRAY[@]}"; do
        case "$target" in
            cursor)   INSTALL_CURSOR=true ;;
            opencode) INSTALL_OPENCODE=true ;;
            claude)   INSTALL_CLAUDE=true ;;
            *)        echo "WARNING: Unknown target '$target', skipping" >&2 ;;
        esac
    done

    # Install skills (shared .agents/ hub)
    install_project_skills "$PROJECT_ROOT" "$SKILL_LIST"

    # Install per-tool symlinks
    if $INSTALL_CURSOR; then
        install_project_cursor "$PROJECT_ROOT"
    fi

    if $INSTALL_OPENCODE; then
        install_project_opencode "$PROJECT_ROOT"
    fi

    if $INSTALL_CLAUDE; then
        install_project_claude "$PROJECT_ROOT"
    fi

    # Add gitignore entries
    add_gitignore_entries "$PROJECT_ROOT"

    print_project_summary "$PROJECT_ROOT"

    if $DRY_RUN; then
        echo ""
        echo "This was a dry run. No changes were made."
        echo "Run without --dry-run to apply."
    fi

else
    # --- Global mode (default) ---
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
fi