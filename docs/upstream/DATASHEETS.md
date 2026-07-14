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

> To keep vendor PDFs handy offline, download them into this folder — they are
> covered by `*.pdf` staying **un-ignored** here, but do not push TI/Arm PDFs to
> the public repo to respect their redistribution terms.
