# Standalone U-Boot build — BeagleBone AI-64

How to compile the BeagleBone AI-64 (TI TDA4VM / J721E) U-Boot by hand with
plain `make`, without `scripts/build-uboot.sh`. Use this to change U-Boot
code or config, to understand what the script does, or to build from a fresh
clone outside this workspace.

**Tested** on 2026-10-30, Ubuntu 22.04.5, Ubuntu cross GCC 11.4.0, 16 threads,
at the commits in [`../../versions.lock`](../../versions.lock). Every command
below was run, both in-tree and out-of-tree (`O=`), and the outputs matched
the known-good `build/deploy/` binaries byte-for-byte in size (contents differ
only in build timestamps / generated certificates).

## 1. What gets built

U-Boot is built **twice**, once per CPU, because the boot ROM runs on a 32-bit
Cortex-R5F and Linux runs on the 64-bit Cortex-A72s:

| Build | defconfig | CPU code | Compiler prefix | Produces |
|---|---|---|---|---|
| R5 | `j721e_beagleboneai64_r5_defconfig` | `arch/arm/cpu/armv7` (ARMv7-R, Thumb-2) | `arm-linux-gnueabihf-` | `tiboot3.bin`, `sysfw.itb` |
| A72 | `j721e_beagleboneai64_a72_defconfig` | `arch/arm/cpu/armv8` (AArch64) | `aarch64-linux-gnu-` | `tispl.bin_unsigned`, `u-boot.img_unsigned` |

