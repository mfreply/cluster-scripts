WORKER_IP=$1

KUBE_USER=$(whoami)

WORKER_ID=$(printf '%02d' $(( 1 + $(cat /etc/hosts | grep k8s-worker | sed -En -e 's/.*k8s-worker-//p' | sort | tail -1) )))
WORKER_HOSTNAME='k8s-worker-'${WORKER_ID}

# Create a ssh key if is not present
ssh-keygen -t ed25519 -a 100 -N '' -f ~/.ssh/id_ed25519 <<< n

# Copy ssh key to authorized_keys for KUBE_USER to login without pwd
ssh-copy-id -i ~/.ssh/id_ed25519 ${KUBE_USER}@${WORKER_IP}

# Copy setup script and run it (Set worker hostname)
scp ./generic_setup.sh ${WORKER_IP}:/tmp
ssh ${WORKER_IP} -t "chmod +x /tmp/generic_setup.sh; sudo hostnamectl set-hostname ${WORKER_HOSTNAME}; sudo /tmp/generic_setup.sh"

# Join the worker to the cluster
scp ~/join.sh ${WORKER_IP}:/tmp
ssh ${WORKER_IP} -t "chmod +x /tmp/join.sh; /tmp/join.sh"

# Add the hostname of the configured worker
sudo echo "${WORKER_IP} ${WORKER_HOSTNAME}" >> /etc/hosts
