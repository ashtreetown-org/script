#!/bin/bash

# =================================================================
# Script Name: setup_docker.sh
# Description: Automated Docker installation/management script
# OS: Linux_x86_64, Linux_arm64, macOS_x86_64, macOS_arm64
# Date: 2026-01-07
# =================================================================

set -e

# 1. Detect OS and Architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Linux)     OS_TYPE="linux" ;;
    Darwin)    OS_TYPE="darwin" ;;
    *)         echo "Error: Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
    x86_64)          ARCH_TYPE="amd64" ;;
    aarch64|arm64)   ARCH_TYPE="arm64" ;;
    *)               echo "Error: Unsupported Architecture: $ARCH"; exit 1 ;;
esac

echo "Detected Platform: $OS_TYPE/$ARCH_TYPE"

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

install_docker() {
    echo "Installing Docker..."
    if [ "$OS_TYPE" = "linux" ]; then
        if command_exists docker; then
            echo "Docker is already installed."
            docker --version
            return
        fi

        echo "Using official Docker installation script (requires root/sudo)..."
        curl -fsSL https://get.docker.com |sh
        
        echo "Docker installed successfully."
        
        # Post-install steps for Linux (optional but recommended for convenience)
        if ! getent group docker > /dev/null 2>&1; then
             sudo groupadd docker || true
        fi
        
        # Check if current user is already in docker group to avoid re-adding
        if ! groups "$USER" | grep -q "\bdocker\b"; then
            echo "Adding current user ($USER) to 'docker' group to run without sudo..."
            sudo usermod -aG docker "$USER"
            echo "You may need to log out and back in for this to take effect."
        fi

    elif [ "$OS_TYPE" = "darwin" ]; then
        if command_exists docker; then
            echo "Docker is already installed."
            docker --version
            return
        fi

        if ! command_exists brew; then
            echo "Error: Homebrew is required for macOS installation."
            echo "Please install Homebrew first: https://brew.sh/"
            exit 1
        fi

        echo "Installing Docker Desktop via Homebrew..."
        brew install --cask docker
        
        echo "Docker Desktop installed. Please launch it from Applications to finish setup."
    fi
}

uninstall_docker() {
    echo "Uninstalling Docker..."
    if [ "$OS_TYPE" = "linux" ]; then
        echo "Attempting to remove Docker packages..."
        if command_exists apt-get; then
             sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true
             sudo apt-get autoremove -y || true
             sudo rm -rf /var/lib/docker
             sudo rm -rf /var/lib/containerd
        elif command_exists yum; then
             sudo yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true
             sudo rm -rf /var/lib/docker
             sudo rm -rf /var/lib/containerd
        elif command_exists dnf; then
             sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras || true
             sudo rm -rf /var/lib/docker
             sudo rm -rf /var/lib/containerd
        else
            echo "Could not detect package manager (apt/yum/dnf). Please uninstall manually."
        fi
        echo "Docker uninstalled."
    elif [ "$OS_TYPE" = "darwin" ]; then
        echo "Uninstalling Docker Desktop via Homebrew..."
        brew uninstall --cask docker || echo "Docker cask not found or already removed."
        echo "You may need to manually remove configuration files at ~/.docker and ~/Library/Containers/com.docker.docker"
    fi
}

repair_docker() {
    echo "Repairing Docker environment..."
    uninstall_docker
    install_docker
    echo "Repair complete."
}

echo "=========================================="
echo " Docker Setup Script"
echo "=========================================="
echo "1. install (default)"
echo "2. uninstall"
echo "3. repair"
read -p "Enter selection [1]: " CHOICE
CHOICE=${CHOICE:-1}

case "$CHOICE" in
    1)
        install_docker
        ;;
    2)
        uninstall_docker
        ;;
    3)
        repair_docker
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac
