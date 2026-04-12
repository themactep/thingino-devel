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
echo -e "\n${GREEN}[1/5] Installing system dependencies...${NC}"
# Detect package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID_LIKE" in
        *debian*)
            sudo apt-get update
            sudo apt-get install -y \
                autoconf build-essential bc bison ccache cpio cmake curl dialog file flex gawk git \
                libncurses-dev libusb-1.0-0-dev make m4 nano perl python3 python3-pip python3-jsonschema \
                rsync unzip u-boot-tools vim-tiny wget whiptail podman qemu-system-misc qemu-user-static
            ;;
        *)
            case "$ID" in
                ubuntu|debian|linuxmint|zorin)
                    sudo apt-get update
                    sudo apt-get install -y \
                        autoconf build-essential bc bison ccache cpio cmake curl dialog file flex gawk git \
                        libncurses-dev libusb-1.0-0-dev make m4 nano perl python3 python3-pip python3-jsonschema \
                        rsync unzip u-boot-tools vim-tiny wget whiptail podman qemu-system-misc qemu-user-static
                    ;;
                arch)
                    sudo pacman -Syu --needed --noconfirm \
                        autoconf base-devel bc bison cpio cmake curl dialog file flex gawk git \
                        m4 libnewt libusb make nano ncurses perl python python-pip rsync unzip \
                        uboot-tools wget podman qemu-base qemu-user-static
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y \
                        autoconf gcc m4 make bc bison cpio cmake curl dialog file flex gawk git \
                        nano ncurses-devel newt libusbx-devel perl rsync unzip uboot-tools wget \
                        podman qemu-system-x86 qemu-user-static
                    ;;
                alpine)
                    sudo apk add \
                        autoconf bash build-base bc bison cpio cmake curl dialog file findutils \
                        flex gawk git grep m4 nano ncurses-dev newt libusb-dev make perl rsync \
                        unzip uboot-tools wget podman qemu-system-x86_64 qemu-user-static
                    ;;
                *)
                    echo -e "${RED}Warning: Unsupported OS: $ID. Please install dependencies manually.${NC}"
                    ;;
            esac
            ;;
    esac
else
    echo -e "${RED}Warning: Could not determine the operating system. Please install dependencies manually.${NC}"
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
if [ ! -d "$WORKSPACE_DIR/firmware" ]; then
    git clone "$FIRMWARE_REPO" "$WORKSPACE_DIR/firmware"
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

echo -e "\n${BLUE}=======================================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "Your workspace is at: ${WORKSPACE_DIR}"
echo -e "To start developing:"
echo -e "  1. source ~/.thingino_config"
echo -e "  2. cd ${WORKSPACE_DIR}/thingino-firmware"
echo -e "  3. make help"
echo -e "${BLUE}=======================================================${NC}"
=${NC}"
