#!/usr/bin/env bash
#
# deploy-app.sh — copy a built application (build/apps/<app>/) to the board
# at ~/apps/<app>/ and optionally run its test/on-board.sh there.
#
#   BOARD=debian@<board-ip> ./scripts/deploy-app.sh <app> [--run]
#
# SPDX-License-Identifier: MIT
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="${1:?usage: BOARD=user@ip deploy-app.sh <app> [--run]}"
BOARD="${BOARD:?set BOARD=<user>@<board-ip>}"
OUT="${ROOT}/build/apps/${APP}"

[ -d "${OUT}" ] || { echo "!! ${OUT} missing — run ./scripts/build-app.sh ${APP}" >&2; exit 1; }

echo ">> ${APP} -> ${BOARD}:~/apps/${APP}/"
ssh "${BOARD}" "rm -rf ~/apps/${APP} && mkdir -p ~/apps/${APP}"
for d in bin kernel test; do
  [ -d "${OUT}/${d}" ] && scp -rq "${OUT}/${d}" "${BOARD}:apps/${APP}/"
done

if [ "${2:-}" = "--run" ]; then
  # -t: sudo inside on-board.sh may need a password prompt
  ssh -t "${BOARD}" "~/apps/${APP}/test/on-board.sh"
fi
