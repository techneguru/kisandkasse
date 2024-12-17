#!/bin/bash
# Grunnleggende systemforberedelser for KI-miljø med Kubernetes, Docker, NFS og Helm

set -e  # Stopp skriptet ved feil
trap 'echo "Feil på linje $LINENO"; exit 1' ERR

# Oppdater system og installer grunnleggende pakker
echo "Oppdaterer systemet og installerer nødvendige pakker..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git nfs-kernel-server conntrack containerd

# Deaktiver Swap (påkrevd for Kubernetes)
echo "Deaktiverer swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Konfigurer Containerd
echo "Konfigurerer Containerd..."
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

# Installer Docker
echo "Installerer Docker..."
curl -fsSL https://get.docker.com | bash
sudo usermod -aG docker $USER
sudo systemctl enable docker

# Kubernetes-installasjon via Snap
echo "Installerer Kubernetes via Snap..."
sudo snap install kubeadm --classic
sudo snap install kubectl --classic
sudo snap install kubelet --classic

# Aktiver kubelet service
echo "Aktiverer kubelet service..."
sudo systemctl enable snap.kubelet.daemon
sudo systemctl start snap.kubelet.daemon

# Verifiser Kubernetes installasjon
echo "Verifiserer Kubernetes versjoner..."
kubeadm version
kubectl version --client

# Installer Helm via Snap
echo "Installerer Helm..."
sudo snap install helm --classic

# Kubernetes-init
echo "Initialiserer Kubernetes-klyngen..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Nettverksplugin - Flannel
echo "Setter opp Kubernetes Flannel-nettverk..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Ingress Controller
echo "Installerer NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Opprett brukere og roller
echo "Oppretter brukere: kiadmin, instruktør, utvikler1-3..."
for user in kiadmin instruktør utvikler1 utvikler2 utvikler3; do
    sudo useradd -m -s /bin/bash $user || true
    echo "$user:$user" | sudo chpasswd
    sudo usermod -aG docker $user || true
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

# Installer tjenester via Helm
echo "Kloner og deployer tjenester fra GitHub-repo..."
git clone https://github.com/techneguru/kisandkasse.git /tmp/kisandkasse || true
helm install code-server /tmp/kisandkasse/charts/code-server --namespace default
helm install ollama /tmp/kisandkasse/charts/ollama --namespace default
helm install jupyterhub /tmp/kisandkasse/charts/jupyterhub --namespace default

# Installer LangFlow
echo "Installerer LangFlow..."
helm repo add langflow https://langflow.github.io/helm-charts
helm repo update
helm install langflow langflow/langflow --namespace default

# Oppsett for ingress
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

# Installer Flowise Docker container
echo "Installerer Flowise..."
sudo docker run -d -p 3000:3000 --name flowise flowiseai/flowise:latest || true

# Verifisering
echo "Validerer Kubernetes pods..."
kubectl get pods --all-namespaces

echo "Systemoppsett fullført. Start maskinen på nytt for å aktivere alle endringer."
