# Thingino Development Knowledge Base

## Workspace Architecture
- **Root:** `~/thingino-workspace/`
- **Firmware:** `~/thingino-workspace/firmware/` (Thingino-firmware repository)
- **Toolchains:** `~/thingino-workspace/toolchains/`
- **Configuration:** `~/.thingino_config` (Exports `CROSS_COMPILE` and `THINGINO_TOOLCHAIN`)

## Environment Setup
The setup is automated via the `thingino-devel` bootstrap repository:
1. `bash setup.sh` installs dependencies and clones source.
2. `bash bootstrap_thingino_toolchains.sh` downloads GCC 15 toolchains.
3. `bash select_toolchain.sh` configures the active toolchain.

## Key Dependencies
- **Compilers:** GCC 15 (XBurst1/XBurst2 variants).
- **Embedded Tools:** `binwalk`, `mtd-utils` (JFFS2), `squashfs-tools`, `cpio`.
- **Virtualization:** `podman`, `qemu-user-static`.
- **Utilities:** `lazygit`, `bc`, `u-boot-tools`.

## Common Commands
- **Activate Env:** `source ~/.thingino_config`
- **Build Firmware:** `cd firmware && make <board_name>`
- **Check Dependencies:** `./scripts/dep_check.sh` (inside firmware repo)

## Toolchain Variants
- **XBurst1:** Used for older Ingenic SoCs (e.g., T20, T30).
- **XBurst2:** Used for newer Ingenic SoCs (e.g., T40).
- **Libc:** musl (preferred), uclibc, or glibc.
