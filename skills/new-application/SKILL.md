---
name: new-application
description: Create a new BeagleBone AI-64 application under applications/ from the _template, cross-compile it for aarch64 (Cortex-A72) with CMake, and run it on the board. Use when starting a new app, adding a program/demo/test tool, or cross-compiling userspace code for the board.
---

# New application

## Create

```bash
N=<short-kebab-name>                       # or applicationN, per applications/README.md
cp -r applications/_template applications/$N
sed -i "s/project(app /project($N /; s/add_executable(app /add_executable($N /; s/TARGETS app /TARGETS $N /" \
    applications/$N/CMakeLists.txt
```

Rewrite `applications/$N/README.md`: one-line purpose, build, run, and any
device access (GPIO/I2C/SPI `/dev` nodes, overlays, permissions).

## Build

Host cross-compile (needs `gcc-aarch64-linux-gnu g++-aarch64-linux-gnu`):

```bash
cd applications/$N
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=toolchain-aarch64.cmake
cmake --build build -j"$(nproc)"
file build/$N                              # → ELF 64-bit ARM aarch64
```

Native on the board: `cmake -S . -B build && cmake --build build`.

Adding C++: change `LANGUAGES C` → `C CXX`. Linking target libs (e.g. libgpiod)
when cross-compiling needs a sysroot — set `CMAKE_SYSROOT` in the toolchain
file, or just build natively on the board.

## Run

```bash
scp build/$N debian@<board-ip>:~ && ssh debian@<board-ip> ./$N
```

(`debian` is the default user on BeagleBoard Debian images.)

## Rules

- Self-contained folder; `build/` dirs are git-ignored — never commit binaries.
- Kernel modules also live here; build them per `kernel-dev`.
- Commit on a `feat/<app>` branch off `develop` (see `git-workflow`).
