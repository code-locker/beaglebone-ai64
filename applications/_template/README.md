# tmpl

> Created from `applications/_template` by `./scripts/new-app.sh`. Replace this
> README's text; keep the Build / Run sections accurate.

One-line description of what this application does on the BeagleBone AI-64.

## Layout

```
tmpl/
├── README.md        # this file — what it is, how to build & run
├── user/            # userspace part (CMake, cross-compiled for aarch64)
│   ├── CMakeLists.txt
│   └── src/main.c
├── kernel/          # kernel part (out-of-tree module) — delete if not needed
│   ├── Kbuild       # obj-m list, used for both host and board builds
│   ├── Makefile     # native build on the board only
│   └── tmpl_drv.c
└── test/
    └── on-board.sh  # run on the board: insmod → run app → rmmod
```

## Build (host, cross-compile)

Needs the workspace kernel built once (`./scripts/build-kernel.sh`) for the kernel part.

```bash
./scripts/build-app.sh tmpl            # kernel + user → build/apps/tmpl/
./scripts/build-app.sh tmpl kernel     # only the module
./scripts/build-app.sh tmpl user       # only the userspace binary
```

## Run on the board

```bash
BOARD=debian@<board-ip> ./scripts/deploy-app.sh tmpl --run
```

The module only loads on the kernel it was built against — deploy the workspace
kernel first (`./scripts/deploy-kernel.sh`), see `docs/build/KERNEL.md`.

## Notes

- Target: BeagleBone AI-64, aarch64 (Cortex-A72), Debian 13.5.
- Device access (GPIO, I2C, /dev nodes), permissions, DT overlays: document here.
