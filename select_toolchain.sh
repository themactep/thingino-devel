#!/bin/bash
# Toolchain selector for Thingino development
# Saves selection to ~/.thingino_config

INSTALL_BASE="${HOME}/opt/toolchains"
CONFIG_FILE="${HOME}/.thingino_config"

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
    echo "  [$i] $name"
done

read -p "Select active toolchain [0-$((${#TOOLCHAINS[@]} - 1))]: " choice

if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -lt "${#TOOLCHAINS[@]}" ]; then
    SELECTED_ROOT="${TOOLCHAINS[$choice]}"
    CROSS_COMPILE_PREFIX="${SELECTED_ROOT}/bin/mipsel-linux-"
    
    echo "Selected: $(basename "$SELECTED_ROOT")"
    
    # Save to global config
    echo "export THINGINO_TOOLCHAIN=\"$SELECTED_ROOT\"" > "$CONFIG_FILE"
    echo "export CROSS_COMPILE=\"$CROSS_COMPILE_PREFIX\"" >> "$CONFIG_FILE"
    
    echo "Configuration saved to $CONFIG_FILE"
    echo "To activate in current shell: source $CONFIG_FILE"
else
    echo "Invalid selection."
    exit 1
fi
