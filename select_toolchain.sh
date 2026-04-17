#!/bin/bash
# Toolchain selector for Thingino development
# Saves selection to ~/.thingino_config

INSTALL_BASE="${INSTALL_BASE:-${HOME}/thingino-workspace/toolchains}"
CONFIG_FILE="${HOME}/.thingino_config"
GITHUB_REPO="themactep/thingino-firmware"
RELEASE_TAG="toolchain-x86_64"

get_libc_from_abbr() {
    case "$1" in
        musl)   echo "musl" ;;
        uclibc) echo "uclibc" ;;
        gnu)    echo "glibc" ;;
        *)      return 1 ;;
    esac
}

reinstall_toolchain() {
    local selected_root="$1"
    local archive_url="$2"
    local remote_epoch="$3"
    local temp_archive
    local temp_extract
    local backup_dir=""

    temp_archive=$(mktemp /tmp/thingino_XXXX.tar.gz) || return 1
    temp_extract=$(mktemp -d /tmp/thingino_toolchain_XXXX) || { rm -f "$temp_archive"; return 1; }

    echo "Remote bundle is newer. Reinstalling $(basename "$selected_root")..."

    if command -v wget &>/dev/null; then
        wget -q --show-progress "$archive_url" -O "$temp_archive" || {
            echo "Failed to download $archive_url"
            rm -f "$temp_archive"
            rm -rf "$temp_extract"
            return 1
        }
    else
        curl -fL --progress-bar "$archive_url" -o "$temp_archive" || {
            echo "Failed to download $archive_url"
            rm -f "$temp_archive"
            rm -rf "$temp_extract"
            return 1
        }
    fi

    tar -xf "$temp_archive" -C "$temp_extract" --strip-components=1 || {
        echo "Failed to extract $temp_archive"
        rm -f "$temp_archive"
        rm -rf "$temp_extract"
        return 1
    }

    rm -f "$temp_archive"

    if [ -d "$selected_root" ]; then
        backup_dir="${selected_root}.backup.$$"
        mv "$selected_root" "$backup_dir" || {
            echo "Failed to prepare backup for reinstall."
            rm -rf "$temp_extract"
            return 1
        }
    fi

    if ! mv "$temp_extract" "$selected_root"; then
        echo "Failed to install new toolchain files."
        if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
            mv "$backup_dir" "$selected_root" || true
        fi
        rm -rf "$temp_extract"
        return 1
    fi

    if [ -x "${selected_root}/relocate-sdk.sh" ]; then
        (cd "$selected_root" && ./relocate-sdk.sh > /dev/null) || {
            echo "relocate-sdk.sh failed after reinstall."
            rm -rf "$selected_root"
            if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
                mv "$backup_dir" "$selected_root" || true
            fi
            return 1
        }
    fi

    printf '%s\n' "$remote_epoch" > "${selected_root}/.bundle_remote_epoch"
    if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
        rm -rf "$backup_dir"
    fi
    echo "Reinstall complete."
}

check_and_refresh_toolchain() {
    local selected_root="$1"
    local name
    local gcc_ver
    local libc_abbr
    local gen
    local libc
    local archive
    local archive_url
    local remote_last_modified
    local remote_epoch
    local local_epoch
    local marker_file

    name=$(basename "$selected_root")
    if [[ ! "$name" =~ ^mipsel-thingino-linux-(gcc[0-9]+)-([^-]+)-(xburst[0-9]+)$ ]]; then
        echo "Skipping freshness check: unrecognized toolchain name '$name'."
        return 0
    fi

    gcc_ver="${BASH_REMATCH[1]}"
    libc_abbr="${BASH_REMATCH[2]}"
    gen="${BASH_REMATCH[3]}"

    libc=$(get_libc_from_abbr "$libc_abbr") || {
        echo "Skipping freshness check: unsupported libc suffix '$libc_abbr'."
        return 0
    }

    archive="thingino-toolchain-x86_64_${gen}_${libc}_${gcc_ver}-linux-mipsel.tar.gz"
    archive_url="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${archive}"

    remote_last_modified=$(curl -fsIL "$archive_url" | tr -d '\r' | awk -F': ' 'tolower($1)=="last-modified"{print $2; exit}')
    if [ -z "$remote_last_modified" ]; then
        echo "Could not determine remote bundle freshness for $archive."
        return 0
    fi

    remote_epoch=$(date -d "$remote_last_modified" +%s 2>/dev/null)
    if [ -z "$remote_epoch" ]; then
        echo "Could not parse remote timestamp for $archive."
        return 0
    fi

    marker_file="${selected_root}/.bundle_remote_epoch"
    if [ -f "$marker_file" ] && [[ "$(cat "$marker_file" 2>/dev/null)" =~ ^[0-9]+$ ]]; then
        local_epoch=$(cat "$marker_file")
    else
        local_epoch=$(stat -c %Y "$selected_root" 2>/dev/null || echo 0)
    fi

    if [ "$remote_epoch" -gt "$local_epoch" ]; then
        reinstall_toolchain "$selected_root" "$archive_url" "$remote_epoch" || {
            echo "Keeping existing toolchain due to reinstall failure."
            return 0
        }
    else
        echo "Installed toolchain is up to date."
    fi
}

