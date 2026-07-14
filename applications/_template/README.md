# Application template

> Copy this folder to `applications/applicationN/` and replace this README.

One-line description of what this application does on the BeagleBone AI-64.

## Layout

```
_template/
├── README.md          # this file — what it is, how to build & run
├── CMakeLists.txt     # build definition
├── toolchain-aarch64.cmake  # cross-compile toolchain file
└── src/
    └── main.c
```

## Build (native on the board)

```bash
cmake -S . -B build
cmake --build build -j"$(nproc)"
./build/app
```

## Build (cross-compile on host for aarch64)

```bash
cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE=toolchain-aarch64.cmake
cmake --build build -j"$(nproc)"
# copy build/app to the board and run
scp build/app debian@<board-ip>:~
```

## Run

```bash
./app            # document arguments / expected output here
```

## Notes

- Target: BeagleBone AI-64, aarch64 (Cortex-A72), Debian 13.5.
- Document any device access (GPIO, I2C, /dev nodes), permissions, or overlays here.
