Kisandkasse: Automatisk Oppsett
Introduksjon

Velkommen til Kisandkasse - en komplett plattform for utvikling og testing av KI-applikasjoner. Denne løsningen kombinerer Kubernetes, Docker, Helm og flere verktøy for KI, som Code-Server, JupyterHub, Flowise og LangFlow.

Med denne veiledningen kan du raskt sette opp miljøet på en Ubuntu 24.04-server.
1. Systemkrav

    Operativsystem: Ubuntu Server 24.04 (64-bit)

    Maskinvare:

        Minst 8 GB RAM (anbefalt: 16 GB eller mer)

        Minst 4 CPU-kjerner

        50 GB ledig diskplass

        Internettilgang

2. Forberedelser
1. Last ned Ubuntu 24.04

Last ned og installer Ubuntu Server 24.04 fra den offisielle nettsiden: Ubuntu Server 24.04 LTS
2. Koble til serveren

Bruk en SSH-klient som MobaXterm for å koble til serveren:
ssh <brukernavn>@<server-ip>
3. Manuelle steg før skriptkjøring
Systemoppdatering og installasjon av pakker:
sudo apt update && sudo apt upgrade -y
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git nfs-kernel-server conntrack containerd
Deaktiver Swap:
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
Konfigurer Containerd:
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
Installer Docker:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt-get update && sudo apt-get install -y docker-ce
sudo usermod -aG docker $USER
sudo systemctl enable docker
Installer Kubernetes via APT eller Snap:
curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-jammy main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update && sudo apt-get install -y kubeadm kubelet kubectl || {
    echo "APT feilet. Installerer med Snap."
    sudo snap install kubeadm --classic
    sudo snap install kubectl --classic
    sudo snap install kubelet --classic
    sudo systemctl enable snap.kubelet.daemon
    sudo systemctl start snap.kubelet.daemon
}
sudo apt-mark hold kubeadm kubelet kubectl
sudo systemctl enable kubelet
4. Kjør oppsettskriptet
Last ned og kjør skriptet:
git clone https://github.com/techneguru/kisandkasse.git
cd kisandkasse/scripts
chmod +x deploy.sh
./deploy.sh
5. Tilgang til tjenester

Når skriptet er fullført, kan du få tilgang til følgende tjenester via nettleseren:

    Code-Server (IDE): http://<server-ip>/code-server

    JupyterHub: http://<server-ip>/jupyterhub

    Flowise: http://<server-ip>/flowise

    LangFlow: http://<server-ip>/langflow

    Ollama API: http://<server-ip>/ollama

6. Brukerinnlogging

Standard brukere opprettes automatisk. Logg inn med følgende detaljer:
Brukernavn	Passord
kiadmin	kiadmin
instruktør	instruktør
utvikler1	utvikler1
utvikler2	utvikler2
utvikler3	utvikler3
7. TAG og RAG-eksempler
Last ned eksempler:
git clone https://github.com/techneguru/kisandkasse-examples.git
8. Feilsøking

Hvis oppsettet feiler:

    Kontroller skriptutdata for feil.

    Start serveren på nytt og kjør skriptet på nytt.

    Valider Kubernetes og Docker med disse kommandoene:

kubectl get nodes
docker ps
9. Lisens

Dette prosjektet er lisensiert under MIT-lisensen.
10. Bidrag

Vi ønsker velkommen til bidrag! Følg disse trinnene:

    Fork repositoriet.

    Lag en ny gren (git checkout -b feature-nyfunksjon).

    Utfør endringer og legg til commits (git commit -m 'Legg til ny funksjon').

    Send inn en pull request.

Kontakt

For spørsmål eller hjelp, vennligst kontakt oss på: support@kisandkasse.techne.guru


