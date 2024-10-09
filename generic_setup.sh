#!/bin/bash
# Generic initial setup script
# Needs to be run on the node with root privileges.
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

log_step () { printf "\n\033[34;1m##\033[37m $1 \033[34m##\033[0m\n"; }

# Variables
ARCH='amd64'
K8S_MAJOR='1'
K8S_MINOR='31'
K8S_PATCH='1'
K8S_VERSION=${K8S_MAJOR}.${K8S_MINOR}.${K8S_PATCH}
CNI_PLUGINS_VERSION='1.5.1'
REGISTRY_NAME=registry.blue-demo.com
REGISTRY_ENDPOINT=http://192.168.1.96:5000

# Check root
if [ "$(id -u)" -ne 0 ] ; then
  echo "This script must be executed with root privileges."
  exit 1
fi


log_step 'Install prerequisite packages'
apt-get -q update
apt-get -q install -y yq apt-transport-https ca-certificates curl gpg


log_step 'Edit config to prevent sleep'
tee /etc/systemd/sleep.conf >/dev/null << EOF
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF
tee /etc/systemd/logind.conf >/dev/null << EOF
[Login]
HandleSuspendKey=ignore
HandleSuspendKeyLongPress=ignore
HandleHibernateKey=ignore
HandleHibernateKeyLongPress=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target suspend-then-hibernate.target


log_step 'Set static ip'
iface=$(ip -o route get to 8.8.8.8 | sed -n 's/.* \(\w\+\) src.*/\1/p')
gateway=$(ip -o route get to 8.8.8.8 | sed -n 's/.*via \([0-9.]\+\).*/\1/p')
address=$(ip -f inet addr show $iface | sed -En -e 's/.*inet ([0-9./]+).*/\1/p')
tee /tmp/interfaces >/dev/null << EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

allow-hotplug $iface
iface $iface inet static
address $address
gateway $gateway
EOF
if iwgetid $iface >/dev/null 2>&1; then
  wpa_ssid=$(sed -En -e 's/.*wpa-ssid\s+(.*$)/\1/p' /etc/network/interfaces)
  wpa_psk=$(sed -En -e 's/.*wpa-psk\s+(.*$)/\1/p' /etc/network/interfaces)
  echo "wpa-ssid $wpa_ssid" >> /tmp/interfaces
  echo "wpa-psk $wpa_psk" >> /tmp/interfaces
  echo "wireless-power off" >> /tmp/interfaces
fi
mv /tmp/interfaces /etc/network/interfaces
systemctl restart networking


log_step 'Set ipv4 packet forwarding'
tee /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
EOF
sysctl --system

# https://github.com/containerd/containerd/blob/main/docs/getting-started.md
log_step 'Add docker apt repo'
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null


log_step "Add k8s apt repo v${K8S_MAJOR}.${K8S_MINOR}"
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${K8S_MAJOR}.${K8S_MINOR}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MAJOR}.${K8S_MINOR}/deb/ /" > /etc/apt/sources.list.d/kubernetes.list


log_step "Install containerd.io and kubeadm/kubectl/kubelet v${K8S_VERSION}"
apt-get -q update
apt-get -q install -y containerd.io kubelet=${K8S_VERSION}\* kubeadm=${K8S_VERSION}\* kubectl=${K8S_VERSION}\*
apt-mark hold kubelet kubeadm kubectl


log_step "Install cni-plugins v${CNI_PLUGINS_VERSION}"
wget -q --show-progress -O /tmp/cni-plugins "https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_PLUGINS_VERSION}.tgz"
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin /tmp/cni-plugins


log_step "Generate containerd config with SystemdCgroup and registry configuration"
mkdir -p /etc/containerd
containerd config default \
  | tomlq -t ".plugins.\"io.containerd.grpc.v1.cri\".containerd.runtimes.runc.options.SystemdCgroup = true | .plugins.\"io.containerd.grpc.v1.cri\".registry.mirrors.\"${REGISTRY_NAME}\".endpoint = [\"${REGISTRY_ENDPOINT}\"]"\
  | tee /etc/containerd/config.toml >/dev/null
systemctl restart containerd

# Check for NVIDIA cards, if none is found stop the setup otherwise install necessary sw
nvidia_card=$(lspci | grep -i nvidia)
if ! $?; then
  echo "Configuration completed!"
  exit 0
fi

log_step "Install NVIDIA driver & smi"
apt-get -q install software-properties-common
apt-add-repository --component non-free
apt-get -q install nvidia-detect
driver=$(nvidia-detect | sed ':a;N;$!ba;s/\n/ /g' | sed -En -e 's/.*It is recommended to install the\s+(\S+)\s+package.*/\1/p')
apt-get -q install $driver nvidia-smi


# https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
log_step "Install NVIDIA Container Toolkit"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list >/dev/null
apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=containerd
systemctl restart containerd
