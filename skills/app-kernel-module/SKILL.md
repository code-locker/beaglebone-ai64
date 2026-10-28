---
name: app-kernel-module
description: Write, cross-compile, and test the kernel part of a BeagleBone AI-64 application — an out-of-tree module in applications/<app>/kernel/ built against the workspace kernel with the same compiler, deployed with its userspace part, and loaded on the board; plus when and how to move it in-tree. Use when an application needs a driver, misc device, ioctl/sysfs interface, IRQ handling, or any kernel code, or on module load errors (vermagic, Invalid module format, Unknown symbol).
---

# Application kernel module

Full guide: `docs/build/APP-KERNEL-CODE.md`.

## Shape

```
applications/<app>/kernel/Kbuild      obj-m := <app>_drv.o   (multi-file: <app>_drv-y := a.o b.o)
applications/<app>/kernel/<app>_drv.c GPL-2.0 SPDX header, MODULE_LICENSE("GPL")
applications/<app>/kernel/Makefile    native board build only
applications/<app>/test/on-board.sh   insmod → run user part → rmmod
```

New app with this skeleton: `./scripts/new-app.sh <app>` (template = misc device
`/dev/<app>_drv` + user program that reads it).

## Build & test

```bash
./scripts/build-kernel.sh                         # once; KERNEL/ must be built (Module.symvers)
./scripts/build-app.sh <app> kernel               # or no 2nd arg: kernel + user
BOARD=debian@<board-ip> ./scripts/deploy-kernel.sh --reboot   # once per kernel change
BOARD=debian@<board-ip> ./scripts/deploy-app.sh <app> --run
```

`build-app.sh` runs `make -C sources/arm64-multiplatform/KERNEL M=<app>/kernel
ARCH=arm64 CROSS_COMPILE=<.CC prefix> modules`; `build-kernel.sh` does that for
every app after each kernel build. Override with `KDIR=` / `CROSS_COMPILE=`.

## Failure → cause

| Symptom | Cause / fix |
|---|---|
| `not a built kernel tree` | run `./scripts/build-kernel.sh` first |
| board `Invalid module format` / vermagic mismatch | board runs another kernel — `deploy-kernel.sh`, compare `modinfo -F vermagic` vs `uname -r` |
| `Unknown symbol` on insmod | symbol not exported / provided by another module not loaded — `modprobe` deps or `EXPORT_SYMBOL_GPL` |
| `compiler differs from the one used to build the kernel` | wrong CROSS_COMPILE; use the `.CC` prefix |
| build litter in `kernel/` | ignored by `.gitignore`; `./scripts/build-app.sh <app> clean` |

## Move in-tree only when

it must be built-in (`=y`), patches existing kernel code, or goes upstream →
`KERNEL/drivers/<subsys>/` + Kconfig + Makefile, made permanent as a fork patch
(`kernel-dev`). Note it in the app README and drop the out-of-tree copy.

## Rules

- Never commit `*.ko`, `*.o`, `modules.order`, `Module.symvers`.
- Rebuild modules after any kernel config/version change.
- Kernel code GPL-2.0; one app's kernel part must not depend on another app's.
