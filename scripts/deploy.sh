#!/bin/bash
# Grunnleggende systemforberedelser for KI-miljø med brukeropprettelse og tjenesteoppsett

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

echo "Installerer Helm..."
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update && sudo apt install helm -y

echo "Initialiserer Kubernetes-klyngen..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Setter opp Kubernetes Flannel-nettverk..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "Installerer Ingress Controller (NGINX)..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

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

echo "Installerer Flowise..."
docker run -d -p 3000:3000 --name flowise flowiseai/flowise:latest

echo "Deploying tjenester med Helm..."
git clone https://github.com/techneguru/kisandkasse.git /tmp/kisandkasse
helm install code-server /tmp/kisandkasse/charts/code-server --namespace default
helm install ollama /tmp/kisandkasse/charts/ollama --namespace default
helm install jupyterhub /tmp/kisandkasse/charts/jupyterhub --namespace default

echo "Systemoppsett fullført. Start maskinen på nytt for å aktivere alle endringer."
