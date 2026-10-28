#!/usr/bin/env bash
#
# on-board.sh — runs ON THE BOARD from ~/apps/<app>/ (scripts/deploy-app.sh --run).
# Loads the kernel part, runs the userspace part, unloads, and reports.
#
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

MOD=tmpl_drv

echo ">> kernel: $(uname -r)"
if [ -f "kernel/${MOD}.ko" ]; then
  modinfo -F vermagic "kernel/${MOD}.ko"
  sudo rmmod "${MOD}" 2>/dev/null || true
  sudo insmod "kernel/${MOD}.ko"
  trap 'sudo rmmod ${MOD} 2>/dev/null || true' EXIT
fi

./bin/tmpl

sudo dmesg | tail -n 5
echo ">> PASS"
