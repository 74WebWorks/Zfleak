#!/usr/bin/env bash

# ============================================================================
# zfleak - Installation Script
# ============================================================================
# Installs the zfleak project environment manager
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

INSTALL_DIR="$HOME/.local"
BIN_DIR="$INSTALL_DIR/bin"
CONFIG_DIR="$HOME/.zfleak.d"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/74WebWorks/Zfleak.git"
TEMP_DIR=""

# Detect if running from remote install (script downloaded via curl/wget)
REMOTE_INSTALL=false
if [ -z "$SCRIPT_DIR" ] || [ "$SCRIPT_DIR" = "/" ] || [ ! -d "$SCRIPT_DIR/bin" ]; then
    REMOTE_INSTALL=true
fi

# Detect user's shell
USER_SHELL="$(basename "$SHELL")"
if [ "$USER_SHELL" = "zsh" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ "$USER_SHELL" = "bash" ]; then
    # Check for .bash_profile or .bashrc
    if [ -f "$HOME/.bash_profile" ]; then
        SHELL_RC="$HOME/.bash_profile"
    else
        SHELL_RC="$HOME/.bashrc"
    fi
else
    # Default to .bashrc for other shells
    SHELL_RC="$HOME/.bashrc"
fi

# ============================================================================
# Helper Functions
# ============================================================================

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}zfleak${NC} - Project Environment Manager            ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# ============================================================================
# Installation Steps
# ============================================================================

step_download_repo() {
    if [ "$REMOTE_INSTALL" = true ]; then
        echo -e "${CYAN}Downloading zfleak repository...${NC}"
        echo ""
        
        TEMP_DIR=$(mktemp -d)
        
        if command -v git &> /dev/null; then
            git clone --depth 1 "$REPO_URL" "$TEMP_DIR" 2>&1 | grep -v "Cloning into" || true
            SCRIPT_DIR="$TEMP_DIR"
            print_success "Downloaded repository using git"
        else
            print_error "git is not installed. Please install git or clone the repository manually."
            return 1
        fi
        
        echo ""
    fi
}

step_create_dirs() {
    echo -e "${CYAN}Creating directories...${NC}"
    echo ""
    
    mkdir -p "$BIN_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/.archive"
    
    print_success "Created $BIN_DIR"
    print_success "Created $CONFIG_DIR"
    echo ""
}

step_install_binary() {
    echo -e "${CYAN}Installing zfleak binary...${NC}"
    echo ""
    
    cp "$SCRIPT_DIR/bin/zfleak" "$BIN_DIR/zfleak"
    chmod +x "$BIN_DIR/zfleak"
    
    print_success "Installed zfleak to $BIN_DIR/zfleak"
    echo ""
}

step_install_library() {
    echo -e "${CYAN}Installing library files...${NC}"
    echo ""
    
    cp "$SCRIPT_DIR/lib/switcher.zsh" "$CONFIG_DIR/switcher.zsh"
    print_success "Installed switcher.zsh"
    
    # Install bash-compatible version if bash is detected or as fallback
    if [ -f "$SCRIPT_DIR/lib/switcher.bash" ]; then
        cp "$SCRIPT_DIR/lib/switcher.bash" "$CONFIG_DIR/switcher.bash"
        print_success "Installed switcher.bash"
    fi
    
    echo ""
}

step_create_template() {
    echo -e "${CYAN}Creating template files...${NC}"
    echo ""
    
    # Create common.zsh if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/common.zsh" ]]; then
        cat > "$CONFIG_DIR/common.zsh" << 'EOF'
# ============================================================================
# Common Settings (Shared Across All Projects)
# ============================================================================

# Add any settings that should be available to all projects here
EOF
        print_success "Created common.zsh"
    else
        print_warning "common.zsh already exists, skipping"
    fi
    
    # Create projects.conf if it doesn't exist
    if [[ ! -f "$CONFIG_DIR/projects.conf" ]]; then
        touch "$CONFIG_DIR/projects.conf"
        print_success "Created projects.conf"
    else
        print_warning "projects.conf already exists, skipping"
    fi
    
    echo ""
}

