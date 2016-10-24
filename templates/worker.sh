#!/bin/bash -v

# modify hostname to allow communication between Scaleway instances.
private_ip=$(cat /tmp/private_ip)
hostname $private_ip
echo $private_ip > /etc/hostname
echo "127.0.0.1 $private_ip" >> /etc/hosts

# install kubernetes worker
apt-get install -y apt-transport-https

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl kubernetes-cni
curl -sSL https://get.docker.com/ | sh
systemctl start docker

for i in {1..50}; do kubeadm join --token=${k8stoken} ${masterIP} && break || sleep 15; done
