#!/bin/bash
set -e

# ── System prep ──────────────────────────────────────────
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gpg

# ── Container runtime ────────────────────────────────────
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

echo "WORKER READY - waiting for join command" > /home/ubuntu/worker-status.txt
