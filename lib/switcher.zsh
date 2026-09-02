# ============================================================================
# zfleak Project Environment Switcher
# ============================================================================
# Automatic detection based on current directory and manual switching
# Usage:
#   use-project <name>    - Manually switch to a project
#   list-projects         - List all available projects
#   clear-project         - Clear current project environment
#   current-project       - Show currently active project
# ============================================================================

# Track loaded environment variables for cleanup
typeset -gA LOADED_ENV_VARS

# Store current project
export ACTIVE_PROJECT=""

source "$(cd "$(dirname "${(%):-%N}")" && pwd)/vault.sh"

# Configuration directory
CONFIG_DIR="${ZFLEAK_CONFIG_DIR:-$HOME/.zfleak.d}"
ARCHIVE_DIR="$CONFIG_DIR/.archive"
PROJECTS_CONFIG="$CONFIG_DIR/projects.conf"

# ============================================================================
# Internal: block loading of projects marked ZFLEAK_SENSITIVE=true
# ============================================================================
_zfleak_confirm_load() {
    local file=$1
    grep -q '^export ZFLEAK_SENSITIVE=true' "$file" 2>/dev/null || return 0

    echo "❌ '$file' is marked SENSITIVE (production credentials)."
    echo "   use-project cannot load sensitive projects directly."
    echo "   Use: zfleak run <project> -- <command...>"
    return 1
}

# ============================================================================
# Manual Project Switcher
# ============================================================================
use-project() {
    local project=$1
    
    if [[ -z "$project" ]]; then
        echo "Usage: use-project <project-name>"
        echo ""
        list-projects
        return 1
    fi
    
    local config_file="$CONFIG_DIR/${project}.zsh"
    local archive_file="$ARCHIVE_DIR/${project}.zsh"
    
    # Clear previous project environment
    if [[ -n "$ACTIVE_PROJECT" ]]; then
        _clear_project_env
    fi
    
    # Try active configs first
    if [[ -f "$config_file" ]]; then
        _zfleak_confirm_load "$config_file" || return 1
        echo "🔄 Loading project: $project"
        source "$config_file"
        _zfleak_resolve_secret_refs "$config_file" || return 1
        export ACTIVE_PROJECT="$project"
        echo "✅ Loaded active project: $project"
        _track_project_vars "$config_file"
        return 0
    # Try archived configs
    elif [[ -f "$archive_file" ]]; then
        _zfleak_confirm_load "$archive_file" || return 1
        echo "🔄 Loading archived project: $project"
        source "$archive_file"
        _zfleak_resolve_secret_refs "$archive_file" || return 1
        export ACTIVE_PROJECT="$project (archived)"
        echo "✅ Loaded archived project: $project"
        _track_project_vars "$archive_file"
        return 0
    else
        echo "❌ Project '$project' not found"
        echo ""
        list-projects
        return 1
    fi
}

