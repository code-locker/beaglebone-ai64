---
name: kernel-dev
description: Modify, rebuild, and deploy the BeagleBone AI-64 Linux kernel (6.18.x-k3 via RobertCNelson arm64-multiplatform) — kernel config changes, device-tree edits, in-tree drivers, out-of-tree modules — and record the change in the code-locker fork. Use for any kernel, driver, DTS, or module work.
---

# Kernel development

> Status: rebuild loop follows the arm64-multiplatform scripts; out-of-tree
> toolchain path and deploy steps not yet verified here.

Kernel tree is produced by `sources/arm64-multiplatform` (submodule → `code-locker/arm64-multiplatform`).
After the first `./scripts/build-kernel.sh`, the actual linux source is in
`sources/arm64-multiplatform/KERNEL/`.

## Edit → rebuild loop

```bash
cd sources/arm64-multiplatform
$EDITOR KERNEL/<file>                 # driver / dts / Kconfig change
./tools/rebuild.sh                    # incremental rebuild (keeps your KERNEL/ edits)
```

- **Do not** re-run `./build_kernel.sh` after editing `KERNEL/` — it re-extracts
  and re-patches the tree and discards uncommitted edits.
- Config: `rebuild.sh` opens menuconfig; the resulting config is saved to
  `patches/defconfig` — commit that if the change should persist.
- Board DTS: `KERNEL/arch/arm64/boot/dts/ti/k3-j721e-beagleboneai64*.dts*`.
- Persisting source edits: arm64-multiplatform applies `patches/` on a fresh
  build. Turn each `KERNEL/` change into a patch (`git -C KERNEL format-patch`)
  under `patches/` and wire it into `patch.sh`, otherwise it is lost on a clean build.

Then copy artifacts into the common dir: `./scripts/build-kernel.sh` collects
`deploy/` into `build/kernel/` (or copy manually).

## Out-of-tree module

```bash
make -C sources/arm64-multiplatform/KERNEL M=$PWD \
     ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- modules
```

Use the same toolchain the kernel was built with if you hit vermagic /
compiler-mismatch warnings (`sources/arm64-multiplatform/dl/gcc-*/bin/aarch64-linux-`).
Put module sources under `applications/<name>/` like any other app.

## Deploy & test

See `deploy-and-test` for copying `Image`, dtbs, and modules to the board.
Verify on target: `uname -a`, `dmesg | tail`, `modinfo <mod>`.

## Record it

```bash
cd sources/arm64-multiplatform
git switch -c feat/<thing> && git commit -am "<area>: <change>"
git push origin feat/<thing>          # → code-locker/arm64-multiplatform
cd ../.. && git add sources/arm64-multiplatform   # bump pointer
# update the arm64-multiplatform sha in versions.lock, commit on a develop feature branch
```
