---
name: beaglebone-embedded-linux
description: Background on the TI TDA4VM / J721E (BeagleBone AI-64) boot flow — ROM → R5 SPL (tiboot3) → TF-A/OP-TEE/A72 SPL (tispl) → U-Boot → Linux — plus the toolchains, defconfigs, and reproducibility rules behind this repo. Use when reasoning about boot stages, firmware components, or why the build is structured as it is.
---

Read [README.md](README.md) in this folder — it holds the full notes.
For the actual commands use `build-image`; for hardware, `deploy-and-test`.
