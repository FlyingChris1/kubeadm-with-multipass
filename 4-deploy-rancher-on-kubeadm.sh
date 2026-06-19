#!/bin/bash
set -euo pipefail

export KUBECONFIG=kubeconfig.yaml

kubectl get nodes -o wide

if ! command -v helm >/dev/null 2>&1; then
  echo "Helm is not installed. Install Helm first, for example:"
  echo "brew install helm"
  exit 1
fi

helm repo add jetstack https://charts.jetstack.io
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set crds.enabled=true

kubectl -n cert-manager rollout status deploy/cert-manager --timeout=300s
kubectl -n cert-manager rollout status deploy/cert-manager-webhook --timeout=300s
kubectl -n cert-manager rollout status deploy/cert-manager-cainjector --timeout=300s

helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.localhost \
  --set bootstrapPassword=admin \
  --set replicas=1

kubectl -n cattle-system rollout status deploy/rancher --timeout=600s

echo "############################################################################"
echo "Rancher is deployed."
echo "Open a new terminal and run:"
echo ""
echo "export KUBECONFIG=kubeconfig.yaml"
echo "kubectl -n cattle-system port-forward deploy/rancher 4443:443"
echo ""
echo "Then open:"
echo "https://127.0.0.1:4443"
echo ""
echo "Initial password:"
echo "admin"
echo "############################################################################"

kubectl -n cattle-system port-forward deploy/rancher 4443:443
