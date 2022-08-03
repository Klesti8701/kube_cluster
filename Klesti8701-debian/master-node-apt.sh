#master node 
#apt install -y sudo
apt update -y && apt upgrade -y 
#installimi i tools per https http 
apt-get install -y apt-transport-https ca-certificates curl wget 
#add gpg keys and sourcelist 
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
apt-get update

#docker install 
apt-get -y install ca-certificates curl  gnupg lsb-release
mkdir -p /etc/apt/keyrings
#add gpg keys
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
#add source list
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null


# #add cri-o
# echo 'deb http://deb.debian.org/debian buster-backports main' > /etc/apt/sources.list.d/backports.list
# apt update
# apt install -y -t buster-backports libseccomp2 || apt update -y -t buster-backports libseccomp2

# #root commands for cri-o
# #add sourcelist
# echo "deb [signed-by=/usr/share/keyrings/libcontainers-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
# echo "deb [signed-by=/usr/share/keyrings/libcontainers-crio-archive-keyring.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
# #add gpg
# mkdir -p /usr/share/keyrings
# curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key |gpg --dearmor -o /usr/share/keyrings/libcontainers-archive-keyring.gpg
# curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/Release.key |gpg --dearmor -o /usr/share/keyrings/libcontainers-crio-archive-keyring.gpg


#install komponentet
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
#add non root user privs
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# #install cri-o
# apt-get update
# apt-get install cri-o cri-o-runc
# apt-get install containernetworking-plugins


#install docker engine
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

#swap off
swapoff -a
sed -i 's/.* none.* swap.* sw.*/#&/' /etc/fstab
sed -i 's/^/#&/' /etc/initramfs-tools/conf.d/resume

#edit the containerd configs 
sed -i 's/"cri"//' /etc/containerd/config.toml
systemctl restart containerd


#config kernal communication modules 
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sysctl --system

#define the hostname for master
read -p "hostname: " host
hostnamectl set-hostname $host

#link the out ip to the hostname 
ip=$(ip a | grep "scope global" | grep -Po '(?<=inet )[\d.]+')
printf "%s\n" "$ip"
echo "type 1 of this ips in which the kube-master domain will be routed"
read -p 'ip: ' var
echo "$var $host" |tee -a /etc/hosts


#run the init command
kubeadm init --control-plane-endpoint=$host --pod-network-cidr=192.168.150.0/16 > connection.txt && export KUBECONFIG=/etc/kubernetes/admin.conf
# mkdir -p $HOME/.kube
# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# chown $(id -u):$(id -g) $HOME/.kube/config

#set up single nonde 
kubectl taint nodes --all node-role.kubernetes.io/control-plane- node-role.kubernetes.io/master-


#networking
KUBECONFIG=/etc/kubernetes/admin.conf kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
