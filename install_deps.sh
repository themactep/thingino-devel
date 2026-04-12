#!/bin/bash
# Install system dependencies for Thingino development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Installing system dependencies...${NC}"

# Detect package manager
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID_LIKE" in
        *debian*)
            sudo apt-get update
            sudo apt-get install -y \
                autoconf build-essential bc bison binwalk ccache cpio cmake curl dialog file flex gawk git lazygit \
                libncurses-dev libusb-1.0-0-dev make m4 mtd-utils nano perl python3 python3-pip python3-jsonschema \
                rsync squashfs-tools unzip u-boot-tools vim-tiny wget whiptail podman qemu-system-misc qemu-user-static
            ;;
        *)
            case "$ID" in
                ubuntu|debian|linuxmint|zorin)
                    sudo apt-get update
                    sudo apt-get install -y \
                        autoconf build-essential bc bison binwalk ccache cpio cmake curl dialog file flex gawk git lazygit \
                        libncurses-dev libusb-1.0-0-dev make m4 mtd-utils nano perl python3 python3-pip python3-jsonschema \
                        rsync squashfs-tools unzip u-boot-tools vim-tiny wget whiptail podman qemu-system-misc qemu-user-static
                    ;;
                arch)
                    sudo pacman -Syu --needed --noconfirm \
                        autoconf base-devel bc bison binwalk cpio cmake curl dialog file flex gawk git lazygit \
                        m4 libnewt libusb make mtd-utils nano ncurses perl python python-pip rsync squashfs-tools unzip \
                        uboot-tools wget podman qemu-base qemu-user-static
                    ;;
                fedora|rhel|centos)
                    sudo dnf install -y \
                        autoconf gcc m4 make bc bison binwalk cpio cmake curl dialog file flex gawk git lazygit \
                        mtd-utils nano ncurses-devel newt libusbx-devel perl rsync squashfs-tools unzip uboot-tools wget \
                        podman qemu-system-x86 qemu-user-static
                    ;;
                alpine)
                    sudo apk add \
                        autoconf bash build-base bc bison binwalk cpio cmake curl dialog file findutils \
                        flex gawk git grep lazygit m4 mtd-utils nano ncurses-dev newt libusb-dev make perl rsync squashfs-tools \
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
