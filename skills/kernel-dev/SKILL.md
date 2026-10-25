---
name: kernel-dev
description: Cross-compile, modify, and test the BeagleBone AI-64 Linux kernel (6.18.x-k3 via RobertCNelson arm64-multiplatform) — config changes, device-tree edits, in-tree drivers, incremental rebuilds, making changes permanent as patches in the code-locker fork, installing the kernel on the board as a .deb, and verifying/rolling back. Use for any kernel, DTS, or in-tree driver work, or "how do I build/test the kernel".
---

# Kernel development

> Status: build-side flow checked against the arm64-multiplatform scripts;
> board install (deploy-kernel.sh) not yet verified on hardware.

Full guide: `docs/build/KERNEL.md`. Application-owned kernel code (out-of-tree
modules) is a separate path: `app-kernel-module`.

## Loop

```bash
./scripts/build-kernel.sh                            # first time (full: fetch + patch + build)
$EDITOR sources/arm64-multiplatform/KERNEL/<file>
REBUILD=1 ./scripts/build-kernel.sh                  # incremental, keeps KERNEL/ edits
BOARD=debian@<board-ip> ./scripts/deploy-kernel.sh --reboot
ssh debian@<board-ip> 'uname -r; dmesg --level=err,warn | head'
```

`build-kernel.sh` also rebuilds every `applications/*/kernel/` module against
the new tree (`APP_MODULES=0` to skip).

## Rules that bite

- Full `./scripts/build-kernel.sh`, `build_kernel.sh`, and `build_deb.sh` all
  **re-check-out and re-patch `KERNEL/`** — uncommitted edits there are lost.
  Use `REBUILD=1` while iterating; `deploy-kernel.sh` packages the existing
  tree with `make bindeb-pkg` (same options as build_deb.sh) for this reason.
- A change is permanent only as a patch in the fork:
  `KERNEL/` commit → `git format-patch` into `patches/local/` → `dir 'local'`
  appended at the end of `patch.sh` → commit/push in `sources/arm64-multiplatform`
  → bump submodule + `versions.lock` here. Confirm with one full build.
- Config changes: menuconfig during the build saves to `patches/defconfig`; commit it in the fork.
- Compiler: always the one in `sources/arm64-multiplatform/.CC` (`CC=<prefix>`), never the distro gcc.
- Out-of-tree modules must be rebuilt after any kernel config/version change.

## Where things are

| What | Path |
|---|---|
| board DTS | `KERNEL/arch/arm64/boot/dts/ti/k3-j721e-beagleboneai64.dts` |
| version / toolchain | `sources/arm64-multiplatform/version.sh` |
| patch order | `sources/arm64-multiplatform/patch.sh` |
| outputs | `build/kernel/` (Image, dtbs/modules tarballs, config, linux-image .deb) |

## Board-side checks

| Symptom | Likely cause |
|---|---|
| still old `uname -r` | boot menu picked the old kernel; check serial console / `/boot` |
| panic, no rootfs | initrd not generated (`dpkg -i` errors) or wrong `root=` |
| module `Invalid module format` | module built against a different tree/config |

Rollback: previous kernel from the boot menu, then `sudo apt remove linux-image-<bad>`.
