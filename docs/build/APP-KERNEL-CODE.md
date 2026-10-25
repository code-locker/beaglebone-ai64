# Application kernel code — modules built alongside the Linux kernel

Some applications need code in the kernel (a driver, a misc device, an IRQ
handler, sysfs/ioctl interface). This repo keeps that code **inside the
application** (`applications/<app>/kernel/`) and compiles it with the workspace
kernel, so the app's userspace and kernel halves are versioned together.

## Layout

```
applications/<app>/
├── user/            # userspace (CMake)       → build/apps/<app>/bin/
├── kernel/          # kernel part              → build/apps/<app>/kernel/*.ko
│   ├── Kbuild       # obj-m := <app>_drv.o  (+ <app>_drv-y := a.o b.o for multi-file)
│   ├── Makefile     # native build on the board only
│   └── <app>_drv.c
└── test/on-board.sh # insmod → run user part → rmmod, run on the board
```

Start one with `./scripts/new-app.sh <app>` (`--no-kernel` for userspace only).

## How it is compiled with the kernel

The kernel part is an **out-of-tree (external) module** built with kbuild's
`M=` against `sources/arm64-multiplatform/KERNEL`:

```bash
make -C sources/arm64-multiplatform/KERNEL M=$PWD/applications/<app>/kernel \
     ARCH=arm64 CROSS_COMPILE=<prefix from sources/arm64-multiplatform/.CC> modules
```

`./scripts/build-app.sh <app> kernel` runs exactly that, and
`./scripts/build-kernel.sh` runs it for **every** application right after the
kernel build — so one command compiles the Linux kernel and all application
kernel code together, with the same tree, config, and compiler.

Why external rather than copying into `KERNEL/drivers/`:

- `KERNEL/` is regenerated on every full kernel build; app code there would be lost.
- Rebuilding one module takes seconds; no kernel rebuild/reflash needed.
- The app stays self-contained and reviewable in this repo.

## Version matching (vermagic)

A module only loads into the kernel it was built against (same
`kernel.release`, config, and compiler). So:

1. Build the workspace kernel and install it on the board (`docs/build/KERNEL.md` §5).
2. Build the module against that same tree (`build-app.sh` does).
3. Check: `modinfo -F vermagic <mod>.ko` on the host equals `uname -r` + flags on the board.

`Invalid module format` / `disagrees about version of symbol` in `dmesg` means
the board runs a different kernel than the one you built against.

Building **natively on the board** against its running kernel also works
(`cd kernel && make`), but needs that kernel's headers on the board — the
workspace `.deb` is built without a headers package, so prefer the host build.

## Edit → test loop

```bash
$EDITOR applications/<app>/kernel/<app>_drv.c
./scripts/build-app.sh <app>                               # kernel + user
BOARD=debian@<board-ip> ./scripts/deploy-app.sh <app> --run
```

## When the code must be in-tree instead

Move it into the kernel tree only when it has to be built-in (`=y`, e.g. needed
before the rootfs mounts), needs to patch existing kernel code, or is going
upstream:

1. Put the source under `KERNEL/drivers/<subsys>/`, add a `Kconfig` entry and a
   `Makefile` line (`obj-$(CONFIG_<APP>) += <app>_drv.o`).
2. Enable it in menuconfig during `REBUILD=1 ./scripts/build-kernel.sh`.
3. Make it permanent as a patch in the `code-locker/arm64-multiplatform` fork
   (`docs/build/KERNEL.md` §4) and remove the out-of-tree copy from the app,
   leaving a note in the app README pointing at the patch.

## Device tree

If the driver binds via a `compatible` string, its DT node goes either in the
board DTS (`KERNEL/arch/arm64/boot/dts/ti/k3-j721e-beagleboneai64.dts`, made
permanent as a patch) or in a DT overlay kept under `applications/<app>/dts/`
and documented in the app README.
