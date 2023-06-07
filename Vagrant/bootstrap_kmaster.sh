#!/bin/bash
set -euxo pipefail
echo "[TASK 1] Pull required containers"
sudo lsmod | grep br_netfilter
sudo systemctl enable kubelet

sudo kubeadm config images pull
sudo rm -rf $HOME/.kube
echo "[TASK 2] Initialize Kubernetes Cluster"
# sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=172.16.16.101 --ignore-preflight-errors=all >> /root/kubeinit.log 2>/dev/null
sudo kubeadm init --apiserver-advertise-address=172.168.29.71 --apiserver-cert-extra-sans=172.168.29.71 --pod-network-cidr=192.168.0.0/16 --service-cidr=172.17.1.0/18

echo "[TASK 3] Set up the kubeconfig for the vagrant user"
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo cp -i /etc/kubernetes/admin.conf /media/sf_vm/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Save Configs to shared /Vagrant location
# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.
config_path="/vagrant/configs"
if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi
cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh
kubeadm token create --print-join-command > $config_path/join.sh

echo "[TASK 5] Deploy Calico network"
printf "\n185.199.108.133 raw.githubusercontent.com\n\n" >> /etc/hosts
### edit>>>>>>> sudo nano /etc/hosts
### add>>>>>>>> 185.199.108.133 raw.githubusercontent.com
sudo curl https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml -O
sudo kubectl apply -f calico.yaml

echo "add dashboard"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
kubectl -n kubernetes-dashboard patch service kubernetes-dashboard --type='json' -p='[{"op": "replace", "path": "/spec/type", "value": "NodePort"}]'
echo "https://$(hostname -I | awk '{print $3}'):$(kubectl -n $NAMESPACE get service $SERVICE_NAME -o jsonpath='{.spec.ports[0].nodePort}')" > /media/sf_vm/dashboard_url
kubectl create serviceaccount admin-user -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user
kubectl -n kubernetes-dashboard create token admin-user > /media/sf_vm/dashboard_token

sudo apt autoremove
sudo apt clean
sudo apt-get clean
