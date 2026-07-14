#!/usr/bin/env bash
#
# fetch-firmware.sh — clone the pinned firmware repos that are NOT tracked as
# submodules (they are large/binary and only needed at build time).
# Versions come from versions.lock so a fresh clone reproduces the same build.
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/sources"
LOCK="${ROOT}/versions.lock"
mkdir -p "${SRC}"

# read one field (url=$2 ref=$3 sha=$4) for a component from versions.lock
lock_field() { awk -v c="$1" -v n="$2" '$1==c{print $n}' "${LOCK}"; }

clone_pinned() {
  local name="$1" dir="${SRC}/$1"
  local url ref sha
  url="$(lock_field "$name" 2)"
  ref="$(lock_field "$name" 3)"
  sha="$(lock_field "$name" 4)"

  if [ -z "${url}" ]; then
    echo "!! ${name} not found in versions.lock" >&2; return 1
  fi

  if [ ! -d "${dir}/.git" ]; then
    echo ">> cloning ${name} (${ref})"
    git clone "${url}" "${dir}"
  fi
  echo ">> pinning ${name} -> ${sha}"
  git -C "${dir}" fetch --tags origin
  git -C "${dir}" checkout --quiet "${sha}"
}

clone_pinned trusted-firmware-a
clone_pinned optee_os
clone_pinned ti-linux-firmware

echo ">> firmware repos ready under ${SRC}/"
