#!/bin/bash
# Setup a worker node and join it to the cluster
# Run as kubeadmin

WORKER_IP=$1

KUBE_USER=$(whoami)

HOSTNAME_PREFIX='k8s-worker'
WORKER_HOSTNAME=$(printf "${WORKER_PREFIX}-%02d" $(( 1 + $(cat /etc/hosts | sed -En "s/.*${WORKER_PREFIX}-([0-9]+)/\1/p" | sort | tail -1) )))

# Create a ssh key if is not present
ssh-keygen -t ed25519 -a 100 -N '' -f ~/.ssh/id_ed25519 <<< n

# Copy ssh key to authorized_keys for KUBE_USER to login without pwd
ssh-copy-id -i ~/.ssh/id_ed25519 ${KUBE_USER}@${WORKER_IP}

# Copy setup script and run it
scp ./generic_setup.sh ${WORKER_IP}:/tmp
ssh ${WORKER_IP} -t "
  sudo sed -i 's/$(hostname)/${WORKER_HOSTNAME}/' /etc/hosts &&
  sudo hostnamectl set-hostname ${WORKER_HOSTNAME} &&
  chmod +x /tmp/generic_setup.sh &&
  sudo /tmp/generic_setup.sh"

# Join the worker to the cluster
scp ~/join.sh ${WORKER_IP}:/tmp
ssh ${WORKER_IP} -t 'chmod +x /tmp/join.sh && /tmp/join.sh'

# Add the hostname of the configured worker
sudo echo "${WORKER_IP}\t${WORKER_HOSTNAME}" >> /etc/hosts
