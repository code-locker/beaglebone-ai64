# TFTP / NFS boot — BeagleBone AI-64

Boot the kernel and device tree over the network from U-Boot, so a freshly
built kernel can be tested without touching the SD card. The boot chain
(`tiboot3.bin`, `sysfw.itb`, `tispl.bin`, `u-boot.img`) still comes from
SD/eMMC — only Linux is fetched over TFTP. The root filesystem can stay on
the SD card or be mounted over NFS.

Values below were checked against the pinned sources (`versions.lock`):
U-Boot `v2026.01-Beagle` (`include/env/ti/ti_common.env`,
`board/beagle/beagleboneai64/beagleboneai64.env`) and the
`k3-j721e-beagleboneai64.dts` reserved-memory map.

## Recommended load addresses

Use the board's default U-Boot environment variables rather than hard-coded
numbers — they are already set to these values:

| What | Variable | Address | Room before next region |
|---|---|---|---|
| Kernel `Image` | `kernel_addr_r` / `loadaddr` | `0x82000000` | 96 MiB (up to `0x88000000`) |
| Device tree (`.dtb`) | `fdt_addr_r` / `fdtaddr` | `0x88000000` | 512 KiB |
| DT overlays (`.dtbo`) | `fdtoverlay_addr_r` / `dtboaddr` | `0x89000000` | — |
| initrd / ramdisk | `ramdisk_addr_r` / `rdaddr` | `0x88080000` | ~127 MiB (to `0x90000000`) |
| Boot script | `scriptaddr` | `0x80000000` | — |
| PXE / extlinux file | `pxefile_addr_r` | `0x80100000` | — |
| FIT image (`fitImage`) | `addr_fit` | `0x90000000` | ~232 MiB (to OP-TEE) |
| Decompression buffer for `Image.gz` | `kernel_comp_addr_r` | `0x85000000` (size `kernel_comp_size=0x20000000`) | — |

Note that `fdtoverlay_addr_r` (`0x89000000`) sits inside the ramdisk window —
don't load overlays and a large initrd at the same time with these defaults.

### Regions you must not load over

| Range | Owner |
|---|---|
| `0x80000000`–`0x81ffffff` | early boot (A72 SPL ran at `0x80080000`, FIT staging at `0x81000000`); free once U-Boot proper is running, used for scripts |
| `0x9e800000`–`0x9fffffff` | **OP-TEE** secure DDR (reserved, faults if touched) |
| `0xa0000000`–`0xabbfffff` | remote-core carve-outs: MCU/main R5F, C66x, C7x, IPC |
| top of DDR | relocated U-Boot itself, its heap and stack |

So **all images must fit in `0x80000000`–`0x9e7fffff`**. Today's kernel
`Image` is ~40 MiB, which fits comfortably at `0x82000000`. If the
uncompressed `Image` ever grows past ~96 MiB it will overwrite the DTB — move
`fdt_addr_r` / `ramdisk_addr_r` up (staying below `0x9e800000`), and keep in
mind `CONFIG_SYS_BOOTM_LEN=0x8000000` (128 MiB) caps what `booti` will unpack.

Prefer the uncompressed `Image`: it boots in place. `Image.gz` also works
(`booti` unpacks it via `kernel_comp_addr_r`) but costs a copy.

## Host setup (Debian/Ubuntu)

```bash
sudo apt install tftpd-hpa
# /etc/default/tftpd-hpa: TFTP_DIRECTORY="/srv/tftp"
sudo mkdir -p /srv/tftp/bbai64 && sudo chown -R "$USER" /srv/tftp
sudo systemctl restart tftpd-hpa

# copy this workspace's build outputs
V=6.18.38-arm64-k3-r45            # see build/kernel/
cp build/kernel/$V.Image /srv/tftp/bbai64/Image
mkdir -p /tmp/dtbs-$V && tar -xf build/kernel/$V-dtbs.tar.zst -C /tmp/dtbs-$V
cp $(find /tmp/dtbs-$V -name k3-j721e-beagleboneai64.dtb) /srv/tftp/bbai64/
```

