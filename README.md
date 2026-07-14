# BeagleBone AI-64 — Embedded Linux Workspace

Personal, reproducible workspace for building and hacking the boot chain and
Linux kernel for the **BeagleBone AI-64** (TI TDA4VM / J721E, Cortex-A72).

Reference image this workspace tracks:

> **BBAI64 Debian 13.5 2026-05-19 XFCE (v6.18.x-k3)**

This repository holds **only plain source references, build scripts, docs, and my
own applications** — never compiled binaries or SD-card images. Everything
buildable is fetched from pinned upstream commits (see [`versions.lock`](versions.lock))
so a fresh clone reproduces the same output.

---

## Repository layout

```
beaglebone-ai64/
├── README.md                 # you are here
├── versions.lock             # exact upstream commits every build pins to
├── CONTRIBUTING.md           # branch model + how to PR upstream u-boot/kernel
├── GITHUB-SETUP.md           # one-time: create the GitHub repo + forks, push
│
├── docs/
│   ├── upstream/             # open-license reference docs (SRM) + datasheet links
│   ├── build/                # the master build guide (BUILD.md)
│   └── mine/                 # documents I write / publish
│
├── skills/                   # skills & know-how learned here, one topic per folder
│
├── applications/             # my own apps — application1, application2, …
│   └── _template/            # copy this to start a new app (README + CMake + steps)
│
├── sources/                  # git submodules → my forks of u-boot & kernel-build
│   ├── u-boot/               # submodule → code-locker/u-boot
│   └── arm64-multiplatform/  # submodule → code-locker/arm64-multiplatform
│
└── scripts/                  # bootstrap + build automation
    ├── bootstrap.sh          # init submodules + fetch firmware repos (pinned)
    ├── fetch-firmware.sh     # clone optee_os / tf-a / ti-linux-firmware (pinned)
    ├── build-uboot.sh        # TF-A + OP-TEE + u-boot → tiboot3/tispl/u-boot.img
    ├── build-kernel.sh       # RobertCNelson arm64 kernel build
    └── add-submodules.sh     # one-time helper to wire the submodules
```

## Quick start (after cloning)

```bash
git clone --recursive https://github.com/code-locker/beaglebone-ai64.git
cd beaglebone-ai64
./scripts/bootstrap.sh          # pulls firmware repos at pinned versions
./scripts/build-uboot.sh        # → build/deploy/{tiboot3.bin,tispl.bin,u-boot.img}
./scripts/build-kernel.sh       # → kernel Image + modules + dtbs
```

> If you forgot `--recursive`: `git submodule update --init --recursive`

Build outputs land under `build/` which is **git-ignored** — nothing compiled is
ever committed. See [docs/build/BUILD.md](docs/build/BUILD.md) for the full walkthrough.

## Target details

| Item        | Value                                             |
|-------------|---------------------------------------------------|
| Board       | BeagleBone AI-64                                   |
| SoC         | TI TDA4VM (J721E), dual Cortex-A72 + C7x/MMA + R5F |
| U-Boot      | `beagleboard/u-boot` v2026.01-Beagle              |
| Defconfigs  | `j721e_beagleboneai64_r5_defconfig` (R5, tiboot3), `j721e_beagleboneai64_a72_defconfig` (A72, tispl/u-boot) |
| Kernel      | linux-stable 6.18.38 via RobertCNelson `arm64-multiplatform` (`6.18.38-arm64-k3-r45`) |
| Secure FW   | TF-A + OP-TEE + ti-linux-firmware (DM/sysfw)      |

See [`versions.lock`](versions.lock) for exact commit SHAs.

## Branch model

- **`main`** — stable; only updated on a release (merge from `develop`).
- **`develop`** — day-to-day development happens here.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the workflow and how to open PRs against
upstream u-boot / kernel from the submodules.

## Licensing

- Code, scripts, and my own docs/apps in this repo: **MIT** (see [LICENSE](LICENSE)).
- Submodules (`sources/*`) keep their upstream licenses (u-boot: GPL-2.0, kernel: GPL-2.0).
- Reference PDFs in `docs/upstream/`: see [docs/upstream/DATASHEETS.md](docs/upstream/DATASHEETS.md)
  for each document's license and source.
