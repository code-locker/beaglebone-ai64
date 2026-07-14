#!/usr/bin/env bash
#
# bootstrap.sh — one command to make a fresh clone build-ready:
#   1. init/update the u-boot & kernel-build submodules
#   2. fetch the pinned firmware repos (TF-A, OP-TEE, ti-linux-firmware)
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

echo ">> initializing submodules (sources/u-boot, sources/arm64-multiplatform)"
git submodule update --init --recursive

echo ">> fetching pinned firmware repos"
"${ROOT}/scripts/fetch-firmware.sh"

cat <<'EOF'

Bootstrap complete. Next:
  ./scripts/build-uboot.sh    # boot chain  -> build/deploy/
  ./scripts/build-kernel.sh   # kernel Image + modules + dtbs
EOF