# ============================================================================
# List Available Projects
# ============================================================================
list-projects() {
    echo "📋 Available Projects:"
    echo ""
    echo "Active Projects:"
    if ls "$CONFIG_DIR"/*.zsh &>/dev/null; then
        for file in "$CONFIG_DIR"/*.zsh; do
            [[ "$file" == *"switcher.zsh" ]] && continue
            [[ "$file" == *"common.zsh" ]] && continue
            local name=$(basename "$file" .zsh)
            echo "  • $name"
        done
    else
        echo "  (none)"
    fi
    
    echo ""
    echo "Archived Projects:"
    if ls "$ARCHIVE_DIR"/*.zsh &>/dev/null; then
        for file in "$ARCHIVE_DIR"/*.zsh; do
            local name=$(basename "$file" .zsh)
            echo "  • $name"
        done
    else
        echo "  (none)"
    fi
    
    if [[ -n "$ACTIVE_PROJECT" ]]; then
        echo ""
        echo "Current: $ACTIVE_PROJECT"
    fi
}

# ============================================================================
# Show Current Project
# ============================================================================
current-project() {
    if [[ -n "$ACTIVE_PROJECT" ]]; then
        echo "Current project: $ACTIVE_PROJECT"
    else
        echo "No project currently loaded"
    fi
}

# ============================================================================
# Clear Project Environment
# ============================================================================
clear-project() {
    if [[ -z "$ACTIVE_PROJECT" ]]; then
        echo "ℹ️  No project currently loaded"
        return 0
    fi
    
    echo "🔄 Clearing project: $ACTIVE_PROJECT"
    _clear_project_env
    export ACTIVE_PROJECT=""
    echo "✅ Project environment cleared"
}

# ============================================================================
# Internal: Track loaded environment variables
# ============================================================================
_track_project_vars() {
    local config_file=$1
    
    # Extract exported variables from the config file
    while IFS= read -r line; do
        if [[ "$line" =~ ^export[[:space:]]+([A-Z_][A-Z0-9_]*)= ]]; then
            local var_name="${match[1]}"
            LOADED_ENV_VARS[$var_name]=1
        fi
    done < "$config_file"
}

# ============================================================================
# Internal: Resolve `# zfleak:secret VAR=<vault-key>` references
# ============================================================================
_zfleak_resolve_secret_refs() {
    local config_file=$1
    local var_name vault_key value
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^#[[:space:]]*zfleak:secret[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=(.+)$ ]]; then
            var_name="${match[1]}"
            vault_key="${match[2]}"
            if ! value="$(_vault_get "$vault_key")"; then
                echo "❌ Failed to resolve secret '$vault_key' for \$$var_name" >&2
                return 1
            fi
            export "$var_name=$value"
            LOADED_ENV_VARS[$var_name]=1
        fi
    done < "$config_file"
}

# ============================================================================
# Internal: Clear loaded environment variables
# ============================================================================
_clear_project_env() {
    for var in "${(@k)LOADED_ENV_VARS}"; do
        unset "$var"
    done
    LOADED_ENV_VARS=()
}

# ============================================================================
# Automatic Project Detection (Dynamic)
# ============================================================================
_auto_detect_project() {
    local current_dir="$PWD"
    local detected_project=""
    
    # Check registered project paths from projects.conf
    if [[ -f "$PROJECTS_CONFIG" ]]; then
        while IFS=: read -r project_name project_path; do
            # Skip empty lines and comments
            [[ -z "$project_name" || "$project_name" == \#* ]] && continue
            
            # Expand ~ to home directory
            project_path="${project_path/#\~/$HOME}"
            
            # Check if current directory matches project path (exact
            # match, or a real subdirectory of it — not just a string
            # prefix, so "work/app-fork" doesn't match "work/app")
            if [[ "$current_dir" == "$project_path" || "$current_dir" == "$project_path"/* ]]; then
                detected_project="$project_name"
                break
            fi
        done < "$PROJECTS_CONFIG"
    fi
    
    # Only auto-load if different from current project
    if [[ -n "$detected_project" && "$detected_project" != "$ACTIVE_PROJECT" ]]; then
        local config_file="$CONFIG_DIR/${detected_project}.zsh"
        local archive_file="$ARCHIVE_DIR/${detected_project}.zsh"
        
        if [[ -f "$config_file" ]] || [[ -f "$archive_file" ]]; then
            echo ""
            echo "🔍 Detected project: $detected_project"
            echo "💡 Loading environment automatically..."
            use-project "$detected_project"
        else
            echo ""
            echo "🔍 Detected project directory: $detected_project"
            echo "⚠️  No configuration found for this project"
            echo "💡 Run: zfleak new-project $detected_project $current_dir"
            echo "   to create a configuration for this project"
        fi
    fi
}

# Hook into directory changes
autoload -U add-zsh-hook
add-zsh-hook chpwd _auto_detect_project

# Run detection on shell startup
_auto_detect_project
