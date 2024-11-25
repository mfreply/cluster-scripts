#!/bin/bash
# Create an admin user able to call kubectl

useradd -m -s /bin/bash $1
passwd $1
mkdir -p /home/$1/.kube
sudo kubeadm kubeconfig user --client-name=$1 --org=edit > /home/$1/.kube/config
sudo chown $(id -u $1):$(id -g $1) /home/$1/.kube/config
