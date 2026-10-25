#!/usr/bin/env bash
#
# deploy-kernel.sh — package the CURRENT workspace kernel tree
# (sources/arm64-multiplatform/KERNEL, incl. uncommitted edits) as a Debian
# linux-image .deb, install it on a running board, and optionally reboot.
# The previously installed kernel stays on the board as a fallback.
#
#   BOARD=debian@<board-ip> ./scripts/deploy-kernel.sh [--no-build] [--reboot]
#
#   --no-build  reuse the newest linux-image-*.deb in build/kernel/
#   --reboot    reboot the board after installing
#
# Uses the same bindeb-pkg options as arm64-multiplatform's build_deb.sh, but
# runs make in the existing tree instead of build_deb.sh (which re-clones and
# re-patches KERNEL/, discarding local edits). Host needs: dpkg-dev.
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KBUILD="${ROOT}/sources/arm64-multiplatform"
KDIR="${KBUILD}/KERNEL"
DEST="${ROOT}/build/kernel"
BOARD="${BOARD:?set BOARD=<user>@<board-ip>}"
BUILD_DEB=1 REBOOT=0
for a in "$@"; do
  case "${a}" in
    --no-build) BUILD_DEB=0 ;;
    --reboot)   REBOOT=1 ;;
    *) echo "!! unknown option ${a}" >&2; exit 1 ;;
  esac
done

if [ "${BUILD_DEB}" = 1 ]; then
  [ -f "${KDIR}/.config" ] && [ -f "${KBUILD}/.CC" ] || {
    echo "!! kernel not built yet — run ./scripts/build-kernel.sh first" >&2; exit 1; }
  # shellcheck disable=SC1091
  . "${KBUILD}/.CC"; . "${KBUILD}/version.sh"
  echo ">> packaging $(cat "${KDIR}/include/config/kernel.release") as .deb"
  rm -f "${KBUILD}"/*.deb "${KBUILD}"/*.buildinfo "${KBUILD}"/*.changes
  make -C "${KDIR}" -j"$(nproc)" ARCH="${KERNEL_ARCH}" KBUILD_DEBARCH="${DEBARCH}" \
    LOCALVERSION="${BUILD}" KDEB_PKGVERSION="1${DISTRO}" KDEB_SOURCENAME=linux-upstream \
    KDEB_COMPRESS=xz DEB_BUILD_PROFILES=pkg.linux-upstream.nokernelheaders \
    CROSS_COMPILE="${CC}" bindeb-pkg
  mkdir -p "${DEST}"
  mv -v "${KBUILD}"/linux-image-*.deb "${DEST}/"
  rm -f "${KBUILD}"/*.deb "${KBUILD}"/*.buildinfo "${KBUILD}"/*.changes
fi

DEB="$(ls -t "${DEST}"/linux-image-*.deb 2>/dev/null | head -n1 || true)"
[ -n "${DEB}" ] || { echo "!! no linux-image-*.deb in ${DEST}/" >&2; exit 1; }

echo ">> installing $(basename "${DEB}") on ${BOARD}"
scp -q "${DEB}" "${BOARD}:/tmp/"
ssh -t "${BOARD}" "sudo dpkg -i /tmp/$(basename "${DEB}") && ls -1 /boot | grep -E '^(vmlinuz|initrd)' | tail -n4"

if [ "${REBOOT}" = 1 ]; then
  ssh -t "${BOARD}" "sudo reboot" || true
  echo ">> rebooting; then check: ssh ${BOARD} uname -r"
fi
