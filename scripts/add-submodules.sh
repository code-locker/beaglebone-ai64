#!/usr/bin/env bash
#
# add-submodules.sh — ONE-TIME setup. Wires sources/u-boot and
# sources/arm64-multiplatform as git submodules pointing at YOUR forks.
#
# Prereq: fork these on GitHub first (see GITHUB-SETUP.md):
#   beagleboard/u-boot                -> code-locker/u-boot
#   RobertCNelson/arm64-multiplatform -> code-locker/arm64-multiplatform
#
# To avoid re-downloading ~9 GB, this reuses your existing local clones as a
# git "reference" if REF_UBOOT / REF_KBUILD point at them.
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

GH_USER="${GH_USER:-code-locker}"

# URL scheme for the fork remotes: "ssh" (git@github.com:...) or "https".
GIT_PROTO="${GIT_PROTO:-https}"
fork_url() { # $1 = repo name
  if [ "${GIT_PROTO}" = "ssh" ]; then
    echo "git@github.com:${GH_USER}/$1.git"
  else
    echo "https://github.com/${GH_USER}/$1.git"
  fi
}

# Optional: existing local clones to speed up the add (set to your paths).
REF_UBOOT="${REF_UBOOT:-/media/abhishekkumark/cf83b77e-dc34-45e6-9518-252c12d6896b/Courses/BBB/build/u-boot}"
REF_KBUILD="${REF_KBUILD:-/media/abhishekkumark/cf83b77e-dc34-45e6-9518-252c12d6896b/Courses/BBB/build/arm64-multiplatform}"

lock_field() { awk -v c="$1" -v n="$2" '$1==c{print $n}' "${ROOT}/versions.lock"; }

add_sub() {
  local name="$1" ref_local="$2" fork_url="$3" sha="$4"
  local path="sources/${name}"
  [ -e "${path}" ] && { echo ">> ${path} already present, skipping add"; return 0; }

  local refopt=()
  [ -d "${ref_local}/.git" ] && refopt=(--reference "${ref_local}")

  echo ">> adding submodule ${name} -> ${fork_url}"
  git submodule add "${refopt[@]}" "${fork_url}" "${path}"
  git -C "${path}" fetch --tags origin
  git -C "${path}" checkout --quiet "${sha}"
  echo ">> ${name} pinned to ${sha}"
}

add_sub u-boot "${REF_UBOOT}" \
  "$(fork_url u-boot)" \
  "$(lock_field u-boot 4)"

add_sub arm64-multiplatform "${REF_KBUILD}" \
  "$(fork_url arm64-multiplatform)" \
  "$(lock_field arm64-multiplatform 4)"

cat <<EOF

Submodules wired. Review .gitmodules, then:
  git add .gitmodules sources
  git commit -m "Add u-boot & kernel-build submodules pinned to build versions"
EOF