Board code for both is `board/beagle/beagleboneai64/` (not `board/ti/j721e`,
which is TI's EVM).

The A72 build also packs in two binaries built by other projects, plus TI
firmware blobs:

| Input | From | Passed as |
|---|---|---|
| `bl31.bin` | TF-A (secure monitor, EL3) | `BL31=` |
| `tee-raw.bin` | OP-TEE OS (secure world) | `TEE=` |
| TIFS / DM firmware | `ti-linux-firmware` | `BINMAN_INDIRS=` (both builds) |

So the order is: **TF-A → OP-TEE → U-Boot R5 → U-Boot A72**. The R5 build
does not depend on TF-A or OP-TEE.

## 2. Host prerequisites

```bash
sudo apt update
sudo apt install -y git build-essential bison flex libssl-dev bc make gcc \
  gcc-arm-linux-gnueabihf gcc-aarch64-linux-gnu \
  device-tree-compiler swig python3-dev python3-setuptools \
  python3-pyelftools python3-yaml python3-jsonschema yamllint \
  libgnutls28-dev libncurses-dev uuid-dev libyaml-dev u-boot-tools
```

### Cross compilers

| Prefix | apt package | Used for |
|---|---|---|
| `arm-linux-gnueabihf-` | `gcc-arm-linux-gnueabihf` | U-Boot R5 (`tiboot3.bin`), OP-TEE's 32-bit TA dev kit |
| `aarch64-linux-gnu-` | `gcc-aarch64-linux-gnu` | TF-A, OP-TEE core, U-Boot A72 |

`CROSS_COMPILE` is a **prefix**: make appends `gcc`, `ld`, `objcopy`, ... to
it, so it ends with `-` and the tools must be on `PATH`. Check:

```bash
arm-linux-gnueabihf-gcc --version     # tested: 11.4.0
aarch64-linux-gnu-gcc --version       # tested: 11.4.0
```

Any reasonably recent GCC works. To use a downloaded toolchain (e.g. Arm GNU
Toolchain or kernel.org crosstool) instead, pass the full prefix:
`CROSS_COMPILE=/opt/arm-gnu/bin/aarch64-none-linux-gnu-`. The R5 core needs
an ARM 32-bit (`arm-*`) compiler — an `aarch64` compiler cannot build it.

### Python: deactivate virtualenvs

binman (U-Boot's image packer) runs `python3` from `PATH` and needs the
apt-installed modules above. **If a Python virtualenv is active, binman uses
the venv's Python and fails at the very end:**

```
binman: Unknown entry type 'ti-board-config' ... error 'No module named 'yamllint''
```

Run `deactivate` (or open a fresh shell) before building, and check with
`python3 -c "import yamllint, elftools, yaml, jsonschema"`. Install these
from apt, not pip (Ubuntu 23.04+ blocks system pip, PEP 668).

## 3. Get the sources

Inside this workspace they are already submodules / fetched trees under
`sources/` (`./scripts/bootstrap.sh`). For a standalone setup, clone the
pinned versions from `versions.lock`:

```bash
mkdir bbai64 && cd bbai64
git clone https://github.com/beagleboard/u-boot.git -b v2026.01-Beagle
git clone https://github.com/TexasInstruments/ti-linux-firmware.git
git clone https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git
git clone https://github.com/OP-TEE/optee_os.git -b 4.10.0
# pin exactly (SHAs from versions.lock):
git -C u-boot             checkout 5c82fb688432c62e74af05fcc6aaa6d0e99d8c1b
git -C ti-linux-firmware  checkout 8f8592375a7930bcf41feff1bb26a5aae46857ae
git -C trusted-firmware-a checkout b5eaba47efc5e4e3029086d5c25eee0e8dbb0129
```

The commands below assume this layout and these variables:

```bash
export TOP=$PWD                         # workspace: TOP=<repo>/sources
export TIFW=$TOP/ti-linux-firmware
export OUT=$TOP/out                     # where build outputs go
```

## 4. TF-A (BL31)

```bash
make -C $TOP/trusted-firmware-a -j$(nproc) \
  CROSS_COMPILE=aarch64-linux-gnu- ARCH=aarch64 \
  PLAT=k3 TARGET_BOARD=generic SPD=opteed \
  BUILD_BASE=$OUT/tfa
# -> $OUT/tfa/k3/generic/release/bl31.bin   (~43 KB)
```

`SPD=opteed` makes BL31 hand off to OP-TEE as BL32. Drop `BUILD_BASE=` to
build into `trusted-firmware-a/build/` instead.

## 5. OP-TEE OS (BL32)

```bash
make -C $TOP/optee_os -j$(nproc) \
  CROSS_COMPILE=arm-linux-gnueabihf- CROSS_COMPILE64=aarch64-linux-gnu- \
  PLATFORM=k3-j721e CFG_ARM64_core=y \
  O=$OUT/optee
# -> $OUT/optee/core/tee-raw.bin   (~490 KB)
```

The core is 64-bit (`CFG_ARM64_core=y`, uses `CROSS_COMPILE64`); the
32-bit compiler builds the 32-bit TA dev kit. Without `O=` it builds into
`optee_os/out/arm-plat-k3/`.

## 6. U-Boot

Pick **one** of the two styles. Out-of-tree is recommended: the source tree
stays clean, and R5 + A72 builds can coexist.

### 6a. Out-of-tree (`O=`) — recommended

```bash
cd $TOP/u-boot

# R5 SPL -> tiboot3.bin + sysfw.itb
make O=$OUT/u-boot-r5 j721e_beagleboneai64_r5_defconfig
make O=$OUT/u-boot-r5 -j$(nproc) \
  CROSS_COMPILE=arm-linux-gnueabihf- \
  BINMAN_INDIRS=$TIFW

# A72 -> tispl.bin_unsigned + u-boot.img_unsigned
make O=$OUT/u-boot-a72 j721e_beagleboneai64_a72_defconfig
make O=$OUT/u-boot-a72 -j$(nproc) \
  CROSS_COMPILE=aarch64-linux-gnu- \
  BL31=$OUT/tfa/k3/generic/release/bl31.bin \
  TEE=$OUT/optee/core/tee-raw.bin \
  BINMAN_INDIRS=$TIFW
```

`BL31`, `TEE` and `BINMAN_INDIRS` must be **absolute** paths (or correct
relative to the U-Boot source dir). Each U-Boot build took ~35–50 s.

### 6b. In-tree

Same commands without `O=`. Because both builds share the one source tree,
you must clean between them:

```bash
cd $TOP/u-boot
make distclean
make j721e_beagleboneai64_r5_defconfig
make -j$(nproc) CROSS_COMPILE=arm-linux-gnueabihf- BINMAN_INDIRS=$TIFW
mkdir -p $OUT/deploy && cp -L tiboot3.bin sysfw.itb $OUT/deploy/   # save before cleaning!

make distclean
make j721e_beagleboneai64_a72_defconfig
make -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu- \
  BL31=$OUT/tfa/k3/generic/release/bl31.bin \
  TEE=$OUT/optee/core/tee-raw.bin BINMAN_INDIRS=$TIFW
cp tispl.bin_unsigned u-boot.img_unsigned $OUT/deploy/
```

## 7. Which output files to boot

| Copy this | To the FAT boot partition as | Notes |
|---|---|---|
| R5 `tiboot3.bin` | `tiboot3.bin` | symlink → `tiboot3-j721e-gp-evm.bin`; use `cp -L` |
| R5 `sysfw.itb` | `sysfw.itb` | symlink → `sysfw-j721e-gp-evm.itb`; **required** on J721E |
| A72 `tispl.bin_unsigned` | `tispl.bin` | a plain `tispl.bin` is **not** produced |
| A72 `u-boot.img_unsigned` | `u-boot.img` | **not** the plain `u-boot.img` next to it — that is the signed-flow image and won't boot this board |

binman's `*-gp-evm*` names reflect the GP (general-purpose) silicon flow it
built for; ignore the `*-capsule.bin` files (EFI capsule updates).

Quick checks:

```bash
ls -lL $OUT/u-boot-r5/tiboot3.bin $OUT/u-boot-r5/sysfw.itb \
       $OUT/u-boot-a72/tispl.bin_unsigned $OUT/u-boot-a72/u-boot.img_unsigned
strings $OUT/u-boot-a72/u-boot.img_unsigned | grep -m1 'U-Boot 20'
# e.g. U-Boot 2026.01-00005-g5c82fb688432   (a "-dirty" suffix = uncommitted changes)
```

Tested sizes at the pinned versions: `tiboot3.bin` 213081, `sysfw.itb`
268978, `tispl.bin_unsigned` 1030459, `u-boot.img_unsigned` 1256067 bytes.

Deploying them: [`../../skills/deploy-and-test/SKILL.md`](../../skills/deploy-and-test/SKILL.md).

## 8. Cleaning

| Command | Removes | Keeps |
|---|---|---|
| `make clean` | objects and most generated files | `.config`, so `make` rebuilds without a defconfig |
| `make mrproper` | `clean` + `.config` and generated headers | — |
| `make distclean` | `mrproper` + editor/patch backup files | — |

For out-of-tree builds add the same `O=`, e.g. `make O=$OUT/u-boot-a72 clean`.

**Two gotchas, both seen while testing:**

1. **`distclean` does not remove binman's outputs.** After an in-tree
   build, `make distclean` left 47 files in the source root, including a
   stale `tiboot3.bin`, `sysfw.itb`, `*.pem` keys and `*-cfg.bin`. In an
   `O=` dir, 62 entries remained. So:
   - `O=` build → just delete the directory: `rm -rf $OUT/u-boot-r5`.
   - In-tree build → after `make distclean`, list the ignored leftovers,
     **read the list**, then delete them:
     ```bash
     git clean -ndX      # dry run: what would go
     git clean -fdX      # delete ignored files (only after checking the list)
     ```
     `-X` deletes *only* git-ignored files, but that includes any ignored
     directory, e.g. a `build/` folder or caches you made yourself.
2. **`O=` needs a clean source tree.** If an in-tree `.config` exists,
   `make O=...` passes the defconfig step and then fails:
   ```
   .../u-boot is not clean, please run 'make mrproper'
   ```
   Run `make mrproper` in the source dir (it does not touch `O=` dirs).

## 9. Changing U-Boot and rebuilding

```bash
make O=$OUT/u-boot-a72 menuconfig          # interactive config (needs libncurses-dev)
make O=$OUT/u-boot-a72 -j$(nproc) CROSS_COMPILE=aarch64-linux-gnu- \
  BL31=... TEE=... BINMAN_INDIRS=$TIFW     # incremental rebuild, same args every time
make O=$OUT/u-boot-a72 savedefconfig       # -> $OUT/u-boot-a72/defconfig, minimal form
cp $OUT/u-boot-a72/defconfig configs/j721e_beagleboneai64_a72_defconfig   # to make it permanent
```

- `make clean` keeps `.config`; `savedefconfig` of an unmodified config
  reproduces the shipped defconfig exactly (both checked).
- Pass `CROSS_COMPILE`, `BL31`, `TEE` and `BINMAN_INDIRS` on **every**
  `make` that builds — they are not remembered in `.config`.
- After changing a defconfig, re-run the `..._defconfig` step.
- Board code: `board/beagle/beagleboneai64/beagleboneai64.c`; default env:
  `board/beagle/beagleboneai64/beagleboneai64.env`; DTs:
  `arch/arm/dts/k3-j721e-r5-beagleboneai64.dts` (R5) and
  `dts/upstream/src/arm64/ti/k3-j721e-beagleboneai64.dts` (A72).
- In this workspace, U-Boot changes go into the `sources/u-boot` submodule
  (`code-locker/u-boot`); bump the pointer and `versions.lock` together —
  see `skills/git-workflow/`.

## 10. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `Unknown entry type 'ti-board-config'` ... `No module named 'yamllint'` | a virtualenv is active (binman uses its `python3`), or `yamllint` / `python3-pyelftools` / `swig` missing — `deactivate`, install from apt |
| `Image 'ti-spl_unsigned' is missing external blobs and is non-functional: atf-bl31 tee-os` (make exits 2) | `BL31=` / `TEE=` not given or wrong path |
| `Image 'sysfw_gp' is missing external blobs and is non-functional: ti-fs.bin` (make exits 2) | `BINMAN_INDIRS` missing or not pointing at `ti-linux-firmware` |
| `... is not clean, please run 'make mrproper'` | in-tree build leftovers while using `O=` — `make mrproper` in the source dir |
| `arm-linux-gnueabihf-gcc: not found` | install `gcc-arm-linux-gnueabihf`, or fix the `CROSS_COMPILE` prefix |
| R5 SPL banner on serial, then hang | `sysfw.itb` missing from the boot partition |
| SPL runs, U-Boot proper doesn't start | signed `u-boot.img` copied instead of `u-boot.img_unsigned` |
| old U-Boot still boots | stale `tiboot3.bin` left in the source root by `distclean` was copied — see §8 |

The automated equivalent of all of this is
[`../../scripts/build-uboot.sh`](../../scripts/build-uboot.sh) (outputs in
`build/deploy/`); see [BUILD.md](BUILD.md).
