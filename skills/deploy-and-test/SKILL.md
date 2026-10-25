---
name: deploy-and-test
description: Put freshly built boot binaries, kernel, device trees, and modules onto a BeagleBone AI-64 SD card or live board, watch the serial console, and verify the boot. Use when testing a build on hardware, flashing an SD card, updating the kernel/u-boot on the board, or debugging a board that does not boot.
---

# Deploy to hardware & test

> Status: procedure drafted from the build outputs; not yet verified on the
> board. Correct it after the first real boot.

Always confirm the target device before writing to a block device — `lsblk` first,
and ask the user if there is any doubt about which `/dev/sdX` is the SD card.

## SD card baseline

Flash the reference image (`BBAI64 Debian 13.5 2026-05-19 XFCE (v6.18.x-k3)`)
from beagleboard.org once, then overwrite pieces with your builds:

```bash
lsblk                                         # identify the card, e.g. /dev/sdX
xzcat bbai64-*.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress
```

## Boot chain (U-Boot)

All four files to the FAT boot partition (partition 1):

```bash
sudo mount /dev/sdX1 /mnt
sudo cp build/deploy/{tiboot3.bin,sysfw.itb,tispl.bin,u-boot.img} /mnt/
sync && sudo umount /mnt
```

## Kernel

Inspect the card's boot config first (`/boot/firmware/extlinux/extlinux.conf`
or `/boot/uEnv.txt` on the rootfs) to see which kernel/dtb it loads, then install
alongside rather than over the working kernel:

```bash
V=6.18.38-arm64-k3-r45                        # from build/kernel/ filenames
ROOTFS=/mnt/rootfs                            # rootfs partition mounted here
sudo cp build/kernel/$V.Image  $ROOTFS/boot/vmlinuz-$V
sudo tar -xf build/kernel/$V-modules.tar.zst -C $ROOTFS/
sudo mkdir -p $ROOTFS/boot/dtbs/$V && sudo tar -xf build/kernel/$V-dtbs.tar.zst -C $ROOTFS/boot/dtbs/$V
```

Then add/point an extlinux label at the new kernel, keeping the old one as fallback.
On a running board the easier path is the Debian package: `(cd sources/arm64-multiplatform && ./build_deb.sh)`,
`scp` the `.deb`, `sudo dpkg -i` on the board.

## Serial console

3-pin UART debug header, 3.3 V TTL USB-serial adapter, **115200 8N1**:

```bash
picocom -b 115200 /dev/ttyUSB0
```

## Verify

```bash
uname -a                  # expected kernel version
cat /proc/cmdline
dmesg --level=err,warn
```

| Symptom | Likely cause |
|---|---|
| no output at all | tiboot3.bin wrong/missing, or wrong UART pins |
| R5 SPL banner then hang | `sysfw.itb` missing |
| SPL ok, U-Boot proper fails | signed `u-boot.img` used instead of `*_unsigned` |
| kernel panic: no rootfs / modules missing | modules not extracted for this version, or `root=` wrong |

Record findings from real boots in `docs/mine/notes/` and fold reusable ones back into this skill.
