# Standalone kernel build — BeagleBone AI-64

How to cross-compile the BeagleBone AI-64 (TI TDA4VM / J721E) Linux kernel
from a plain kernel.org source tree with ordinary `make`, without
`scripts/build-kernel.sh` or RobertCNelson's `arm64-multiplatform` scripts.
Use it to build a kernel on any PC, to try a different kernel version, or to
understand what the workspace scripts do. The workspace flow (patched tree,
`.deb` install on the board) is in [KERNEL.md](KERNEL.md).

**Tested** on 2026-10-30: Ubuntu 22.04.5, Ubuntu cross GCC 11.4.0, 16
threads, `linux-6.18.38.tar.xz` from kernel.org with the BeagleBoard config.
Every command below was run; results are noted where they matter.

## 1. What you get

| Output (in the build dir `$O`) | What it is | Goes to (on the board) |
|---|---|---|
| `arch/arm64/boot/Image` | uncompressed arm64 kernel | `/boot/vmlinuz-<release>` |
| `arch/arm64/boot/dts/ti/k3-j721e-beagleboneai64.dtb` | board device tree | `/boot/dtbs/<release>/ti/` |
| `*.ko` → `modules_install` | loadable modules | `/lib/modules/<release>/` |
| `include/config/kernel.release` | the `<release>` string, e.g. `6.18.38-bbai64` | — |

`<release>` = kernel version + `LOCALVERSION`. Modules only load into a kernel
with exactly the same release string and config.

## 2. Host prerequisites

```bash
sudo apt update
sudo apt install -y build-essential bc bison flex libssl-dev libelf-dev \
  libncurses-dev kmod cpio rsync xz-utils zstd \
  gcc-aarch64-linux-gnu wireless-regdb
# optional: dwarves  (pahole, only if you enable CONFIG_DEBUG_INFO_BTF)
#           dpkg-dev (only for `make bindeb-pkg`)
```

### Cross compiler

Every piece of the kernel runs on the Cortex-A72 (AArch64), so only **one**
compiler is needed (unlike U-Boot, which also needs a 32-bit one for the R5).

| Option | `CROSS_COMPILE=` | Notes |
|---|---|---|
| Ubuntu/Debian package `gcc-aarch64-linux-gnu` | `aarch64-linux-gnu-` | used for this test (GCC 11.4.0) |
| kernel.org crosstool (what the workspace uses: GCC 15.2.0 nolibc) | `/path/to/gcc-15.2.0-nolibc/aarch64-linux/bin/aarch64-linux-` | download from `mirrors.edge.kernel.org/pub/tools/crosstool/files/bin/x86_64/` |

`CROSS_COMPILE` is a prefix — make appends `gcc`, `ld`, `objcopy`, ...; it
ends with `-`. Linux 6.18 needs GCC ≥ 8. `ARCH=arm64` must be passed on
**every** `make` invocation (config, build, install, clean), otherwise make
uses your host's x86 config.

## 3. Get the source

Kernel.org stable release, matching `versions.lock` (`linux-kernel v6.18.38`):

```bash
mkdir -p ~/bbai64-kernel && cd ~/bbai64-kernel
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.18.38.tar.xz
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc
grep ' linux-6.18.38.tar.xz$' sha256sums.asc | sha256sum -c -    # -> OK
tar -xf linux-6.18.38.tar.xz
export K=$PWD/linux-6.18.38          # source tree
export O=$PWD/out                    # build dir (out-of-tree)
export CC=aarch64-linux-gnu-
```

Or with git: `git clone --depth 1 -b v6.18.38
https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git`.

> **Vanilla vs BeagleBoard kernel.** The kernel the board ships with
> (`6.18.38-arm64-k3-r45`) is this same stable release **plus** BeagleBoard
> patches (`sources/arm64-multiplatform/patches/`: cc33xx Wi-Fi/BT, extra
> overlays, Beagle logo, ...). Upstream already supports the BBAI64 (SoC
> drivers, `k3-j721e-beagleboneai64.dts`), so vanilla is fine for core
> bring-up and driver work; you won't have the Beagle-only extras. For those,
> use the workspace's patched `sources/arm64-multiplatform/KERNEL/` as `$K`
> — the commands below are identical.

## 4. Configure

