#!/bin/bash
set -euo pipefail

export KUBECONFIG="${KUBECONFIG:-kubeconfig.yaml}"

kubectl get nodes

if ! command -v helm >/dev/null 2>&1; then
  echo "Helm is required. Install it first:"
  echo "brew install helm"
  exit 1
fi

helm repo add traefik https://traefik.github.io/charts || true
helm repo update

kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install traefik traefik/traefik \
  --namespace traefik \
  --set service.type=LoadBalancer \
  --wait \
  --timeout=300s

kubectl get pods -n traefik
kubectl get svc -n traefik