Check from the host: `tftp localhost -c get bbai64/Image /tmp/x && ls -l /tmp/x`.
Allow UDP 69 through any firewall.

## U-Boot: one-off boot (rootfs on SD card)

Stop autoboot on the serial console (115200 8N1, press a key), then:

```
=> setenv serverip 192.168.1.10          # your TFTP host
=> setenv autoload no                    # dhcp must not auto-TFTP ${bootfile}
=> dhcp                                  # or: setenv ipaddr 192.168.1.50
=> ping ${serverip}
=> tftp ${kernel_addr_r} bbai64/Image
=> tftp ${fdt_addr_r} bbai64/k3-j721e-beagleboneai64.dtb
=> setenv bootargs console=ttyS2,115200n8 earlycon=ns16550a,mmio32,0x02800000 root=/dev/mmcblk1p3 rw rootwait
=> booti ${kernel_addr_r} - ${fdt_addr_r}
```

- `root=`: replace `/dev/mmcblk1p3` with whatever `cat /proc/cmdline` shows on
  a normal SD boot (on eMMC it is `mmcblk0pN`).
- The `-` means "no initrd". With an initrd:
  `tftp ${ramdisk_addr_r} bbai64/initrd.img` and then
  `booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}`
  (run the `tftp` for the initrd last so `${filesize}` is its size).
- Kernel modules come from the rootfs — install the matching
  `$V-modules.tar.zst` there, or the TFTP'd kernel boots without them.

## NFS root (nothing on the SD card but the bootloaders)

The kernel config already has `CONFIG_ROOT_NFS`, `CONFIG_IP_PNP_DHCP`, the
AM65 CPSW Ethernet driver and the DP83867 PHY built in (`=y`), so no initrd is
needed.

Host:

```bash
sudo apt install nfs-kernel-server
sudo mkdir -p /srv/nfs/bbai64          # extract a Debian arm64 rootfs + modules here
echo '/srv/nfs/bbai64 *(rw,sync,no_subtree_check,no_root_squash)' | sudo tee -a /etc/exports
sudo exportfs -ra
```

U-Boot (after the two `tftp` commands above):

```
=> setenv bootargs console=ttyS2,115200n8 root=/dev/nfs rw nfsroot=${serverip}:/srv/nfs/bbai64,v3,tcp ip=dhcp rootwait
=> booti ${kernel_addr_r} - ${fdt_addr_r}
```

## Making it the default

```
=> setenv serverip 192.168.1.10
=> setenv autoload no
=> setenv netboot 'dhcp; tftp ${kernel_addr_r} bbai64/Image; tftp ${fdt_addr_r} bbai64/k3-j721e-beagleboneai64.dtb; setenv bootargs console=ttyS2,115200n8 root=/dev/nfs rw nfsroot=${serverip}:/srv/nfs/bbai64,v3,tcp ip=dhcp rootwait; booti ${kernel_addr_r} - ${fdt_addr_r}'
=> setenv bootcmd 'run netboot'
=> saveenv
```

To go back to the stock SD/eMMC boot: `env default -a; saveenv`.

Alternative: the default `boot_targets` already ends in `pxe`, so a
`pxelinux.cfg/` tree on the TFTP server (extlinux syntax) is picked up when
the SD/eMMC targets have nothing to boot.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `dhcp` times out / `ping` fails | cable in the wrong port, no DHCP server, or `serverip` on another subnet |
| `TFTP error: 'File not found'` | path is relative to `TFTP_DIRECTORY`; check with `tftp` from the host |
| `T T T ...` then timeout | host firewall blocks UDP 69 or the ephemeral data ports |
| `TFTP error: trying to overwrite reserved memory...` | image overlaps a reserved region or the next image — check the address table |
| Hang right after `Starting kernel ...` | DTB overwritten by an oversized kernel, or wrong `console=` — use `earlycon` as above |
| `VFS: Unable to mount root fs via NFS` | export path/permissions, or NFSv4-only server — keep `,v3,tcp` |
