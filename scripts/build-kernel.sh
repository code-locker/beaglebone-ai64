#!/usr/bin/env bash
#
# build-kernel.sh — build the 6.18.x-k3 arm64 kernel for BeagleBone AI-64 using
# RobertCNelson's arm64-multiplatform build system (tracked as a submodule).
# It downloads linux-stable 6.18.38 + the aarch64 gcc toolchain on first run.
# Then builds the kernel/ part of every application against the fresh tree.
#
#   ./scripts/build-kernel.sh             # full build: re-fetch + re-patch KERNEL/
#   REBUILD=1 ./scripts/build-kernel.sh   # incremental: keep edits in KERNEL/
#   APP_MODULES=0 ...                     # skip building application modules
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDIR="${ROOT}/sources/arm64-multiplatform"

# Check the submodule is populated. NOTE: a git submodule's .git is a FILE
# (a gitlink), not a directory — so test for the build script we actually need.
[ -f "${KDIR}/build_kernel.sh" ] || { echo "!! ${KDIR} not populated. Run ./scripts/bootstrap.sh first." >&2; exit 1; }

# system.sh is required by the build system; seed it from the sample once.
if [ ! -f "${KDIR}/system.sh" ]; then
  echo ">> creating ${KDIR}/system.sh from sample"
  cp "${KDIR}/system.sh.sample" "${KDIR}/system.sh"
fi

# Two builds in the same KERNEL/ tree corrupt each other's objects
# ("fixdep: error opening file ... .o.d"), so allow only one at a time.
mkdir -p "${ROOT}/build"
exec 9>"${ROOT}/build/.kernel-build.lock"
flock -n 9 || { echo "!! another kernel build is already running in this workspace" >&2; exit 1; }

cd "${KDIR}"
if [ "${REBUILD:-0}" = 1 ] && [ -d "${KDIR}/KERNEL" ]; then
  echo ">> incremental kernel rebuild (keeps edits in ${KDIR}/KERNEL/)"
  ./tools/rebuild.sh
else
  # build_kernel.sh re-clones and re-patches KERNEL/ — uncommitted edits there are lost.
  echo ">> building kernel (this downloads linux-stable + toolchain on first run)"
  ./build_kernel.sh
fi

# Collect kernel artifacts into the common build/ folder (alongside the u-boot
# boot files in build/deploy), so every compiled image lives under build/.
KDEPLOY="${KDIR}/deploy"
DEST="${ROOT}/build/kernel"
echo ">> collecting kernel artifacts into ${DEST}"
mkdir -p "${DEST}"
shopt -s nullglob
copied=0
for f in "${KDEPLOY}"/*.Image "${KDEPLOY}"/*-dtbs.tar.zst \
         "${KDEPLOY}"/*-modules.tar.zst "${KDEPLOY}"/config-*; do
  cp -v "${f}" "${DEST}/"; copied=$((copied+1))
done
shopt -u nullglob
[ "${copied}" -gt 0 ] || echo "!! no kernel artifacts found in ${KDEPLOY}" >&2

# Application kernel parts are built right after the kernel, with the same
# tree and compiler, so their modules always match this kernel.
if [ "${APP_MODULES:-1}" = 1 ]; then
  for kb in "${ROOT}"/applications/*/kernel/Kbuild; do
    [ -f "${kb}" ] || continue
    app="$(basename "$(dirname "$(dirname "${kb}")")")"
    [ "${app}" = _template ] && continue
    "${ROOT}/scripts/build-app.sh" "${app}" kernel
  done
fi

cat <<EOF

Kernel build finished. Artifacts collected under:
  ${DEST}/        (Image, dtbs, config, modules tarball)
(originals also remain in ${KDEPLOY}/)

Rebuild after editing files in ${KDIR}/KERNEL/:
  REBUILD=1 ./scripts/build-kernel.sh
Install on a running board:
  BOARD=debian@<board-ip> ./scripts/deploy-kernel.sh --reboot
EOF
