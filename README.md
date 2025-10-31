# ☁️ IU Cloud Programming – K3s Cluster on Hetzner Cloud

This project automatically deploys a complete K3s cluster (1 Master, N Workers) on Hetzner Cloud using **Terraform**.

***

## 🧩 Prerequisites

* Account at [Hetzner Cloud](https://console.hetzner.cloud)
* Tools locally installed:
    * [git](https://git-scm.com/)
    * [Terraform](https://developer.hashicorp.com/terraform/downloads)
    * [kubectl](https://kubernetes.io/docs/tasks/tools/) (Optional)

***

## 🚀 Setup & Deployment Guide

### Repository Clone and Setup
```bash
git clone [https://github.com/kainze/iu-cloud-programming.git](https://github.com/kainze/iu-cloud-programming.git)
cd iu-cloud-programming
```
### Create the secrets file
```bash
cp terraform.tfvars.example terraform.tfvars
```
### 🔐 Edit Secrets (terraform.tfvars)
- hcloud_token: -> Create Project at Hetzner and Get Api Token from -> Security -> Api Tokens (Must have Read & Write permissions.)
- k3s_token: The shared token for the K3s cluster (Master & Workers). Recommended to generate a secure random string: openssl rand -hex 32

### 🔑 SSH Keys erstellen

Use this to generate the SSH key to log in to the servers via SSH.

```bash
ssh-keygen -t ed25519 -C "user@hostname.de" -f ~/.ssh/id_ed25519_hetzner
```

## ⚙️ Deployment & Kubernetes Verification

### Initialize and Apply Terraform

Run the following commands to provision all Hetzner resources (network, servers) and execute the cloud-init scripts:

```bash
terraform init
terraform plan
# CAUTION: The 'apply' phase creates paid resources immediately.
terraform apply
```

### ✅ Check Kubernetes Cluster Status

The cluster configuration is complete only after the worker nodes successfully join the master. Wait about 1 minute after terraform apply finishes for the agent services to start and join.

- SSH into the Master Node:

```bash
# Replace <MASTER_PUBLIC_IP> with the public IP address of the Master Node you get that from the Cloud Console
ssh root@<MASTER_PUBLIC_IP>
```

- Check Node Status: Run this command on the master to see the entire cluster state. Wait until both the master and all workers show Ready.

```bash
kubectl get nodes
```

Expected Result:
The output must show all nodes with a Ready status:

### 🧹 Cleanup

To delete all resources created on Hetzner Cloud and stop incurring costs:

```bash
terraform destroy
```

HINT: If you rebuild the servers (terraform apply after a destroy), your local SSH client may reject the connection due to an outdated fingerprint. If this happens, remove the old fingerprint: 
```bash
ssh-keygen -R <IP-AdressoftheServer>
```












# Check the cloud-init logs for errors:
cat /var/log/cloud-init.log 
cat /var/log/cloud-init-output.log