# Kisandkasse: KI Utviklingsplattform

**Kisandkasse** er en komplett KI-utviklingsplattform for lokale GPU-servere. Den tilbyr nødvendige verktøy for utvikling, testing og hosting av KI-applikasjoner som RAG og TAG.

## Innhold
1. [Systemoversikt](#systemoversikt)
2. [Tjenester og Porter](#tjenester-og-porter)
3. [Brukere og Tilgang](#brukere-og-tilgang)
4. [Installasjonsprosess](#installasjonsprosess)
5. [Hvordan starte utviklingen](#hvordan-starte-utviklingen)
6. [Validering og Testing](#validering-og-testing)

---

## Systemoversikt
- **Orkestrering:** Docker, Kubernetes og Helm.
- **Utviklingsverktøy:** Code-Server (webbasert VS Code), JupyterHub, Flowise, LangFlow.
- **Modellkjøring:** Ollama API med støtte for LLaMA-modeller.
- **Lagring:** Felles NFS-lagring for treningsdata.
- **Overvåkning:** Grafana, Prometheus og NVIDIA DCGM Exporter.
- **Logging:** Loki Stack.
- **Ingress:** Tjenester gjøres tilgjengelige via lokale paths.

---

## Tjenester og Porter
| Tjeneste            | URL                             | Port   | Beskrivelse                 |
|---------------------|---------------------------------|--------|-----------------------------|
| **Code-Server**     | `http://<server-ip>/code-server` | 8080   | Nettbasert VS Code-IDE      |
| **JupyterHub**      | `http://<server-ip>/jupyterhub`  | 8000   | Samarbeidsmiljø for Jupyter |
| **Flowise**         | `http://<server-ip>/flowise`     | 3000   | Visuell KI-agent utvikling  |
| **Ollama API**      | `http://<server-ip>/ollama`      | 11434  | API for å kjøre LLaMA-modeller |
| **Felleslagring**   | Montert fra `/mnt/nfs-share`     | N/A    | Fellesområde for treningsdata |
| **Kubernetes Dashboard** | Proxied URL                   | N/A    | Oversikt over Kubernetes    |

---

## Brukere og Tilgang
| Bruker         | Passord      | Tilgang                        |
|----------------|--------------|--------------------------------|
| **kiadmin**    | `kiadmin`    | Administrasjon av systemet     |
| **instruktør** | `instruktør` | Opprette brukere og sandkasser |
| **utvikler1**  | `utvikler1`  | Utvikling og testing           |
| **utvikler2**  | `utvikler2`  | Utvikling og testing           |
| **utvikler3**  | `utvikler3`  | Utvikling og testing           |

---

## Installasjonsprosess
1. **Klon prosjektet og kjør deploy-skriptet**:
   ```bash
   git clone https://github.com/techneguru/kisandkasse.git
   cd kisandkasse/scripts
   chmod +x deploy.sh
   ./deploy.sh
   ```

2. **Restart serveren** når skriptet er fullført.

3. **Valider at alle pods kjører**:
   ```bash
   kubectl get pods --all-namespaces
   ```

---

## Hvordan starte utviklingen

### 1. Logg inn på tjenester
- **Code-Server**: 
   - URL: `http://<server-ip>/code-server`  
   - Bruker/Passord: `utvikler1 / utvikler1`  

- **JupyterHub**: 
   - URL: `http://<server-ip>/jupyterhub`  
   - Bruker/Passord: `utvikler1 / utvikler1`

- **Flowise**: 
   - URL: `http://<server-ip>/flowise`  

- **Ollama API**: 
   - URL: `http://<server-ip>/ollama`

### 2. Konfigurer utviklingsmiljøet lokalt
Monter NFS-lagringen for å få tilgang til felles treningsdata:
```bash
sudo mount -t nfs <server-ip>:/mnt/nfs-share /mnt/nfs-local
```

### 3. Installer nødvendige klientverktøy
**kubectl** og **Helm** installeres lokalt:
```bash
# Installer kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Installer Helm
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https
sudo apt install helm -y
```

---

## Validering og Testing
1. **Valider Code-Server**:
   ```bash
   curl http://<server-ip>/code-server
   ```
2. **Valider Flowise**:
   ```bash
   curl http://<server-ip>/flowise
   ```
3. **Valider Ollama API**:
   ```bash
   curl http://<server-ip>/ollama
   ```

---

## Ressurser og Støtte
- **GitHub Repository**: [techneguru/kisandkasse](https://github.com/techneguru/kisandkasse)
- **Dokumentasjon**: Tilgjengelig i `/docs` på serveren.
