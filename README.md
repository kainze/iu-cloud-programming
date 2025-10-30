# IU Cloud Programming – K3s Cluster auf Hetzner Cloud

Dieses Projekt deployt automatisiert einen vollständigen K3s-Cluster (1 Master, n Worker) auf der Hetzner Cloud mittels **Terraform**.  
Zusätzlich wird der **Hetzner Cloud Controller Manager (CCM)**, **NGINX Ingress Controller** und optional **cert-manager** bereitgestellt.

---

## 🧩 Voraussetzungen

- Account bei [Hetzner Cloud](https://console.hetzner.cloud)
- Tools lokal installiert:
  - [Terraform](https://developer.hashicorp.com/terraform/downloads)
  - [kubectl](https://kubernetes.io/docs/tasks/tools/)
  - [git](https://git-scm.com/)
- SSH-Schlüssel vorhanden (z. B. `~/.ssh/id_ed25519.pub`)
- Optional: Domain/Subdomain für TLS (z. B. `cloudprogramming.kainzmaier.de`)


## 🚀 Anleitung (Setup & Deployment)

### 1. Repository klonen
```bash
git clone https://github.com/kainze/iu-cloud-programming.git
cd iu-cloud-programming
```


### Secrets eintragen
```bash
cp terraform.tfvars.example terraform.tfvars
```

- hccloud_token: -> Create Project at Hetzner and Get Api Token from -> Security -> Api Tokens
- k3s_token: Ein zufälliger String als Shared Token für Master & Worker (z. B. openssl rand -hex 16)
- my_public_key: Dein öffentlichen SSH-Key (z. B. ~/.ssh/id_ed25519.pub)

### 🔑 SSH Keys erstellen

Dieser Key wird verwendet, um dich selbst per SSH auf die Server einzuloggen.

```bash
ssh-keygen -t ed25519 -C "user@hostname.de" -f ~/.ssh/id_ed25519_hetzner
```

### ⚙️ Terraform initialisieren & ausführen

Nachdem alle Variablen in `terraform.tfvars` gesetzt sind und die SSH-Keys erstellt wurden, kann das Projekt provisioniert werden.

#### 1️⃣ Terraform initialisieren

```bash
terraform init
terraform plan
terraform apply
```

Later we want to Destroy it again so we have no costs. 
```bash
terraform destroy
```

Hint: If you redeploy the server you have to remove the fingerprint of the server
```bash
ssh-keygen -R <IP-AdressoftheServer>
```

### Check Kubernetes
- Get the IP Adress from Hetzner
- ssh into it
```bash
ssh root@<IP-AdressoftheServer>
```
- check i k3s is running
```bash
kubectl get nodes
```












# Check the cloud-init logs for errors:
cat /var/log/cloud-init.log 
cat /var/log/cloud-init-output.log