Always build out-of-tree with `O=` — the source stays clean and you can keep
several configs side by side. Pick one config:

### 4a. BeagleBoard config (recommended — same options as the board's kernel)

```bash
mkdir -p $O
cp <workspace>/sources/arm64-multiplatform/patches/defconfig $O/.config
#   standalone: the same file is patches/defconfig in
#   https://github.com/RobertCNelson/arm64-multiplatform (branch v6.18.x-arm64-k3)
#   or /boot/config-<release> copied off a running board
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC olddefconfig
```

`olddefconfig` keeps every option the source supports and drops the rest. On
vanilla 6.18.38 with GCC 11 it dropped 33 of 5530 `=y/m` options — all
expected: Rust (no `rustc` installed), compiler-feature probes (`CC_HAS_*`,
GCC 11 vs 15) and the Beagle-only drivers (`CC33XX`, `BT_TI_UART`,
`MSPM0_I2C`, `LOGO_BEAGLE_CLUT224`). Every BBAI64 essential stays on
(`ARCH_K3`, `TI_SCI_PROTOCOL`, `TI_K3_AM65_CPSW_NUSS`, `SERIAL_8250_OMAP`,
`MMC_SDHCI_AM654`, `ROOT_NFS`).

**This config builds firmware into the kernel image** —
`CONFIG_EXTRA_FIRMWARE="regulatory.db regulatory.db.p7s cadence/mhdp8546.bin"`
from `$K/firmware/`. A kernel.org tree has no such files and the build fails
~20 min in with:

```
No rule to make target '.../firmware/regulatory.db', needed by
'drivers/base/firmware_loader/builtin/regulatory.db.gen.o'.  Stop.
```

Provide them before building (`regulatory.db*` from the `wireless-regdb`
package, `mhdp8546.bin` — the DisplayPort bridge firmware — from
`ti-linux-firmware`, cloned for U-Boot):

```bash
mkdir -p $K/firmware/cadence
cp /lib/firmware/regulatory.db /lib/firmware/regulatory.db.p7s $K/firmware/
cp <workspace>/sources/ti-linux-firmware/cadence/mhdp8546.bin $K/firmware/cadence/
```

(Or drop them: `$K/scripts/config --file $O/.config --set-str EXTRA_FIRMWARE ""`
then `olddefconfig` — the drivers will then load these files from
`/lib/firmware` on the board at runtime instead.)

### 4b. Upstream arm64 defconfig

```bash
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC defconfig
```

Generic config for all arm64 boards (4546 `=y/m` options, fewer modules,
faster). Checked: it has `ARCH_K3`, `TI_SCI_PROTOCOL`,
`TI_K3_AM65_CPSW_NUSS`, `DP83867_PHY`, `SERIAL_8250_OMAP`,
`MMC_SDHCI_AM654`, `ROOT_NFS`, and builds the BBAI64 DTB. No embedded
firmware, so no extra files needed.

### Adjusting the config

```bash
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC menuconfig      # interactive, plain terminal only
$K/scripts/config --file $O/.config --enable  CONFIG_FOO        # scripted
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC olddefconfig     # resolve dependencies after edits
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC savedefconfig    # -> $O/defconfig (minimal form)
```

## 5. Build

```bash
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC LOCALVERSION=-bbai64 \
     -j$(nproc) Image modules dtbs
```

- `LOCALVERSION=-bbai64` makes the release `6.18.38-bbai64`, so it can't be
  confused with the board's stock `6.18.38-arm64-k3-r45` modules. Pass the
  same value on every build/install command (or set `CONFIG_LOCALVERSION`).
- Build only the board DTB (seconds): `... ti/k3-j721e-beagleboneai64.dtb`.
- Rebuild after an edit: run the same command again — make only rebuilds
  what changed.
- Logging with `| tee` is fine for the build, but don't pipe `menuconfig`.

Tested result (BeagleBoard config, GCC 11.4, 16 threads): **~49 min**, no
compiler warnings; `Image` 47 MiB (`Linux version 6.18.38-bbai64 ...
SMP PREEMPT_RT`), 3118 modules, `k3-j721e-beagleboneai64.dtb` 110 KB. The
upstream `defconfig` builds far fewer modules and is correspondingly faster.

Check:

