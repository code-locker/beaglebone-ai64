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

RETRIES="${RETRIES:-4}"

# retry a command up to $RETRIES times with backoff — survives transient
# DNS/network blips (e.g. "Could not resolve host: github.com").
retry() {
  local n=1
  until "$@"; do
    if [ "${n}" -ge "${RETRIES}" ]; then
      echo "!! failed after ${RETRIES} attempts: $*" >&2; return 1
    fi
    echo ">> attempt ${n}/${RETRIES} failed, retrying in $((n*5))s ..." >&2
    sleep "$((n*5))"; n=$((n+1))
  done
}

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
    # remove any partial dir left by a failed clone so the retry is clean
    rm -rf "${dir}"
    retry git clone "${url}" "${dir}"
  fi
  echo ">> pinning ${name} -> ${sha}"
  retry git -C "${dir}" fetch --tags origin
  git -C "${dir}" checkout --quiet "${sha}"
}

clone_pinned trusted-firmware-a
clone_pinned optee_os
clone_pinned ti-linux-firmware

echo ">> firmware repos ready under ${SRC}/"
