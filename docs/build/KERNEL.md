# Kernel guide — cross-compile, modify, and test on the board

How the BeagleBone AI-64 kernel (linux-stable 6.18.38, `6.18.38-arm64-k3-r45`)
is built from this workspace, how to change it, and how to get it running on
the board. For kernel code that belongs to an application, see
[APP-KERNEL-CODE.md](APP-KERNEL-CODE.md).

> Status: written from the build scripts; the board-side steps (§5–6) are not
> yet verified on hardware — correct them after the first real boot.

## 1. How the build is put together

The kernel is built by RobertCNelson's **arm64-multiplatform** scripts, tracked
as the submodule `sources/arm64-multiplatform` (fork: `code-locker/arm64-multiplatform`).

| What | Where |
|---|---|
| version, branch, toolchain | `sources/arm64-multiplatform/version.sh` |
| linux-stable git clone (~6–8 GB) | `sources/arm64-multiplatform/ignore/linux-src/` (or `LINUX_GIT` in `system.sh`) |
| patched kernel source you edit | `sources/arm64-multiplatform/KERNEL/` |
| BeagleBoard / k3 patch set | `sources/arm64-multiplatform/patches/` + `patch.sh` |
| kernel config | `sources/arm64-multiplatform/patches/defconfig` |
| cross-compiler (gcc 15.2 nolibc, auto-downloaded) | `sources/arm64-multiplatform/dl/`; prefix recorded in `.CC` |
| outputs | `sources/arm64-multiplatform/deploy/` → collected into `build/kernel/` |

`build_kernel.sh` does: clone/update linux-stable → check out a fresh
`KERNEL/` → apply `patches/` → copy `patches/defconfig` → menuconfig (unless
`AUTO_BUILD=1`) → `make Image modules dtbs` → package modules/dtbs tarballs.

## 2. Cross-compile (first time)

Host packages: see [BUILD.md](BUILD.md) §0; packaging the `.deb` also needs `dpkg-dev`.

```bash
./scripts/build-kernel.sh
```

Close menuconfig without changes to keep the stock config. Outputs:

```
build/kernel/
  6.18.38-arm64-k3-r45.Image
  6.18.38-arm64-k3-r45-dtbs.tar.zst
  6.18.38-arm64-k3-r45-modules.tar.zst
  config-6.18.38-arm64-k3-r45
build/apps/<app>/kernel/*.ko        # every application's kernel part (APP_MODULES=0 skips)
```

## 3. Change the kernel — edit → rebuild loop

```bash
$EDITOR sources/arm64-multiplatform/KERNEL/<file>
REBUILD=1 ./scripts/build-kernel.sh      # incremental: tools/rebuild.sh, keeps KERNEL/ edits
```

**Never** run plain `./scripts/build-kernel.sh` (or `build_kernel.sh` /
`build_deb.sh` in the submodule) with uncommitted work in `KERNEL/` — they
re-check-out and re-patch the tree and the edits are gone.

Common edit targets:

| Change | Where |
|---|---|
| board device tree | `KERNEL/arch/arm64/boot/dts/ti/k3-j721e-beagleboneai64.dts` (+ SoC `k3-j721e*.dtsi`) |
| config option | menuconfig during the rebuild; saved to `patches/defconfig` |
| driver | `KERNEL/drivers/...` |

Equivalent manual cross-compile inside the tree (what the scripts run):

```bash
cd sources/arm64-multiplatform && . ./.CC && . ./version.sh
make -C KERNEL -j"$(nproc)" ARCH=arm64 LOCALVERSION="${BUILD}" CROSS_COMPILE="${CC}" Image modules dtbs
```

## 4. Make a change permanent

`KERNEL/` is regenerated on every full build, so a change only survives as a
patch in the fork:

```bash
cd sources/arm64-multiplatform/KERNEL
git add -A && git commit -m "bbai64: <change>"           # KERNEL/ is its own git tree
git format-patch -1 -o ../patches/local/
cd ..
# once: make patch.sh apply every patches/local/*.patch (in order) — add the line
#   dir 'local'
# at the end of patch.sh, after the existing `cc33xx_drivers` call.
git add patches/ patch.sh && git commit -m "Add local patch: <change>"
git push origin <branch>                                  # → code-locker/arm64-multiplatform
cd ../.. && git add sources/arm64-multiplatform          # bump the pointer; update versions.lock
```

Verify with a full (non-`REBUILD`) build that the patch applies cleanly.

## 5. Install on the board

Fastest reliable path on the stock BeagleBoard Debian image: install the kernel
as a Debian package — the image's kernel hooks install it the same way they
install BeagleBoard's own kernel packages, and the old kernel stays as fallback.

```bash
BOARD=debian@<board-ip> ./scripts/deploy-kernel.sh --reboot
```

It runs `make bindeb-pkg` in the existing `KERNEL/` tree (same options as
`build_deb.sh`, without re-patching), copies `build/kernel/linux-image-*.deb`
to the board, `dpkg -i`'s it, and reboots.

Alternative (offline / board not booting): mount the SD card and copy the files
from `build/kernel/` per `skills/deploy-and-test/SKILL.md`.

## 6. Test on the board

Connect the serial console first (3.3 V USB-UART on the debug header,
`picocom -b 115200 /dev/ttyUSB0`) so a failed boot is visible.

```bash
uname -r                         # 6.18.38-arm64-k3-r45 (or your LOCALVERSION)
cat /proc/cmdline
dmesg --level=err,warn | head -50
zgrep CONFIG_<OPTION> /proc/config.gz 2>/dev/null || grep CONFIG_<OPTION> /boot/config-$(uname -r)
ls /sys/firmware/devicetree/base/ # DT change visible?
```

Rollback: choose the previous kernel at the boot menu on the serial console, or
`sudo apt remove linux-image-<bad-version>` from a working boot.