```bash
file $O/arch/arm64/boot/Image      # Linux kernel ARM64 boot executable Image
cat  $O/include/config/kernel.release
strings $O/arch/arm64/boot/Image | grep -m1 'Linux version'
```

## 6. Install into a staging dir

```bash
STAGE=$PWD/stage
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC LOCALVERSION=-bbai64 \
     INSTALL_MOD_PATH=$STAGE INSTALL_MOD_STRIP=1 modules_install
make -C $K O=$O ARCH=arm64 CROSS_COMPILE=$CC \
     INSTALL_DTBS_PATH=$STAGE/boot/dtbs/$(cat $O/include/config/kernel.release) dtbs_install
cp $O/arch/arm64/boot/Image $STAGE/boot/vmlinuz-$(cat $O/include/config/kernel.release)
cp $O/.config               $STAGE/boot/config-$(cat $O/include/config/kernel.release)
```

`INSTALL_MOD_STRIP=1` strips debug info from the modules (much smaller).
`modules_install` without `INSTALL_MOD_PATH` would try to install into your
**host's** `/lib/modules` — always set it.

Tested: `modules_install` took ~1.5 min and produced 50 MB in
`$STAGE/lib/modules/6.18.38-bbai64/`, including `modules.dep` (the host's
`depmod` from `kmod` runs automatically). The BeagleBoard config sets
`CONFIG_MODULE_COMPRESS_XZ`, so installed modules are `*.ko.xz`. The
`build` symlink in there points at `$O` on your PC — harmless on the board,
just dangling. `dtbs_install` put all TI DTBs (5.1 MB) under `ti/`.

## 7. Put it on the board

> Not yet verified on hardware — the PC-side steps above were tested; correct
> this section after the first real boot.

The stock BeagleBoard Debian image boots via
`/boot/firmware/extlinux/extlinux.conf`. Keep the stock kernel as a fallback
— add a new entry rather than overwriting:

```bash
# from the PC, board reachable as debian@<board-ip>
rsync -a $STAGE/boot/ debian@<board-ip>:/tmp/kboot/
rsync -a $STAGE/lib/modules/ debian@<board-ip>:/tmp/kmod/
# on the board
sudo cp -r /tmp/kboot/* /boot/ && sudo cp -r /tmp/kmod/* /lib/modules/
sudo depmod <release>
```

Then point an `extlinux.conf` label at `/boot/vmlinuz-<release>` and
`fdtdir /boot/dtbs/<release>/`, or TFTP-boot `Image` + the DTB without
installing anything ([TFTP-BOOT.md](TFTP-BOOT.md)). On the stock image the
simplest equivalent is a Debian package — `make ... bindeb-pkg` — installed
with `dpkg -i`, as `scripts/deploy-kernel.sh` does ([KERNEL.md](KERNEL.md) §5).

Check after boot: `uname -r` shows `<release>`, `lsmod` lists modules,
`dmesg --level=err,warn` has no new errors.

## 8. Cleaning

| Command (add `-C $K O=$O ARCH=arm64`) | Removes | Keeps |
|---|---|---|
| `make clean` | objects, `Image` (checked) | `.config` (checked) |
| `make mrproper` | `clean` + `.config` and generated files | — |
| `make distclean` | `mrproper` + editor backup / patch files | — |

For an `O=` build the simplest full clean is `rm -rf $O` (save `.config`
first). If you ever built **in-tree** (no `O=`), later `O=` builds stop with
`*** The source tree is not clean, please run 'make ARCH=arm64 mrproper'`
(checked) — run that in `$K`.

## 9. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| `No rule to make target '.../firmware/regulatory.db'` | BeagleBoard config embeds firmware — §4a |
| config looks like x86, `arch/x86` gets built | `ARCH=arm64` missing from a `make` command |
| `aarch64-linux-gnu-gcc: not found` | install `gcc-aarch64-linux-gnu` or fix the `CROSS_COMPILE` prefix |
| `Invalid module format` / `disagrees about version of symbol` on the board | module built for a different release/config — rebuild modules with the same `LOCALVERSION` and `.config` as the running kernel |
| Rust options vanish after `olddefconfig` | no Rust toolchain on the host; those drivers are optional on BBAI64 |
| hang after `Starting kernel ...` | wrong DTB, or `console=ttyS2,115200n8` missing from `bootargs` |
