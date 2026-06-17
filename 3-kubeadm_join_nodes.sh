#!/bin/bash
set -e

NODES=$(echo worker{1..2})

JOIN_CMD=$(multipass exec master -- bash -c "sudo kubeadm token create --print-join-command")

for NODE in ${NODES}; do
  multipass exec ${NODE} -- bash -c "sudo ${JOIN_CMD}"
done

sleep 30

KUBECONFIG=kubeconfig.yaml kubectl label node worker1 node-role.kubernetes.io/node= --overwrite
KUBECONFIG=kubeconfig.yaml kubectl label node worker2 node-role.kubernetes.io/node= --overwrite
KUBECONFIG=kubeconfig.yaml kubectl get nodes -o wide

echo "############################################################################"
echo "Enjoy :-)"