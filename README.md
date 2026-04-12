# Thingino Development Environment Bootstrap

This repository provides a set of tools to quickly set up a local development environment for the **Thingino** firmware project.

## Overview

The bootstrap process automates:
- Installation of required system packages (`build-essential`, `podman`, `qemu`, etc.).
- Creation of a dedicated workspace directory.
- Cloning the `thingino-firmware` source code.
- Downloading and installing cross-compilation toolchains (GCC 15) for Ingenic XBurst1 and XBurst2.
- Configuring environment variables for easy access to the toolchains.

## Quick Start

1. **Clone this repository:**
   ```bash
   git clone <this-repo-url> thingino-devel
   cd thingino-devel
   ```

2. **Run the setup script:**
   ```bash
   bash setup.sh
   ```
   *Note: The script will ask for sudo password to install system dependencies.*

3. **Activate the environment:**
   ```bash
   source ~/.thingino_config
   ```
   *Note: During setup, you can choose to have this added to your `.bashrc` or `.zshrc` automatically for future sessions.*

4. **Start developing:**
   ```bash
   cd ~/thingino-workspace/firmware
   make help
   ```

## Included Tools

- `setup.sh`: The main entry point that orchestrates the entire setup.
- `bootstrap_thingino_toolchains.sh`: Downloads and installs pre-built toolchains to `~/opt/toolchains`.
- `select_toolchain.sh`: Interactive script to switch between different toolchain variants (XBurst1 vs XBurst2, different C libraries).

## Dependencies

The `setup.sh` script supports `apt` (Debian/Ubuntu) and `pacman` (Arch Linux) automatically. For other distributions, please ensure you have the following installed:
- Git, Curl, Wget
- Build Essentials (GCC, Make)
- Python 3
- Podman
- QEMU (System and User Static)
- U-Boot Tools

## Directory Structure

- `~/thingino-workspace/`: Default location for source code and toolchains.
- `~/thingino-workspace/toolchains/`: Location where toolchains are installed.
- `~/.thingino_config`: Shell script snippet containing exported environment variables.
