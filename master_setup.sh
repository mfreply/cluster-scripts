#!/bin/bash
# Setup script for master node to start the cluster.
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

log_step () { printf "\n\033[34;1m##\033[37m $1 \033[34m##\033[0m\n"; }


log_step "Setup master hostname"
sed -i "s/$(hostname)/k8s-master/" /etc/hosts
hostnamectl set-hostname k8s-master

log_step "Start generic setup phase"
./generic_setup.sh


log_step "Initialize the cluster"
kubeadm init --pod-network-cidr=10.244.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf

log_step "Install helm"
#https://helm.sh/docs/intro/install/
curl -fsSL https://baltocdn.com/helm/signing.asc | gpg --dearmor -o /usr/share/keyrings/helm.gpg
apt-get -q -y install apt-transport-https
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" > /etc/apt/sources.list.d/helm-stable-debian.list
apt-get -q update
apt-get -q -y install helm

log_step "Add helm repos"
helm repo add nvdp https://nvidia.github.io/k8s-device-plugin
helm repo add flannel https://flannel-io.github.io/flannel/
helm repo update

log_step "Install flannel"
#https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-with-helm
kubectl create ns kube-flannel
kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
helm install flannel --set podCidr="10.244.0.0/16" --namespace kube-flannel flannel/flannel

log_step "Install NVIDIA device plugin"
# https://github.com/NVIDIA/k8s-device-plugin?tab=readme-ov-file#deployment-via-helm
helm install nvdp --namespace nvidia-device-plugin --create-namespace nvdp/nvidia-device-plugin

log_step "Setup kubeadmin user"
KUBE_USER=kubeadmin

# Output join command
kubeadm token create --print-join-command > /home/${KUBE_USER}/join.sh

# Add kube config
mkdir -p /home/${KUBE_USER}/.kube
cp -i /etc/kubernetes/admin.conf /home/${KUBE_USER}/.kube/config
chown $(id -u ${KUBE_USER}):$(id -g ${KUBE_USER}) /home/${KUBE_USER}/.kube/config

