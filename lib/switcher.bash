# ============================================================================
# zfleak Project Environment Switcher (Bash)
# ============================================================================
# Automatic detection based on current directory and manual switching
# Usage:
#   use-project <name>    - Manually switch to a project
#   list-projects         - List all available projects
#   clear-project         - Clear current project environment
#   current-project       - Show currently active project
# ============================================================================

# Track loaded environment variables for cleanup
declare -A LOADED_ENV_VARS

# Store current project
export ACTIVE_PROJECT=""

# Configuration directory
CONFIG_DIR="${ZFLEAK_CONFIG_DIR:-$HOME/.zfleak.d}"
ARCHIVE_DIR="$CONFIG_DIR/.archive"
PROJECTS_CONFIG="$CONFIG_DIR/projects.conf"

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
        echo "🔄 Loading project: $project"
        source "$config_file"
        export ACTIVE_PROJECT="$project"
        echo "✅ Loaded active project: $project"
        _track_project_vars "$config_file"
        return 0
    # Try archived configs
    elif [[ -f "$archive_file" ]]; then
        echo "🔄 Loading archived project: $project"
        source "$archive_file"
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
            [[ "$file" == *"switcher.bash" ]] && continue
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
            local var_name="${BASH_REMATCH[1]}"
            LOADED_ENV_VARS[$var_name]=1
        fi
    done < "$config_file"
}

# ============================================================================
# Internal: Clear loaded environment variables
# ============================================================================
_clear_project_env() {
    for var in "${!LOADED_ENV_VARS[@]}"; do
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
            
            # Check if current directory matches project path
            if [[ "$current_dir" == "$project_path"* ]]; then
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

# ============================================================================
# Hook into directory changes (Bash version using PROMPT_COMMAND)
# ============================================================================
_zfleak_last_dir="$PWD"

_zfleak_chpwd_hook() {
    if [[ "$PWD" != "$_zfleak_last_dir" ]]; then
        _zfleak_last_dir="$PWD"
        _auto_detect_project
    fi
}

# Add to PROMPT_COMMAND if not already there
if [[ "$PROMPT_COMMAND" != *"_zfleak_chpwd_hook"* ]]; then
    PROMPT_COMMAND="_zfleak_chpwd_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

# Run detection on shell startup
_auto_detect_project
