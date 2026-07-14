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

[ -d "${KDIR}/.git" ] || { echo "!! ${KDIR} missing. Run ./scripts/bootstrap.sh first." >&2; exit 1; }

# system.sh is required by the build system; seed it from the sample once.
if [ ! -f "${KDIR}/system.sh" ]; then
  echo ">> creating ${KDIR}/system.sh from sample"
  cp "${KDIR}/system.sh.sample" "${KDIR}/system.sh"
fi

cd "${KDIR}"
echo ">> building kernel (this downloads linux-stable + toolchain on first run)"
./build_kernel.sh

cat <<EOF

Kernel build finished. Artifacts under:
  ${KDIR}/deploy/        (Image, dtbs, config, modules tarball)

Optional Debian package:
  (cd ${KDIR} && ./build_deb.sh)

Rebuild after editing files in ${KDIR}/KERNEL/:
  (cd ${KDIR} && ./tools/rebuild.sh)
EOF
