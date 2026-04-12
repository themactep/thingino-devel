#!/bin/bash
# Bootstrap script for Thingino Toolchains (Ingenic XBurst1/XBurst2)
# Installs toolchains to ~/opt/toolchains/ with a flattened naming convention.

set -e

# Configuration
INSTALL_BASE="${INSTALL_BASE:-${HOME}/thingino-workspace/toolchains}"
GITHUB_REPO="themactep/thingino-firmware"
RELEASE_TAG="toolchain-x86_64"

# Toolchain definitions
XBURST_GENS=("xburst1" "xburst2")
LIBC_TYPES=("musl" "uclibc" "glibc")
GCC_VER="gcc15"

mkdir -p "${INSTALL_BASE}"

echo "-------------------------------------------------------"
echo "Thingino Toolchain Bootstrapper"
echo "Target: ${INSTALL_BASE}"
echo "-------------------------------------------------------"

# Mapping libc types to directory naming conventions
get_libc_abbr() {
    case "$1" in
        musl)   echo "musl" ;;
        uclibc) echo "uclibc" ;;
        glibc)  echo "gnu" ;;
    esac
}

for GEN in "${XBURST_GENS[@]}"; do
    for LIBC in "${LIBC_TYPES[@]}"; do
        
        LIBC_ABBR=$(get_libc_abbr "$LIBC")
        ARCHIVE="thingino-toolchain-x86_64_${GEN}_${LIBC}_${GCC_VER}-linux-mipsel.tar.gz"
        URL="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${ARCHIVE}"
        
        # New directory structure: ~/opt/toolchains/mipsel-thingino-linux-gcc15-<libc_abbr>-<arch>
        TARGET_DIR="${INSTALL_BASE}/mipsel-thingino-linux-${GCC_VER}-${LIBC_ABBR}-${GEN}"

        echo "[*] Processing ${GEN} with ${LIBC}..."

        if [ -d "${TARGET_DIR}/bin" ] && [ -f "${TARGET_DIR}/relocate-sdk.sh" ]; then
            echo "    Already installed in ${TARGET_DIR}. Skipping."
            continue
        fi

        echo "    Downloading: ${ARCHIVE}"
        TEMP_ARCHIVE=$(mktemp /tmp/thingino_XXXX.tar.gz)
        
        if command -v wget &>/dev/null; then
            wget -q --show-progress "${URL}" -O "${TEMP_ARCHIVE}" || { echo "    Failed to download ${URL}"; rm -f "${TEMP_ARCHIVE}"; continue; }
        else
            curl -L --progress-bar "${URL}" -o "${TEMP_ARCHIVE}" || { echo "    Failed to download ${URL}"; rm -f "${TEMP_ARCHIVE}"; continue; }
        fi

        echo "    Extracting to ${TARGET_DIR}..."
        mkdir -p "${TARGET_DIR}"
        # Strip components to flatten the directory structure
        tar -xf "${TEMP_ARCHIVE}" -C "${TARGET_DIR}" --strip-components=1
        rm -f "${TEMP_ARCHIVE}"

        # Relocate the SDK
        if [ -x "${TARGET_DIR}/relocate-sdk.sh" ]; then
            echo "    Relocating SDK in ${TARGET_DIR}..."
            (cd "${TARGET_DIR}" && ./relocate-sdk.sh > /dev/null)
        fi

        echo "    Done: Installed to ${TARGET_DIR}"
    done
done

echo "-------------------------------------------------------"
echo "All toolchains processed."
echo "Location: ${INSTALL_BASE}"
echo "-------------------------------------------------------"

if [ -f "./select_toolchain.sh" ]; then
    ./select_toolchain.sh
else
    echo "To use a toolchain in your project, set your cross compiler path, e.g.:"
    echo "export CROSS_COMPILE=${INSTALL_BASE}/mipsel-thingino-linux-${GCC_VER}-musl-xburst1/bin/mipsel-linux-"
fi
echo "-------------------------------------------------------"
