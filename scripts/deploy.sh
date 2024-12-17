#!/bin/bash
# Grunnleggende systemforberedelser for KI-miljø med brukeropprettelse, NFS og tjenesteoppsett

set -e  # Stopp skriptet ved feil
trap 'echo "Feil på linje $LINENO"; exit 1' ERR

echo "Oppdaterer systemet og installerer nødvendige pakker..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git nfs-kernel-server

# Docker-installasjon
echo "Installerer Docker..."
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
sudo systemctl enable docker

# Kubernetes-installasjon via Snap
echo "Installerer Kubernetes via Snap fordi apt-installasjonen feilet tidligere..."
sudo snap install kubeadm --classic
sudo snap install kubectl --classic
sudo snap install kubelet --classic

echo "Verifiserer Kubernetes Snap-installasjon..."
kubeadm version
kubectl version --client
sudo systemctl status snap.kubelet.daemon

# NVIDIA-driver og toolkit
echo "Installerer NVIDIA-driver og toolkit..."
sudo apt install -y nvidia-driver-535
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/ubuntu20.04/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt update && sudo apt install -y nvidia-docker2
sudo systemctl restart docker

echo "Validerer NVIDIA-driver..."
nvidia-smi

# Helm-installasjon
echo "Installerer Helm..."
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update && sudo apt install helm -y

# Kubernetes-init og Flannel-nettverk
echo "Initialiserer Kubernetes-klyngen..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "Setter opp Kubernetes Flannel-nettverk..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Ingress Controller
echo "Installerer NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Oppretter brukere og roller
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

# RBAC-roller
echo "Setter opp grunnleggende RBAC for utviklere..."
for i in {1..3}; do
    kubectl create namespace utvikler$i
    kubectl create rolebinding utvikler${i}-role --role=edit --user=utvikler$i --namespace=utvikler$i
done

# NFS-lagring
echo "Setter opp felles NFS-lagring..."
if [ ! -d "/mnt/nfs-share" ]; then
    sudo mkdir -p /mnt/nfs-share
    sudo chown nobody:nogroup /mnt/nfs-share
    sudo chmod 777 /mnt/nfs-share
fi
echo "/mnt/nfs-share *(rw,sync,no_subtree_check)" | sudo tee /etc/exports
sudo exportfs -a
sudo systemctl restart nfs-kernel-server

# Overvåkning og logging
echo "Installerer Grafana, Prometheus og Loki..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add nvidia https://nvidia.github.io/dcgm-exporter
helm repo update
helm install prometheus grafana/kube-prometheus-stack --namespace monitoring --create-namespace
helm install loki grafana/loki-stack --namespace logging --create-namespace
helm install nvidia-dcgm-exporter nvidia/dcgm-exporter --namespace monitoring

# Tjenester via Helm
echo "Kloner og deployer tjenester fra GitHub-repo..."
git clone https://github.com/techneguru/kisandkasse.git /tmp/kisandkasse
helm install code-server /tmp/kisandkasse/charts/code-server --namespace default
helm install ollama /tmp/kisandkasse/charts/ollama --namespace default
helm install jupyterhub /tmp/kisandkasse/charts/jupyterhub --namespace default

# Lokal ingress-konfigurasjon
echo "Setter opp Ingress for tjenester..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kisandkasse-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
  - host: localhost
    http:
      paths:
      - path: /code-server
        pathType: Prefix
        backend:
          service:
            name: code-server
            port:
              number: 8080
      - path: /jupyterhub
        pathType: Prefix
        backend:
          service:
            name: jupyterhub
            port:
              number: 8000
      - path: /flowise
        pathType: Prefix
        backend:
          service:
            name: flowise
            port:
              number: 3000
      - path: /ollama
        pathType: Prefix
        backend:
          service:
            name: ollama
            port:
              number: 11434
EOF

echo "Installerer Flowise..."
sudo docker run -d -p 3000:3000 --name flowise flowiseai/flowise:latest

echo "Validerer Kubernetes pods..."
kubectl get pods --all-namespaces

echo "Systemoppsett fullført. Start maskinen på nytt for å aktivere alle endringer."
