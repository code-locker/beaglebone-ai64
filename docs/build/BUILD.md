# Build guide — BeagleBone AI-64 boot chain & kernel

Full walkthrough for reproducing the boot firmware and kernel from source at the
versions pinned in [`../../versions.lock`](../../versions.lock).

The scripts under [`../../scripts/`](../../scripts/) automate all of this; the
manual commands below document what each step does. My original step notes are in
[`../upstream/uboot-bbai64-build-steps.pdf`](../upstream/uboot-bbai64-build-steps.pdf).

## 0. Host prerequisites (Debian/Ubuntu host)

```bash
sudo apt update
sudo apt install -y git build-essential bison flex libssl-dev bc make gcc \
  gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu \
  device-tree-compiler swig python3-dev python3-setuptools \
  python3-pyelftools python3-yaml python3-jsonschema yamllint \
  libgnutls28-dev libncurses-dev uuid-dev libyaml-dev u-boot-tools fakeroot
```

> The U-Boot `binman` packaging step needs `python3-pyelftools`, `swig`, and
> `yamllint` (note: the package is `yamllint`, **not** `python3-yamllint`).
> Missing them lets the build run for minutes and then die at the very last step
> (`Unknown entry type 'ti-board-config'` or an obscure binman traceback). Install
> from apt, **not** `pip` (Ubuntu 24.04+ marks Python externally-managed / PEP 668).
> See `docs/upstream/uboot-bbai64-build-steps.pdf` §2.2 for the full rationale.

Cross-compilers used:
- 32-bit (R5 / OP-TEE): `arm-linux-gnueabihf-`
- 64-bit (A72 / TF-A / U-Boot / kernel): `aarch64-linux-gnu-`

The kernel build additionally auto-downloads a **gcc 15.2.0 (nolibc) aarch64**
toolchain from kernel.org.

## 1. Fetch sources

```bash
./scripts/bootstrap.sh
```

This initializes the two submodules (`sources/u-boot`, `sources/arm64-multiplatform`)
and clones the pinned firmware repos (`optee_os`, `trusted-firmware-a`,
`ti-linux-firmware`) into `sources/`.

## 2. Build the boot chain (TF-A → OP-TEE → U-Boot)

```bash
./scripts/build-uboot.sh
```

What it does (J721E / TDA4VM):

1. **TF-A (BL31)** — `PLAT=k3 TARGET_BOARD=generic SPD=opteed`
2. **OP-TEE (BL32)** — `PLATFORM=k3-j721e CFG_ARM64_core=y`
3. **U-Boot R5 SPL** — `j721e_beagleboneai64_r5_defconfig`, combined with TI
   system firmware (DM + sysfw from `ti-linux-firmware`) → **`tiboot3.bin`**
4. **U-Boot A72** — `j721e_beagleboneai64_a72_defconfig`, with `BL31`, `TEE`,
   and `BINMAN_INDIRS` → **`tispl.bin`** + **`u-boot.img`**

Outputs land in **`build/deploy/`** (git-ignored):

```
tiboot3.bin      # R5 ROM-loaded first stage
tispl.bin        # A72 second stage (contains TF-A BL31 + OP-TEE BL32 + U-Boot SPL)
u-boot.img       # U-Boot proper
sysfw.itb        # TI system firmware blob
```

## 3. Build the kernel

```bash
./scripts/build-kernel.sh
```

Wraps RobertCNelson's `arm64-multiplatform` build system (`./build_kernel.sh`),
which downloads linux-stable 6.18.38, applies the k3 patch set, and builds the
`Image`, device trees, and modules. Optional Debian package via `./build_deb.sh`
inside the submodule.

Artifacts are collected into the common **`build/kernel/`** folder (alongside the
u-boot boot files in `build/deploy/`), so every compiled image lives under
`build/`:

```
build/kernel/
  6.18.38-arm64-k3-r45.Image             # kernel image
  6.18.38-arm64-k3-r45-dtbs.tar.zst      # device trees
  6.18.38-arm64-k3-r45-modules.tar.zst   # loadable modules
  config-6.18.38-arm64-k3-r45            # the .config used
```

(The originals also remain in `sources/arm64-multiplatform/deploy/`.) All of
`build/` is git-ignored.

## 4. Deploy to SD card

> Reference production image: **BBAI64 Debian 13.5 2026-05-19 XFCE (v6.18.x-k3)**.

The boot binaries go on the FAT boot partition:

```
tiboot3.bin  tispl.bin  u-boot.img
```

For a full card, flash the BeagleBoard reference `.img.xz` first, then overwrite
the boot binaries / kernel with your freshly-built ones. Do **not** commit any
`.img`/`.img.xz` to git (they are ignored).

## Version bumps

Edit [`../../versions.lock`](../../versions.lock), move the submodule to the new
commit (`cd sources/u-boot && git checkout <sha>`), rebuild, and commit the
submodule pointer on `develop`.
