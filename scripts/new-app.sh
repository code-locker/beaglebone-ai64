#!/usr/bin/env bash
#
# new-app.sh — create applications/<name>/ from applications/_template,
# renaming the "tmpl" placeholder (binary, module, /dev node, files).
#
#   ./scripts/new-app.sh <name> [--no-kernel]
#
# <name>: lowercase letters, digits, '_' (it becomes a C/module identifier).
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAME="${1:?usage: new-app.sh <name> [--no-kernel]}"
SRC="${ROOT}/applications/_template"
DEST="${ROOT}/applications/${NAME}"

[[ "${NAME}" =~ ^[a-z][a-z0-9_]*$ ]] || { echo "!! name must match [a-z][a-z0-9_]*" >&2; exit 1; }
[ -e "${DEST}" ] && { echo "!! ${DEST} already exists" >&2; exit 1; }

cp -r "${SRC}" "${DEST}"
[ "${2:-}" = "--no-kernel" ] && rm -rf "${DEST}/kernel"

# rename files, then contents
find "${DEST}" -depth -name '*tmpl*' | while read -r f; do
  mv "${f}" "$(dirname "${f}")/$(basename "${f}" | sed "s/tmpl/${NAME}/g")"
done
grep -rl tmpl "${DEST}" | xargs -r sed -i "s/tmpl/${NAME}/g"
chmod +x "${DEST}/test/on-board.sh"

echo ">> created applications/${NAME}/"
find "${DEST}" -type f | sed "s|${ROOT}/||" | sort
echo ">> next: ./scripts/build-app.sh ${NAME}"
