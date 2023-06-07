#!/bin/bash
set -euxo pipefail
echo "[TASK 1] Join node to Kubernetes Cluster"
sudo apt-get install -qq -y sshpass
sudo sshpass -p "vikas" scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no kmaster1:/vagrant/configs/join.sh join.sh
sudo bash join.sh

sudo apt autoremove
sudo apt clean
sudo apt-get clean


