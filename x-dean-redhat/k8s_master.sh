#/bin/bash

swapoff -a
sed -i 's_^/dev/mapper/almalinux-swap none                    swap    defaults        0 0_#/dev/mapper/almalinux-swap none                    swap    defaults        0 0_' /etc/fstab
sed -i 's_^SELINUX=enforcing_SELINUX=permissive_' /etc/selinux/config
dnf install -y iproute-tc



	firewall-cmd --permanent --add-port=6443/tcp
	firewall-cmd --permanent --add-port=2379-2380/tcp
	firewall-cmd --permanent --add-port=10250/tcp
	firewall-cmd --permanent --add-port=10251/tcp
	firewall-cmd --permanent --add-port=10252/tcp
	firewall-cmd --permanent --add-port=30000-32767/tcp
	firewall-cmd --reload




printf "overlay \nbr_netfilter" > /etc/modules-load.d/k8s.conf

modprobe overlay
modprobe br_netfilter

printf "net.bridge.bridge-nf-call-iptables  = 1 \nnet.ipv4.ip_forward                 = 1 \nnet.bridge.bridge-nf-call-ip6tables = 1" > /etc/sysctl.d/k8s.conf
sysctl --system

export VERSION=1.21

curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/CentOS_8/devel:kubic:libcontainers:stable.repo
curl -L -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/CentOS_8/devel:kubic:libcontainers:stable:cri-o:$VERSION.repo

dnf install cri-o
systemctl enable cri-o
systemctl start cri-o

printf "[kubernetes] \nname=Kubernetes \nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 \nenabled=1 \ngpgcheck=1 \nrepo_gpgcheck=1 \ngpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg\n       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg \nexclude=kubelet kubeadm kubectl" > /etc/yum.repos.d/kubernetes.repo


dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet
systemctl start kubelet


kubeadm init --pod-network-cidr=192.168.10.0/16
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

kubectl taint nodes –all node-role.kubernetes.io/master-

kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
kubectl create -f https://docs.projectcalico.org/manifests/custom-resources.yaml

	


#https://www.linuxtechi.com/how-to-install-kubernetes-cluster-rhel/
