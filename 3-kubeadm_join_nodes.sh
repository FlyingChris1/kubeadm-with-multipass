set -euo pipefail
#!/bin/bash
set -e

NODES=$(echo worker{1..2})

JOIN_CMD=$(multipass exec master -- bash -c "sudo kubeadm token create --print-join-command")

for NODE in ${NODES}; do
  multipass exec ${NODE} -- bash -c "sudo ${JOIN_CMD}"
done

KUBECONFIG=kubeconfig.yaml kubectl wait --for=condition=Ready node/worker1 --timeout=300s
KUBECONFIG=kubeconfig.yaml kubectl wait --for=condition=Ready node/worker2 --timeout=300s

WORKER1_IP=$(KUBECONFIG=kubeconfig.yaml kubectl get node worker1 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
WORKER2_IP=$(KUBECONFIG=kubeconfig.yaml kubectl get node worker2 -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')

multipass exec master -- bash -c "grep -q ' worker1$' /etc/hosts || echo '${WORKER1_IP} worker1' | sudo tee -a /etc/hosts"
multipass exec master -- bash -c "grep -q ' worker2$' /etc/hosts || echo '${WORKER2_IP} worker2' | sudo tee -a /etc/hosts"

# SSH-Key vom Master auf die Worker verteilen
multipass exec master -- bash -c "test -f ~/.ssh/id_ed25519 || ssh-keygen -t ed25519 -N '' -f ~/.ssh/id_ed25519"

MASTER_PUB_KEY=$(multipass exec master -- bash -c "cat ~/.ssh/id_ed25519.pub")

multipass exec worker1 -- bash -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -q '${MASTER_PUB_KEY}' ~/.ssh/authorized_keys 2>/dev/null || echo '${MASTER_PUB_KEY}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

multipass exec worker2 -- bash -c "mkdir -p ~/.ssh && chmod 700 ~/.ssh && grep -q '${MASTER_PUB_KEY}' ~/.ssh/authorized_keys 2>/dev/null || echo '${MASTER_PUB_KEY}' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

KUBECONFIG=kubeconfig.yaml kubectl label node worker1 node-role.kubernetes.io/node= --overwrite
KUBECONFIG=kubeconfig.yaml kubectl label node worker2 node-role.kubernetes.io/node= --overwrite

echo "############################################################################"
echo "Enjoy :-)"