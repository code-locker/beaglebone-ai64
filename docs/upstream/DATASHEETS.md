# Reference documents & datasheets

Documents used while working on the BeagleBone AI-64. Only openly-licensed
documents are stored in this repo directly. Vendor datasheets/TRMs are
copyrighted and freely downloadable but **not** open-licensed, so they are
linked here rather than redistributed.

## Included in this repo (open license)

| File | Description | License / Source |
|------|-------------|------------------|
| [BBAI64-System-Reference-Manual.pdf](BBAI64-System-Reference-Manual.pdf) | BeagleBone AI-64 System Reference Manual (board pinout, power, connectors) | CC-BY-SA 4.0 — BeagleBoard.org open hardware docs |
| [uboot-bbai64-build-steps.pdf](uboot-bbai64-build-steps.pdf) | My own notes on the U-Boot build sequence | MIT (authored here) |

## Linked only (vendor copyright — download from source)

| Document | What it covers | Official source |
|----------|----------------|-----------------|
| TDA4VM / DRA829 / J721E Technical Reference Manual (TRM) | SoC registers, subsystems, boot ROM | https://www.ti.com/lit/pdf/spruil1 (TI product page: https://www.ti.com/product/TDA4VM) |
| TDA4VM Datasheet | Electrical specs, pin muxing | https://www.ti.com/product/TDA4VM |
| Arm Cortex-A72 MPCore Technical Reference Manual | A72 core internals | https://developer.arm.com/documentation/100095/latest/ |
| Arm Cortex-A72 Software Optimization Guide | Perf tuning | https://developer.arm.com/documentation/ |

## Key upstream references

- BeagleBone AI-64 wiki: https://docs.beagleboard.org/latest/boards/beaglebone/ai-64/
- BeagleBoard image releases: https://www.beagleboard.org/distros
- TI Processor SDK (J721E): https://www.ti.com/tool/PROCESSOR-SDK-J721E
- U-Boot (BeagleBoard fork): https://github.com/beagleboard/u-boot
- Kernel build scripts: https://github.com/RobertCNelson/arm64-multiplatform

## Getting the TRM locally

The TI link serves a ZIP (rev D, `spruil1d.zip`, ~325 MB), not a PDF. Extract
it into `TDA4VM-TRM/` here — that folder is git-ignored, so the PDFs stay local:

```bash
cd docs/upstream
curl -L -o spruil1d.zip https://www.ti.com/lit/pdf/spruil1
unzip spruil1d.zip -d TDA4VM-TRM && rm spruil1d.zip
```

| File in `TDA4VM-TRM/` | Contents |
|---|---|
| `SPRUIL_DRA829_TDA4VM Technical Reference Manual.pdf` | main TRM, 3535 pages — every subsystem, boot, memory map |
| `DRA829TDA4VM_Registers_Part1..5.pdf` | full register maps (bit-level tables) |

Never commit these: TI's terms don't allow redistribution, and
`Registers_Part2.pdf` (101 MB) is over GitHub's 100 MB file limit anyway.
Other vendor PDFs dropped in this folder are **not** ignored — keep them out
of commits too.
