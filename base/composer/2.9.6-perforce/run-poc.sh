#!/bin/sh
set -eu

workspace="$(mktemp -d)"
marker="/tmp/cve-2026-40176-success"
trap 'rm -rf "$workspace"' EXIT

rm -f "$marker"
cp /opt/poc/composer.json "$workspace/composer.json"
cd "$workspace"

set +e
composer update --no-interaction --no-plugins --no-scripts
status=$?
set -e

if [ -f "$marker" ]; then
    echo "[-] Patched Composer executed shell syntax from the Perforce port."
    exit 1
fi

echo "[+] FIXED: Composer did not execute shell syntax from the Perforce port."
echo "[*] Composer exit status $status is expected because no Perforce server exists."
