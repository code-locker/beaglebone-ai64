# Skill: Building the BeagleBone AI-64 boot chain & kernel

What I learned bringing up the TI TDA4VM (J721E) boot flow and kernel from source.

## The TDA4VM / J721E boot flow

The SoC is multi-core and boots in stages across different cores:

1. **ROM code** on the **R5F** (Cortex-R5) loads **`tiboot3.bin`**
   (U-Boot R5 SPL + TI system firmware / DM + sysfw).
2. R5 SPL starts the **A72** (Cortex-A72) and loads **`tispl.bin`**, which bundles:
   - **TF-A BL31** (secure monitor, EL3)
   - **OP-TEE BL32** (trusted execution environment)
   - **U-Boot SPL** (A72)
3. U-Boot SPL loads **`u-boot.img`** (U-Boot proper) → boots the Linux kernel.

So building the boot chain means building **four** things and stitching them:
TF-A → OP-TEE → U-Boot-R5 (tiboot3) → U-Boot-A72 (tispl + u-boot.img).

## Key facts / gotchas

- **Two defconfigs**, not one: `j721e_beagleboneai64_r5_defconfig` (R5, produces
  tiboot3) and `j721e_beagleboneai64_a72_defconfig` (A72, produces tispl/u-boot.img).
- **Two cross-compilers**: `arm-linux-gnueabihf-` for the 32-bit R5 & OP-TEE,
  `aarch64-linux-gnu-` for the 64-bit A72 / TF-A / U-Boot / kernel.
- **`BINMAN_INDIRS`** must point at the `ti-linux-firmware` checkout — binman
  pulls the DM firmware and sysfw blobs from there at U-Boot build time.
- TF-A for K3 uses `PLAT=k3 TARGET_BOARD=generic SPD=opteed`; the `SPD=opteed`
  is what wires OP-TEE in as BL32.
- OP-TEE platform is `PLATFORM=k3-j721e CFG_ARM64_core=y`.
- The **kernel** is built with RobertCNelson's `arm64-multiplatform` scripts,
  which download linux-stable + patches + a kernel.org gcc toolchain — you don't
  clone the kernel directly.
- On BBAI64 the first-stage blob is the **HS-FS** variant (`tiboot3-*-hs-fs-*.bin`).

## The reproducible-build lesson

Pin every upstream commit (see `versions.lock`). A "known-good" image is only
reproducible if TF-A, OP-TEE, ti-linux-firmware, U-Boot, and the kernel are all
at exact SHAs — bumping any one silently can change the resulting binaries.

## Reference

- Board SRM: `docs/upstream/BBAI64-System-Reference-Manual.pdf`
- My build notes: `docs/upstream/uboot-bbai64-build-steps.pdf`
- Master build guide: `docs/build/BUILD.md`
