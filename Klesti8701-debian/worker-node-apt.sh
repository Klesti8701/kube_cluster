#master node 
apt install -y sudo
#installimi i tools per https http 
sudo apt-get install -y apt-transport-https ca-certificates curl wget 
#add gpg keys and sourcelist 
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

#docker install 
sudo apt-get -y install ca-certificates curl  gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
#add gpg keys
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#add source list
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# #add cri-o
# echo 'deb http://deb.debian.org/debian buster-backports main' > /etc/apt/sources.list.d/backports.list
# apt update
# apt install -y -t buster-backports libseccomp2 || apt update -y -t buster-backports libseccomp2

# #root commands for cri-o
# #add sourcelist
# sudo echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
# sudo echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
# #add gpg
# sudo mkdir -p /usr/share/keyrings
# curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key |sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
# curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key |sudo gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg


#install komponentet
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
#add non root user privs
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# #install cri-o
# sudo apt-get update
# sudo apt-get install cri-o cri-o-runc
# sudo apt-get install containernetworking-plugins


#install docker engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

#swap off
sudo swapoff -a
sudo sed -i 's/.* none.* swap.* sw.*/#&/' /etc/fstab
sudo sed -i 's/^/#&/' /etc/initramfs-tools/conf.d/resume

#edit the containerd configs 
sudo sed -i 's/"cri"//' /etc/containerd/config.toml
sudo systemctl restart containerd


#config kernal communication modules 
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