if [ ! -d "$INSTALL_BASE" ]; then
    echo "Error: Toolchain directory $INSTALL_BASE not found."
    exit 1
fi

echo "--- Thingino Toolchain Selector ---"
echo "Searching for installed toolchains in $INSTALL_BASE..."

# Find all toolchain roots (directories containing bin/mipsel-linux-gcc)
TOOLCHAINS=()
while IFS= read -r -d '' gcc_binary; do
    bin_dir=$(dirname "$gcc_binary")
    root_dir=$(dirname "$bin_dir")
    TOOLCHAINS+=("$root_dir")
done < <(find "$INSTALL_BASE" -maxdepth 3 -name "mipsel-linux-gcc" -print0)

if [ ${#TOOLCHAINS[@]} -eq 0 ]; then
    echo "No toolchains found. Please run ./bootstrap_thingino_toolchains.sh first."
    exit 1
fi

# Sort alphabetically
IFS=$'\n' TOOLCHAINS=($(sort <<<"${TOOLCHAINS[*]}"))
unset IFS

echo "Available toolchains:"
for i in "${!TOOLCHAINS[@]}"; do
    name=$(basename "${TOOLCHAINS[$i]}")
    echo "  [$((i + 1))] $name"
done

read -p "Select toolchain(s) [0=all, 1-${#TOOLCHAINS[@]}, space-separated]: " choice
read -r -a selections <<< "$choice"

if [ ${#selections[@]} -eq 0 ]; then
    echo "Invalid selection."
    exit 1
fi

selected_indices=()
contains_all=0
active_index=-1

for sel in "${selections[@]}"; do
    if ! [[ "$sel" =~ ^[0-9]+$ ]]; then
        echo "Invalid selection."
        exit 1
    fi

    if [ "$sel" -eq 0 ]; then
        contains_all=1
        active_index=0
        continue
    fi

    if [ "$sel" -lt 1 ] || [ "$sel" -gt "${#TOOLCHAINS[@]}" ]; then
        echo "Invalid selection."
        exit 1
    fi

    idx=$((sel - 1))
    if [[ ! " ${selected_indices[*]} " =~ " ${idx} " ]]; then
        selected_indices+=("$idx")
    fi
    active_index="$idx"
done

if [ "$contains_all" -eq 1 ]; then
    if [ ${#selections[@]} -gt 1 ]; then
        echo "Invalid selection."
        exit 1
    fi
    selected_indices=()
    for i in "${!TOOLCHAINS[@]}"; do
        selected_indices+=("$i")
    done
fi

if [ ${#selected_indices[@]} -eq 0 ]; then
    echo "Invalid selection."
    exit 1
fi

for idx in "${selected_indices[@]}"; do
    root="${TOOLCHAINS[$idx]}"
    echo "Processing: $(basename "$root")"
    check_and_refresh_toolchain "$root"
done

SELECTED_ROOT="${TOOLCHAINS[$active_index]}"
CROSS_COMPILE_PREFIX="${SELECTED_ROOT}/bin/mipsel-linux-"

echo "Active: $(basename "$SELECTED_ROOT")"

# Save to global config
echo "export THINGINO_TOOLCHAIN=\"$SELECTED_ROOT\"" > "$CONFIG_FILE"
echo "export CROSS_COMPILE=\"$CROSS_COMPILE_PREFIX\"" >> "$CONFIG_FILE"

echo "Configuration saved to $CONFIG_FILE"
echo "To activate in current shell: source $CONFIG_FILE"
