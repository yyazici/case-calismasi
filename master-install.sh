#!/bin/bash

#Hostname ve /etc/hosts tanımları
hostnamectl set-hostname system-0
cat <<EOF>> /etc/hosts
192.168.4.96    server-0
192.168.4.105   server-1
EOF

#Kubernetes repo tanımlanması

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

#kubelet, kubeadm, and kubectl kurulumu, vagrant test ortamında 1.22 ile test leri yaptığımdan, burada da 1.22 ile ilerledim, son sürüm ile ilerlenebilir. 
sudo yum install -y kubelet-1.22.2 kubeadm-1.22.2  kubectl-1.22.2 
systemctl enable kubelet
systemctl start kubelet

#Firewall yapılandırması, firewall kapalı ise atlanabilir.
sudo firewall-cmd --permanent --add-port=6443/tcp
sudo firewall-cmd --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --permanent --add-port=10250/tcp
sudo firewall-cmd --permanent --add-port=10251/tcp
sudo firewall-cmd --permanent --add-port=10252/tcp
sudo firewall-cmd --permanent --add-port=10255/tcp
sudo firewall-cmd --reload

#Kernel tuning ayarları
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system


#Disable selinux
sudo setenforce 0
sudo sed -i ‘s/^SELINUX=enforcing$/SELINUX=permissive/’ /etc/selinux/config

#Disable swap
sudo sed -i '/swap/d' /etc/fstab
sudo swapoff -a

#Buraya kadar olan kısım worker ve master için benzer, bundan sonraki adimlar master node için. 
#Config file ile kurulum yapmayı tercih ettim, cluster ismini config file içine koydum.
sudo kubeadm init --config files/kubeadm-config.yaml

#Cluster login olabilmek için
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Flannel network tanımı
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

#Burada master node görünmesi lazım
sudo kubectl get nodes

#Cluster eklenme scriptin olusturulmasi /joincluster.sh
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null

