set -euo pipefail
#!/bin/bash
set -euo pipefail
source ./common.sh
launch_instance master
multipass transfer install_tools.sh master:
multipass exec master -- bash -c 'sudo chmod +x $HOME/install_tools.sh'
multipass exec master -- bash -c 'cd $HOME'
multipass exec master -- bash -c './install_tools.sh install_tools'
multipass exec master -- bash -c './install_tools.sh setup_containerd'
multipass exec master -- bash -c './install_tools.sh bring_up_cluster'
multipass exec master -- bash -c './install_tools.sh setup_kubectl_conf'
multipass exec master -- bash -c 'sudo cat /etc/kubernetes/admin.conf' > kubeconfig.yaml
# export KUBECONFIG=kubeconfig.yaml
# kubectl apply -f https://docs.projectcalico.org/v3.9/manifests/calico.yaml
echo "now deploying calico ...."
KUBECONFIG=kubeconfig.yaml kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
KUBECONFIG=kubeconfig.yaml kubectl rollout status daemonset kube-flannel-ds -n kube-flannel
KUBECONFIG=kubeconfig.yaml kubectl get nodes -o wide
echo "Enjoy the kubeadm with containerd on Multipass"
echo "Now deploying the worker nodes"