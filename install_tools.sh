#!/bin/bash
set -e


function welcome_to_demo {
echo 'welcome to CRI and Kubernetes demo'
}
function install_tools {
sudo apt-get update && sudo apt-get install -y libseccomp2 apt-transport-https curl
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key \
  | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
}

function setup_containerd {
sudo apt-get update
sudo apt-get install -y containerd

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd
}


function bring_up_cluster {
    sudo modprobe br_netfilter
    sudo sysctl net.bridge.bridge-nf-call-iptables=1
    echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

    sudo kubeadm init --pod-network-cidr=192.168.0.0/16
}

function setup_kubectl_conf {
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

function enbale_pod_scheduling_on_master {
kubectl taint nodes --all node-role.kubernetes.io/master-
}

function setup_network {
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

"$@"
