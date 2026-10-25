---
name: build-image
description: Build the BeagleBone AI-64 boot chain (TF-A, OP-TEE, U-Boot R5/A72 → tiboot3.bin, sysfw.itb, tispl.bin, u-boot.img) and the 6.18.x-k3 arm64 kernel from the pinned sources, and diagnose build failures. Use when asked to build, rebuild, or compile the image/bootloader/kernel, or when a build step fails.
---

# Build the BBAI64 image

Background (boot flow, why two defconfigs/compilers): `skills/beaglebone-embedded-linux/README.md`.
Manual walkthrough: `docs/build/BUILD.md`. Pins: `versions.lock`.

## 1. Host prerequisites (Debian/Ubuntu, once per PC)

```bash
sudo apt update
sudo apt install -y git build-essential bison flex libssl-dev bc make gcc \
  gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu \
  device-tree-compiler swig python3-dev python3-setuptools \
  python3-pyelftools python3-yaml python3-jsonschema yamllint \
  libgnutls28-dev libncurses-dev uuid-dev libyaml-dev u-boot-tools fakeroot
sudo apt install -y dpkg-dev cmake g++-aarch64-linux-gnu   # kernel .deb + applications
```

Install the Python bits from **apt, not pip** (PEP 668). Package is `yamllint`,
not `python3-yamllint`.

## 2. Build

```bash
./scripts/bootstrap.sh      # submodules + pinned TF-A / OP-TEE / ti-linux-firmware
./scripts/build-uboot.sh    # → build/deploy/{tiboot3.bin,sysfw.itb,tispl.bin,u-boot.img}
./scripts/build-kernel.sh   # → build/kernel/{*.Image,*-dtbs.tar.zst,*-modules.tar.zst,config-*}
```

The kernel build downloads linux-stable + a kernel.org gcc toolchain on first
run (several GB, slow), then builds every `applications/*/kernel/` module
against the new tree into `build/apps/<app>/kernel/` (`APP_MODULES=0` skips).
After editing `KERNEL/`, use `REBUILD=1 ./scripts/build-kernel.sh` — a plain run
re-patches the tree and drops the edits. More: `kernel-dev`.

Disk: plan ~30–40 GB free (kernel clone + objects are most of it).

Run long builds in the background and tail their output; a full u-boot build is
minutes, the first kernel build can be an hour+.

## 3. Check the outputs

```bash
ls -lL build/deploy/ build/kernel/
```

All **four** boot files are needed — `BUILD.md` §4 lists three, but on J721E
`sysfw.itb` is required (without it the R5 SPL banner prints then hangs).

## Failure → cause

| Symptom | Cause / fix |
|---|---|
| `Unknown entry type 'ti-board-config'` / binman traceback at the very end | missing `python3-pyelftools`, `swig`, or `yamllint` |
| `!! missing sources/...` | run `./scripts/bootstrap.sh` |
| `sources/arm64-multiplatform not populated` | submodules not cloned — `git submodule update --init --recursive` (needs the personal SSH key, see `workspace-setup`) |
| `Could not resolve host` during fetch | transient; `fetch-firmware.sh` retries (`RETRIES=` to raise) |
| board boots old u-boot | wrong file copied — on GP silicon the script picks `*_unsigned` A72 FITs; don't use the signed `u-boot.img` from `build/u-boot-a72/` |

## Rules

- Never commit anything under `build/` or any `*.img*` / `*.bin`.
- Changing a pin: edit `versions.lock` + move the submodule in one commit.