step_update_shell_config() {
    echo -e "${CYAN}Updating shell configuration...${NC}"
    echo ""
    
    local zfleak_block="# zfleak - Project Environment Manager"
    
    # Check if already configured
    if grep -q "$zfleak_block" "$SHELL_RC" 2>/dev/null; then
        print_warning "zfleak already configured in $SHELL_RC"
    else
        # Determine which switcher file to source
        local switcher_file="switcher.zsh"
        if [ "$USER_SHELL" = "bash" ]; then
            switcher_file="switcher.bash"
        fi
        
        # Add to shell RC file
        cat >> "$SHELL_RC" << EOF

# zfleak - Project Environment Manager
export PATH="\$HOME/.local/bin:\$PATH"
[[ -f "\$HOME/.zfleak.d/$switcher_file" ]] && source "\$HOME/.zfleak.d/$switcher_file"
EOF
        print_success "Added zfleak to $SHELL_RC"
    fi
    
    echo ""
}

step_verify_installation() {
    echo -e "${CYAN}Verifying installation...${NC}"
    echo ""
    
    if [[ -x "$BIN_DIR/zfleak" ]]; then
        print_success "zfleak binary is executable"
    else
        print_error "zfleak binary is not executable"
        return 1
    fi
    
    local switcher_check="$CONFIG_DIR/switcher.zsh"
    if [ "$USER_SHELL" = "bash" ] && [ -f "$CONFIG_DIR/switcher.bash" ]; then
        switcher_check="$CONFIG_DIR/switcher.bash"
    fi
    
    if [[ -f "$switcher_check" ]]; then
        print_success "Switcher library installed"
    else
        print_error "Switcher library not found"
        return 1
    fi
    
    echo ""
}

step_cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        echo -e "${CYAN}Cleaning up temporary files...${NC}"
        rm -rf "$TEMP_DIR"
        print_success "Cleanup complete"
        echo ""
    fi
}

show_completion() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}  ${CYAN}Installation Complete!${NC}                              ${GREEN}║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo ""
    echo "1. Reload your shell:"
    echo -e "   ${CYAN}source $SHELL_RC${NC}"
    echo ""
    echo "2. Create your first project:"
    echo -e "   ${CYAN}zfleak new-project myapp ~/projects/myapp${NC}"
    echo ""
    echo "3. Edit the configuration:"
    echo -e "   ${CYAN}zfleak edit myapp${NC}"
    echo ""
    echo "4. Navigate to your project:"
    echo -e "   ${CYAN}cd ~/projects/myapp${NC}"
    echo ""
    echo "5. Get help anytime:"
    echo -e "   ${CYAN}zfleak help${NC}"
    echo ""
    echo -e "${CYAN}Documentation:${NC} https://github.com/74WebWorks/Zfleak"
    echo -e "${CYAN}Detected shell:${NC} $USER_SHELL"
    echo ""
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    print_header
    
    echo -e "${YELLOW}This will install zfleak - Project Environment Manager${NC}"
    echo ""
    echo "Installation paths:"
    echo "  Binary:  $BIN_DIR/zfleak"
    echo "  Config:  $CONFIG_DIR"
    echo "  Shell:   $USER_SHELL"
    echo "  RC File: $SHELL_RC"
    
    if [ "$REMOTE_INSTALL" = true ]; then
        echo "  Mode:    Remote installation"
    fi
    
    echo ""
    echo -n "Continue with installation? (y/n) "
    read REPLY
    echo ""
    
    case "$REPLY" in
        [Yy]|[Yy][Ee][Ss])
            # Continue with installation
            ;;
        *)
            echo "Installation cancelled"
            exit 0
            ;;
    esac
    
    echo ""
    
    step_download_repo
    step_create_dirs
    step_install_binary
    step_install_library
    step_create_template
    step_update_shell_config
    step_verify_installation
    step_cleanup
    show_completion
}

main "$@"
