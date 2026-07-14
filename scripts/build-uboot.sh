#!/usr/bin/env bash
#
# build-uboot.sh — build the BeagleBone AI-64 (J721E / TDA4VM) boot chain:
#   TF-A (BL31) + OP-TEE (BL32) + U-Boot R5 SPL + U-Boot A72
# Produces: build/deploy/{tiboot3.bin, tispl.bin, u-boot.img, sysfw.itb}
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/sources"
DEPLOY="${ROOT}/build/deploy"
JOBS="$(nproc)"

UBOOT="${SRC}/u-boot"
TFA="${SRC}/trusted-firmware-a"
OPTEE="${SRC}/optee_os"
TIFW="${SRC}/ti-linux-firmware"

export CROSS_COMPILE_32="${CROSS_COMPILE_32:-arm-linux-gnueabihf-}"
export CROSS_COMPILE_64="${CROSS_COMPILE_64:-aarch64-linux-gnu-}"

for d in "${UBOOT}" "${TFA}" "${OPTEE}" "${TIFW}"; do
  [ -d "${d}" ] || { echo "!! missing ${d}. Run ./scripts/bootstrap.sh first." >&2; exit 1; }
done
mkdir -p "${DEPLOY}"

echo "==> [1/4] TF-A (BL31)"
make -C "${TFA}" -j"${JOBS}" \
  CROSS_COMPILE="${CROSS_COMPILE_64}" ARCH=aarch64 \
  PLAT=k3 TARGET_BOARD=generic SPD=opteed

echo "==> [2/4] OP-TEE (BL32)"
make -C "${OPTEE}" -j"${JOBS}" \
  CROSS_COMPILE="${CROSS_COMPILE_32}" CROSS_COMPILE64="${CROSS_COMPILE_64}" \
  PLATFORM=k3-j721e CFG_ARM64_core=y

echo "==> [3/4] U-Boot R5 SPL -> tiboot3.bin"
make -C "${UBOOT}" O="${ROOT}/build/u-boot-r5" j721e_beagleboneai64_r5_defconfig
make -C "${UBOOT}" O="${ROOT}/build/u-boot-r5" -j"${JOBS}" \
  CROSS_COMPILE="${CROSS_COMPILE_32}" \
  BINMAN_INDIRS="${TIFW}"

echo "==> [4/4] U-Boot A72 -> tispl.bin + u-boot.img"
make -C "${UBOOT}" O="${ROOT}/build/u-boot-a72" j721e_beagleboneai64_a72_defconfig
make -C "${UBOOT}" O="${ROOT}/build/u-boot-a72" -j"${JOBS}" \
  CROSS_COMPILE="${CROSS_COMPILE_64}" \
  BL31="${TFA}/build/k3/generic/release/bl31.bin" \
  TEE="${OPTEE}/out/arm-plat-k3/core/tee-raw.bin" \
  BINMAN_INDIRS="${TIFW}"

echo "==> collecting outputs into ${DEPLOY}"
# R5 build yields tiboot3-*.bin (HS-FS on BBAI64); A72 yields tispl.bin/u-boot.img
cp -v "${ROOT}/build/u-boot-r5"/tiboot3*.bin "${DEPLOY}/tiboot3.bin" 2>/dev/null || \
  cp -v "${ROOT}/build/u-boot-r5"/tiboot3.bin "${DEPLOY}/tiboot3.bin"
cp -v "${ROOT}/build/u-boot-a72/tispl.bin"   "${DEPLOY}/tispl.bin"
cp -v "${ROOT}/build/u-boot-a72/u-boot.img"  "${DEPLOY}/u-boot.img"
[ -f "${ROOT}/build/u-boot-a72/sysfw.itb" ] && cp -v "${ROOT}/build/u-boot-a72/sysfw.itb" "${DEPLOY}/" || true

echo "==> done. Boot binaries in ${DEPLOY}/"
ls -la "${DEPLOY}"
