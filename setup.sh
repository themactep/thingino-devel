#!/bin/bash
# Thingino Development Environment Setup Script
# This script prepares a Linux environment for Thingino firmware development.

set -e

# --- Configuration ---
WORKSPACE_DIR="${HOME}/thingino-workspace"
FIRMWARE_REPO="https://github.com/themactep/thingino-firmware.git"
INSTALL_BASE="${WORKSPACE_DIR}/toolchains"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}   Thingino Development Environment Bootstrapper      ${NC}"
echo -e "${BLUE}=======================================================${NC}"

# 1. Install System Dependencies
echo -e "\n${GREEN}[1/5] Checking and installing system dependencies...${NC}"
if [ -f "./install_deps.sh" ]; then
    bash ./install_deps.sh
else
    echo -e "${RED}Error: install_deps.sh not found!${NC}"
    exit 1
fi

# 2. Create Workspace
echo -e "\n${GREEN}[2/5] Setting up workspace directory...${NC}"
if [ ! -d "$WORKSPACE_DIR" ]; then
    mkdir -p "$WORKSPACE_DIR"
    echo "Created $WORKSPACE_DIR"
else
    echo "Workspace $WORKSPACE_DIR already exists."
fi

# 3. Clone Thingino Firmware
echo -e "\n${GREEN}[3/5] Cloning thingino-firmware repository with submodules...${NC}"
if [ ! -d "$WORKSPACE_DIR/firmware" ]; then
    git clone --recursive "$FIRMWARE_REPO" "$WORKSPACE_DIR/firmware"
else
    echo "firmware directory already exists in workspace. Skipping clone."
fi

# 4. Bootstrap Toolchains
echo -e "\n${GREEN}[4/5] Bootstrapping toolchains...${NC}"
if [ -f "./bootstrap_thingino_toolchains.sh" ]; then
    bash ./bootstrap_thingino_toolchains.sh
else
    echo -e "${RED}Error: bootstrap_thingino_toolchains.sh not found!${NC}"
    exit 1
fi

# 5. Finalize Configuration
echo -e "\n${GREEN}[5/5] Finalizing setup...${NC}"
if [ -f "./select_toolchain.sh" ]; then
    echo "Running toolchain selector..."
    bash ./select_toolchain.sh
fi

# Add to shell profile
echo -e "\nWould you like to automatically source ~/.thingino_config in your shell profile? (y/n)"
read -r add_to_profile
if [[ "$add_to_profile" =~ ^[Yy]$ ]]; then
    SHELL_RC=""
    if [ -n "$ZSH_VERSION" ] || [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ] || [ -f "$HOME/.bashrc" ]; then
        SHELL_RC="$HOME/.bashrc"
    fi

    if [ -n "$SHELL_RC" ]; then
        if ! grep -q "source ~/.thingino_config" "$SHELL_RC"; then
            echo -e "\n# Thingino environment" >> "$SHELL_RC"
            echo "[[ -f ~/.thingino_config ]] && source ~/.thingino_config" >> "$SHELL_RC"
            echo -e "${GREEN}Added to $SHELL_RC${NC}"
        else
            echo -e "Already exists in $SHELL_RC"
        fi
    else
        echo -e "${RED}Could not find .bashrc or .zshrc. Please add 'source ~/.thingino_config' manually.${NC}"
    fi
fi

echo -e "\n${BLUE}=======================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "Your workspace is at: ${WORKSPACE_DIR}"
echo -e "To start developing:"
if [[ "$add_to_profile" =~ ^[Yy]$ ]]; then
    echo -e "  1. source ~/.thingino_config (only for this shell; automatic in future)"
else
    echo -e "  1. source ~/.thingino_config"
fi
echo -e "  2. cd ${WORKSPACE_DIR}/firmware"
echo -e "  3. make help"
echo -e "${BLUE}=======================================================${NC}"
