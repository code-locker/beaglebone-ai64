# Applications

My own applications that run on the BeagleBone AI-64. Each application lives in
its own folder and is fully self-contained: userspace code, optional kernel
code, an on-board test, and a README with build & run steps.

```
applications/
├── _template/            # copied by scripts/new-app.sh (placeholder name: tmpl)
├── cmake/
│   └── toolchain-aarch64.cmake   # shared cross-compile toolchain for user/ parts
└── <app>/
    ├── README.md
    ├── user/             # userspace part — CMake
    ├── kernel/           # optional kernel part — out-of-tree module (Kbuild)
    └── test/on-board.sh  # runs on the board: insmod → run → rmmod
```

## Start a new application

```bash
./scripts/new-app.sh <app>               # userspace + kernel module skeleton
./scripts/new-app.sh <app> --no-kernel   # userspace only
```

`<app>` is lowercase `[a-z][a-z0-9_]*` — it also names the module (`<app>_drv`)
and its device (`/dev/<app>_drv`).

## Build → deploy → test

```bash
./scripts/build-kernel.sh                # once: kernel tree the modules build against
./scripts/build-app.sh <app>             # → build/apps/<app>/{bin,kernel,test}
BOARD=debian@<board-ip> ./scripts/deploy-kernel.sh --reboot   # board must run this kernel
BOARD=debian@<board-ip> ./scripts/deploy-app.sh <app> --run
```

`build-kernel.sh` also rebuilds every app's `kernel/` part automatically, so the
modules always match the kernel. Details: [docs/build/APP-KERNEL-CODE.md](../docs/build/APP-KERNEL-CODE.md).

## Conventions

- Cross-compile on the host for aarch64 (Cortex-A72); the user part can also be
  built natively on the board.
- Kernel code is GPL-2.0 (`SPDX-License-Identifier: GPL-2.0` header); the rest MIT.
- Build directories and `*.ko` are git-ignored — never commit binaries.
