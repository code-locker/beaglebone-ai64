#!/usr/bin/env bash
#
# build-kernel.sh — build the 6.18.x-k3 arm64 kernel for BeagleBone AI-64 using
# RobertCNelson's arm64-multiplatform build system (tracked as a submodule).
# It downloads linux-stable 6.18.38 + the aarch64 gcc toolchain on first run.
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

cd "${KDIR}"
echo ">> building kernel (this downloads linux-stable + toolchain on first run)"
./build_kernel.sh

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

cat <<EOF

Kernel build finished. Artifacts collected under:
  ${DEST}/        (Image, dtbs, config, modules tarball)
(originals also remain in ${KDEPLOY}/)

Optional Debian package:
  (cd ${KDIR} && ./build_deb.sh)

Rebuild after editing files in ${KDIR}/KERNEL/:
  (cd ${KDIR} && ./tools/rebuild.sh)
EOF
