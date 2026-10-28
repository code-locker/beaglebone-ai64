---
name: new-application
description: Create a new BeagleBone AI-64 application under applications/ (userspace part, optional kernel module part, on-board test) with scripts/new-app.sh, cross-compile it for aarch64 with build-app.sh, and run it on the board with deploy-app.sh. Use when starting a new app, adding a program/demo/test tool, or cross-compiling userspace code for the board.
---

# New application

Layout and conventions: `applications/README.md`.

## Create

```bash
./scripts/new-app.sh <app>               # user/ + kernel/ + test/
./scripts/new-app.sh <app> --no-kernel   # userspace only
```

`<app>` = `[a-z][a-z0-9_]*`; replaces the `tmpl` placeholder everywhere
(binary `<app>`, module `<app>_drv`, `/dev/<app>_drv`). Then rewrite
`applications/<app>/README.md`: purpose, device access, how to run.

## Build

Host needs `gcc-aarch64-linux-gnu g++-aarch64-linux-gnu cmake` (+ the kernel
built once if there is a `kernel/` part).

```bash
./scripts/build-app.sh <app>             # all → build/apps/<app>/{bin,kernel,test}
./scripts/build-app.sh <app> user        # userspace only
file build/apps/<app>/bin/<app>          # → ELF 64-bit ARM aarch64
```

User part uses `applications/cmake/toolchain-aarch64.cmake`. C++: change
`LANGUAGES C` → `C CXX` in `user/CMakeLists.txt`. Linking board libraries
(e.g. libgpiod) when cross-compiling needs a sysroot (`CMAKE_SYSROOT`) — or build
the user part natively on the board.

Kernel part: see `app-kernel-module`.

## Run

```bash
BOARD=debian@<board-ip> ./scripts/deploy-app.sh <app>         # copy to ~/apps/<app>/
BOARD=debian@<board-ip> ./scripts/deploy-app.sh <app> --run   # + run test/on-board.sh
```

Extend `test/on-board.sh` so it exits non-zero on failure — it is the app's hardware test.

## Rules

- Self-contained folder; `build/` and `*.ko` are git-ignored — never commit binaries.
- Commit on a `feat/<app>` branch off `develop` (see `git-workflow`).
