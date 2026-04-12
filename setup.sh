#!/bin/bash
# Thingino Development Environment Setup Script
# This script prepares a Linux environment for Thingino firmware development.

set -e

# --- Configuration ---
WORKSPACE_DIR="${HOME}/thingino-workspace"
FIRMWARE_REPO="https://github.com/themactep/thingino-firmware.git"
INSTALL_BASE="${HOME}/opt/toolchains"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================================${NC}"
echo -e "${BLUE}   Thingino Development Environment Bootstrapper      ${NC}"
echo -e "${BLUE}=======================================================${NC}"

# 1. Install System Dependencies
echo -e "\n${GREEN}[1/5] Installing system dependencies...${NC}"
# Detect package manager
if command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        git \
        wget \
        curl \
        python3 \
        python3-pip \
        libncurses5-dev \
        gawk \
        gettext \
        unzip \
        file \
        libssl-dev \
        rsync \
        u-boot-tools \
        podman \
        qemu-system-misc \
        qemu-user-static \
        bc \
        cpio
elif command -v pacman &>/dev/null; then
    sudo pacman -Syu --needed --noconfirm \
        base-devel \
        git \
        wget \
        curl \
        python \
        python-pip \
        ncurses \
        gawk \
        gettext \
        unzip \
        file \
        openssl \
        rsync \
        uboot-tools \
        podman \
        qemu-headless \
        qemu-user-static \
        bc \
        cpio
else
    echo -e "${RED}Warning: Unknown package manager. Please install dependencies manually:${NC}"
    echo "build-essential, git, wget, curl, python3, ncurses-dev, gawk, gettext, unzip, file, libssl-dev, rsync, u-boot-tools, podman, qemu"
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
echo -e "\n${GREEN}[3/5] Cloning thingino-firmware repository...${NC}"
if [ ! -d "$WORKSPACE_DIR/thingino-firmware" ]; then
    git clone "$FIRMWARE_REPO" "$WORKSPACE_DIR/thingino-firmware"
else
    echo "thingino-firmware already exists in workspace. Skipping clone."
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

echo -e "\n${BLUE}=======================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "Your workspace is at: ${WORKSPACE_DIR}"
echo -e "To start developing:"
echo -e "  1. source ~/.thingino_config"
echo -e "  2. cd ${WORKSPACE_DIR}/thingino-firmware"
echo -e "  3. make help"
echo -e "${BLUE}=======================================================${NC}"
