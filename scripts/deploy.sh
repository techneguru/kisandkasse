#!/bin/bash
# Grunnleggende systemforberedelser for KI-miljø med brukeropprettelse

echo "Oppdaterer systemet og installerer nødvendige pakker..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git nfs-kernel-server

echo "Installerer Docker..."
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
sudo systemctl enable docker

echo "Installerer Kubernetes..."
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "Installerer NVIDIA-driver og toolkit..."
sudo apt install -y nvidia-driver-535
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu20.04/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install -y nvidia-docker2
sudo systemctl restart docker

echo "Oppretter brukere: kiadmin, instruktør, utvikler1-3..."
sudo useradd -m -s /bin/bash kiadmin
echo "kiadmin:kiadmin" | sudo chpasswd
sudo usermod -aG sudo kiadmin

sudo useradd -m -s /bin/bash instruktør
echo "instruktør:instruktør" | sudo chpasswd

for i in {1..3}; do
    sudo useradd -m -s /bin/bash utvikler$i
    echo "utvikler$i:utvikler$i" | sudo chpasswd
    sudo usermod -aG docker utvikler$i
done

echo "Setter opp felles NFS-lagring..."
sudo mkdir -p /mnt/nfs-share
sudo chown nobody:nogroup /mnt/nfs-share
sudo chmod 777 /mnt/nfs-share
echo "/mnt/nfs-share *(rw,sync,no_subtree_check)" | sudo tee /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

echo "Systemoppsett fullført. Start maskinen på nytt for å aktivere alle endringer."
