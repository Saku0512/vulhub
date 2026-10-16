#!/bin/sh
set -eu

workspace="$(mktemp -d)"
marker="/tmp/cve-2026-84361-success"
trap 'rm -rf "$workspace"' EXIT

rm -f "$marker"
cp /opt/poc/composer.json "$workspace/composer.json"
cd "$workspace"

set +e
composer update --prefer-source --no-interaction --no-plugins --no-scripts
status=$?
set -e

if [ -e "$marker" ]; then
    echo "[-] Patched Composer executed the malicious Perforce transport."
    exit 1
fi

echo "[+] FIXED: Composer rejected the malicious rsh: Perforce URL."
echo "[*] Composer exit status: $status"
