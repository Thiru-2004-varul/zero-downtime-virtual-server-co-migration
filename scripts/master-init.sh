#!/bin/bash
set -e

# ── System prep ──────────────────────────────────────────
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg

# ── Container runtime (containerd) ───────────────────────
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# ── Kernel settings ──────────────────────────────────────
cat <<SYSCTL > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL
sysctl --system
modprobe br_netfilter

# ── Kubernetes packages ───────────────────────────────────
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
  | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' \
  > /etc/apt/sources.list.d/kubernetes.list
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# ── Disable swap ──────────────────────────────────────────
swapoff -a
sed -i '/swap/d' /etc/fstab

# ── Init cluster ──────────────────────────────────────────
kubeadm init --pod-network-cidr=192.168.0.0/16 > /var/log/kubeadm-init.log 2>&1

# ── kubeconfig for root ───────────────────────────────────
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# ── kubeconfig for ubuntu user ────────────────────────────
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

# ── Calico network plugin ─────────────────────────────────
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml \
  --kubeconfig /root/.kube/config

# ── Save join command for workers ─────────────────────────
kubeadm token create --print-join-command > /home/ubuntu/join-command.sh
chmod +x /home/ubuntu/join-command.sh

echo "MASTER READY" > /home/ubuntu/master-status.txt
