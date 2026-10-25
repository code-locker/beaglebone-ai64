#!/usr/bin/env bash
#
# build-app.sh — cross-compile one application for the BeagleBone AI-64:
#   kernel/ → out-of-tree module(s), built against the workspace kernel tree
#             with the SAME compiler the kernel was built with
#   user/   → userspace binaries via CMake + aarch64 toolchain
# Output: build/apps/<app>/{kernel/*.ko, bin/*, test/}
#
#   ./scripts/build-app.sh <app> [all|kernel|user|clean]
#
# Env: KDIR=<kernel tree>   (default sources/arm64-multiplatform/KERNEL)
#      CROSS_COMPILE=<prefix> (default: kernel build's compiler from .CC)
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${1:?usage: build-app.sh <app> [all|kernel|user|clean]}"
WHAT="${2:-all}"
ADIR="${ROOT}/applications/${APP}"
OUT="${ROOT}/build/apps/${APP}"
KBUILD="${ROOT}/sources/arm64-multiplatform"
KDIR="${KDIR:-${KBUILD}/KERNEL}"
JOBS="$(nproc)"

[ -d "${ADIR}" ] || { echo "!! no such app: applications/${APP}" >&2; exit 1; }

# The module must be built by the compiler that built the kernel; the
# arm64-multiplatform build records it in .CC as CC=<prefix>.
kernel_cc() {
  if [ -n "${CROSS_COMPILE:-}" ]; then echo "${CROSS_COMPILE}"
  elif [ -f "${KBUILD}/.CC" ]; then (. "${KBUILD}/.CC"; echo "${CC}")
  else echo "aarch64-linux-gnu-"; fi
}

kmake() { make -C "${KDIR}" M="${ADIR}/kernel" ARCH=arm64 CROSS_COMPILE="$(kernel_cc)" "$@"; }

build_kernel() {
  [ -f "${ADIR}/kernel/Kbuild" ] || { echo ">> ${APP}: no kernel/ part, skipping"; return 0; }
  [ -f "${KDIR}/Module.symvers" ] || {
    echo "!! ${KDIR} is not a built kernel tree — run ./scripts/build-kernel.sh first (or set KDIR=)" >&2
    return 1
  }
  echo "==> ${APP}: kernel module(s) against $(cat "${KDIR}/include/config/kernel.release")"
  kmake -j"${JOBS}" modules
  mkdir -p "${OUT}/kernel"
  cp -v "${ADIR}"/kernel/*.ko "${OUT}/kernel/"
}

build_user() {
  [ -f "${ADIR}/user/CMakeLists.txt" ] || { echo ">> ${APP}: no user/ part, skipping"; return 0; }
  echo "==> ${APP}: userspace"
  cmake -S "${ADIR}/user" -B "${OUT}/user-build" \
    -DCMAKE_TOOLCHAIN_FILE="${ROOT}/applications/cmake/toolchain-aarch64.cmake" \
    -DCMAKE_INSTALL_PREFIX="${OUT}"
  cmake --build "${OUT}/user-build" -j"${JOBS}"
  cmake --install "${OUT}/user-build"
}

copy_test() {
  [ -d "${ADIR}/test" ] || return 0
  mkdir -p "${OUT}/test" && cp -r "${ADIR}"/test/. "${OUT}/test/"
}

case "${WHAT}" in
  all)    build_kernel; build_user; copy_test ;;
  kernel) build_kernel; copy_test ;;
  user)   build_user; copy_test ;;
  clean)  [ -f "${ADIR}/kernel/Kbuild" ] && [ -d "${KDIR}" ] && kmake clean; rm -rf "${OUT}" ;;
  *) echo "!! unknown target '${WHAT}' (all|kernel|user|clean)" >&2; exit 1 ;;
esac

[ "${WHAT}" = clean ] || { echo "==> ${APP}: outputs in build/apps/${APP}/"; find "${OUT}" -path "${OUT}/user-build" -prune -o -type f -print | sed "s|${ROOT}/||"; }
