#!/usr/bin/env bash
# =================================================================
# Script Name: setup_opencode.sh
# Description: Deploy OpenCode AI coding assistant
# OS: Linux_x86_64, Linux_arm64, macOS_x86_64, macOS_arm64
# Date: 2026-01-18
# =================================================================

set -u

# Function to print colored messages
print_message() {
    local level=$1
    local message=$2
    local color=""
    local NC='\033[0m'

    case $level in
        info) color='\033[0;32m' ;; # Green
        warning) color='\033[0;33m' ;; # Yellow
        error) color='\033[0;31m' ;; # Red
    esac

    echo -e "${color}${message}${NC}"
}

# Function to install OpenCode
install_opencode() {
    print_message info "Starting OpenCode installation..."
    
    # Run the official installer but prevent it from modifying shell config automatically
    # We want to handle that to avoid duplicates as per requirements
    if curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; then
        print_message info "OpenCode binary installed successfully."
        
        # Post-install environment configuration
        INSTALL_DIR="$HOME/.opencode/bin"
        SHELL_CONFIG=""
        
        # Detect shell configuration file based on user's default shell and file existence
        # We cannot rely on ZSH_VERSION/BASH_VERSION because this script runs in bash
        if [[ "$SHELL" == *"zsh"* ]] || [ -f "$HOME/.zshrc" ]; then
            SHELL_CONFIG="$HOME/.zshrc"
        elif [[ "$SHELL" == *"bash"* ]] || [ -f "$HOME/.bashrc" ]; then
            SHELL_CONFIG="$HOME/.bashrc"
        fi

        # If both exist, we might want to be smarter, but usually on macOS .zshrc is key.
        # If the specific shell config file doesn't exist but we detected the shell, create it?
        # The requirements say "user may have already correctly configured... avoid duplicate". 
        # If it doesn't exist, we can't really "duplicate" it, so appending is fine (creating it).
        
        # Refined logic: Priority to zshrc on macOS/zsh users, then bashrc.
        if [ -n "${ZSH_VERSION:-}" ] || [[ "$SHELL" == *"zsh"* ]] && [ -f "$HOME/.zshrc" ]; then
             SHELL_CONFIG="$HOME/.zshrc"
        elif [ -n "${BASH_VERSION:-}" ] || [[ "$SHELL" == *"bash"* ]] && [ -f "$HOME/.bashrc" ]; then
             SHELL_CONFIG="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
             SHELL_CONFIG="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
             SHELL_CONFIG="$HOME/.bashrc"
        else
             SHELL_CONFIG=""
        fi

        if [ -n "$SHELL_CONFIG" ] && [ -f "$SHELL_CONFIG" ]; then
             if ! grep -q "$INSTALL_DIR" "$SHELL_CONFIG"; then
                print_message info "Adding $INSTALL_DIR to PATH in $SHELL_CONFIG"
                echo "# OpenCode Path" >> "$SHELL_CONFIG"
                echo "export PATH=\"\$PATH:$INSTALL_DIR\"" >> "$SHELL_CONFIG"
             else
                print_message warning "OpenCode path already exists in $SHELL_CONFIG. Skipping."
             fi
        else
             print_message warning "Could not detect shell configuration file. Please manually add $INSTALL_DIR to your PATH."
        fi
        
        print_message info "Installation complete. Please restart your shell or run 'source $SHELL_CONFIG' to use 'opencode'."
    else
        print_message error "Installation failed."
        exit 1
    fi
}

# Function to uninstall OpenCode
uninstall_opencode() {
    print_message info "Uninstalling OpenCode..."
    
    INSTALL_DIR="$HOME/.opencode"
    
    if [ -d "$INSTALL_DIR" ]; then
        rm -rf "$INSTALL_DIR"
        print_message info "Removed directory: $INSTALL_DIR"
    else
        print_message warning "Directory $INSTALL_DIR not found."
    fi
    
    print_message warning "Please manually remove any OpenCode related lines (e.g., export PATH=.../.opencode/bin) from your shell configuration files (.zshrc, .bashrc, etc.)."
    print_message info "Uninstallation complete."
}

# Function to repair OpenCode
repair_opencode() {
    print_message info "Repairing OpenCode..."
    uninstall_opencode
    install_opencode
    print_message info "Repair complete."
}

# Main menu
echo "Please choose an action:"
echo "1. Install (default)"
echo "2. Uninstall"
echo "3. Repair"
read -r -p "Enter number [1]: " choice

choice=${choice:-1}

case "$choice" in
    1)
        install_opencode
        ;;
    2)
        uninstall_opencode
        ;;
    3)
        repair_opencode
        ;;
    *)
        print_message error "Invalid choice. Exiting."
        exit 1
        ;;
esac
