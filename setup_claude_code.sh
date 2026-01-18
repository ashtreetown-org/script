#!/bin/bash

# =================================================================
# Script Name: setup_claude_code.sh
# Description: Script to install Claude Code CLI
# OS: Linux_x86_64, Linux_arm64, macOS_x86_64, macOS_arm64
# Date: 2026-01-16
# =================================================================

set -e

# Define Installation Paths
CLAUDE_DIR="$HOME/.claude"
# The official installer determines the bin path, usually ~/.claude/bin or similar, 
# but it also modifies the shell rc files.
SHELL_CONFIGS=("$HOME/.bashrc" "$HOME/.zshrc")

install_claude() {
    # 1. Check for prerequisites
    if ! command -v curl >/dev/null 2>&1; then
        echo "Error: curl is not installed. Please install curl first."
        exit 1
    fi
    echo "Prerequisites checked."

    # 2. Download and Install
    echo "Installing Claude Code..."
    # Using the official native installer
    curl -fsSL https://claude.ai/install.sh | bash

    echo "--------------------------------------------------"
    echo "Claude Code installation completed!"
    echo "Please restart your shell or run 'source <shell_config>' to start using it."
    echo "--------------------------------------------------"
}

uninstall_claude() {
    echo "Uninstalling Claude Code..."

    # 1. Remove the directory
    if [ -d "$CLAUDE_DIR" ]; then
        rm -rf "$CLAUDE_DIR"
        echo "Removed directory: $CLAUDE_DIR"
    else
        echo "Directory not found: $CLAUDE_DIR"
    fi

    # 2. Try to remove the binary if it's in a common location not covered by the dir?
    # The official installer usually puts everything in ~/.claude.
    
    # 3. Clean up shell configs
    echo "Removing configuration from shell files..."
    USER_REMOVED_CONFIG=false

    # The official installer adds a block. We need to identify it.
    # Typically it adds:
    # # claude-code
    # export PATH=...
    # or sourcing a env file.
    
    # Since we can't be 100% sure what the current version of the installer writes exacty without running it,
    # we will look for common markers. 
    # Based on research, it might add something to PATH.
    
    for CONF in "${SHELL_CONFIGS[@]}"; do
        if [ -f "$CONF" ]; then
            # We'll look for lines containing ".claude" to be safe and conservative,
            # asking the user to confirm might be too interactive for a simple script, 
            # but we can try to be smart.
            
            # Common pattern for these tools is to add a comment block.
            # If we find "claude" related exports, we try to remove them.
            
            # Using a simplified approach: warn the user about shell config.
            # Automated removal of shell config lines is risky if we don't know the EXACT pattern.
            # However, the user requirement asks for uninstall function.
            
            # Let's try to find lines referencing the installation dir.
            if grep -q "$CLAUDE_DIR" "$CONF"; then
                echo "Found Claude Code configuration in $CONF."
                # Construct a backup
                cp "$CONF" "${CONF}.bak"
                echo "Backed up $CONF to ${CONF}.bak"
                
                # Remove lines containing the CLAUDE_DIR
                # This is a bit aggressive but effectively removes the path addition.
                grep -v "$CLAUDE_DIR" "${CONF}.bak" > "$CONF"
                
                echo "Removed lines containing '$CLAUDE_DIR' from $CONF"
                USER_REMOVED_CONFIG=true
            fi
        fi
    done

    if [ "$USER_REMOVED_CONFIG" = false ]; then
         echo "No configuration found to remove in standard shell files."
    else
         echo "Shell configuration updated. Please verify ${SHELL_CONFIGS[*]} if necessary."
    fi

    echo "Claude Code uninstallation completed."
}

repair_claude() {
    echo "Repairing Claude Code..."
    uninstall_claude
    install_claude
}

config_router() {
    echo "Configuring Claude Code Router..."

    # 1. Prompt for ANTHROPIC_BASE_URL
    read -p "Enter ANTHROPIC_BASE_URL: " BASE_URL
    if [ -z "$BASE_URL" ]; then
        echo "Error: ANTHROPIC_BASE_URL cannot be empty."
        return
    fi

    # 2. Prompt for ANTHROPIC_AUTH_TOKEN
    read -p "Enter ANTHROPIC_AUTH_TOKEN: " AUTH_TOKEN
    if [ -z "$AUTH_TOKEN" ]; then
        echo "Error: ANTHROPIC_AUTH_TOKEN cannot be empty."
        return
    fi

    # 3. Write to shell config files
    for CONF in "${SHELL_CONFIGS[@]}"; do
        if [ -f "$CONF" ]; then
            echo "Checking $CONF..."

            MISSING_URL=false
            if ! grep -q "export ANTHROPIC_BASE_URL=" "$CONF"; then MISSING_URL=true; fi

            MISSING_TOKEN=false
            if ! grep -q "export ANTHROPIC_AUTH_TOKEN=" "$CONF"; then MISSING_TOKEN=true; fi

            if [ "$MISSING_URL" = true ] || [ "$MISSING_TOKEN" = true ]; then
                echo "" >> "$CONF"
                echo "# Claude Code" >> "$CONF"

                if [ "$MISSING_URL" = true ]; then
                    echo "export ANTHROPIC_BASE_URL=\"$BASE_URL\"" >> "$CONF"
                    echo "Added ANTHROPIC_BASE_URL to $CONF"
                else
                    echo "Warning: ANTHROPIC_BASE_URL is already defined in $CONF. Skipping."
                fi

                if [ "$MISSING_TOKEN" = true ]; then
                    echo "export ANTHROPIC_AUTH_TOKEN=\"$AUTH_TOKEN\"" >> "$CONF"
                    echo "Added ANTHROPIC_AUTH_TOKEN to $CONF"
                else
                    echo "Warning: ANTHROPIC_AUTH_TOKEN is already defined in $CONF. Skipping."
                fi
            else
                echo "Configuration already exists in $CONF."
            fi
        fi
    done
    
    echo "--------------------------------------------------"
    echo "Configuration completed!"
    echo "Please restart your shell or run 'source <shell_config>' to apply changes."
    echo "--------------------------------------------------"
}

# Main Menu
echo "Choose an option:"
echo "1. install (default)"
echo "2. uninstall"
echo "3. repair"
echo "4. configure claude-code-router"
read -p "Enter selection [1]: " CHOICE
CHOICE=${CHOICE:-1}

case "$CHOICE" in
    1)
        install_claude
        ;;
    2)
        uninstall_claude
        ;;
    3)
        repair_claude
        ;;
    4)
        config_router
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
