#!/bin/bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-kubeconfig.yaml}"

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.9/config/manifests/metallb-native.yaml

kubectl wait --namespace metallb-system \
  --for=condition=available deployment/controller \
  --timeout=300s

cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: multipass-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.252.230-192.168.252.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: multipass-l2
  namespace: metallb-system
spec:
  ipAddressPools:
  - multipass-pool
EOF