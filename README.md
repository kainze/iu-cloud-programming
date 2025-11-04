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

Copy the network ID from the output and save it for later.


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


## Create an example deployment
### Nginx Ingress Controller 

```bash
wget -q https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.13.0/deploy/static/provider/cloud/deploy.yaml -O /tmp/nginx.yaml

sed -i -e "s/kind: Deployment/kind: DaemonSet/g" /tmp/nginx.yaml
sed -i -e "s/data: null/data:/g" /tmp/nginx.yaml
sed -i -e '/^kind: ConfigMap.*/i  \ \ compute-full-forwarded-for: \"true\"\n \ use-forwarded-headers: \"true\"\n \ use-proxy-protocol: \"true\"\n \ keep-alive: \"off\"' /tmp/nginx.yaml
sed -i -e "s/strategy:/updateStrategy:/g" /tmp/nginx.yaml


kubectl apply -f /tmp/nginx.yaml
```

Replace <your_api_token> with your own Hetzner API token, and <network_id> with the network ID you got from the output terraform apply.

```bash
kubectl -n kube-system apply -f https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/v1.26.0/ccm-networks.yaml
kubectl -n kube-system create secret generic hcloud \
  --from-literal=token=<your_api_token> \
  --from-literal=network=<network_id>
```

Check if the nodes have the correct Provider

```bash
kubectl describe node master-node | grep "ProviderID"
kubectl describe node worker-node-0 | grep "ProviderID"
```

The output should be hcloud://<id>

Now copy/create the file whoami.yaml on the master node:
```bash
nano whoami.yaml
```

Next, apply the file, If you have a public domain and a SSL certificate, upload or create the SSL certificate in Hetzner Console and change some lines below in the whoami.yaml
```bash
kubectl apply -f whoami.yaml
```

View the pods and the deployment.
```bash
kubectl -n ingress-nginx get pods
kubectl -n ingress-nginx get deployments
kubectl -n ingress-nginx get svc
```

### 🧹 Cleanup

To delete all resources created on Hetzner Cloud and stop incurring costs:
```bash
kubectl -n ingress-nginx delete deployment whoami
kubectl -n ingress-nginx delete service whoami
```


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