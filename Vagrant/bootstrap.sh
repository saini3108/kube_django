#!/bin/bash
set -euxo pipefail

echo "[TASK 1] Disable and turn off SWAP"
sudo sed -i '/swap.img/ s/^/#/' /etc/fstab && sudo swapoff -a

echo "[TASK 2] Stop and Disable firewall"
sudo systemctl disable --now ufw

echo "[TASK 3] Enable and Load Kernel modules https://kubernetes.io/docs/setup/production-environment/container-runtimes/"
printf "\n172.168.29.71 kmaster1\n172.168.29.72 kmaster2\n172.168.29.73 kmaster3\n\n" >> /etc/hosts
printf "\n172.168.29.81 kworker1\n172.168.29.82 kworker2\n172.168.29.83 kworker3\n\n" >> /etc/hosts
printf "overlay\nbr_netfilter\n" >> /etc/modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

# run below 2 if /proc/sys/net/bridge/bridge-nf-call-iptables not found
# sudo modprobe br_netfilter
sudo sysctl -p /etc/sysctl.conf

echo "[TASK 4] Add Kernel settings, Set up required sysctl params, these persist across reboots"
printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" >> /etc/sysctl.d/99-kubernetes-cri.conf
# Apply sysctl params without reboot
sudo sysctl --system

sudo lsmod | grep br_netfilter
sudo lsmod | grep overlay
sudo sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

sudo sysctl -p /etc/sysctl.conf
printf "net.bridge.bridge-nf-call-iptables = 1\nnet.ipv4.ip_forward = 1\nnet.bridge.bridge-nf-call-ip6tables = 1\n" >> /etc/sysctl.d/99-kubernetes-cri.conf
sudo sysctl --system

# echo "[TASK 5.0] keep proxy set"
# sudo touch /etc/apt/apt.conf.d/99verify-peer.conf && echo >>/etc/apt/apt.conf.d/99verify-peer.conf "Acquire { https::Verify-Peer false }"
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B53DC80D13EDEF05

echo "[TASK 5.1] Install containerd runtime https://docs.docker.com/engine/install/ubuntu/"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y containerd.io

echo "[TASK 5.2] Install containerd runtime Configuring the systemd cgroup driver"
sudo containerd config default > /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo sed -i 's/snapshotter = "overlayfs"/snapshotter = "native"/' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "[TASK 6] Add apt repo for kubernetes"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
# sudo curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
# sudo apt-add-repository -y "deb http://apt.kubernetes.io/ kubernetes-xenial main"
sudo echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[TASK 7] Install Kubernetes components (kubeadm, kubelet and kubectl)"
# apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B53DC80D13EDEF05
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[TASK 8] Enable ssh password authentication"
sudo sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
sudo systemctl reload sshd

echo "[TASK 9] Set root password"
sudo echo -e "vikas\nvikas" | passwd root
sudo echo "export TERM=xterm" >> /etc/bash.bashrc


## Create shared folder in VM box for movement of file with the name "vm"