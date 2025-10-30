# Tell Terraform to include the hcloud provider
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.52.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

resource "hcloud_network" "private_network" {
  name     = "kubernetes-cluster"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "private_network_subnet" {
  type         = "cloud"
  network_id   = hcloud_network.private_network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

output "network_id" {
  value = hcloud_network.private_network.id
}

resource "hcloud_ssh_key" "me" {
  name       = "iu-k8s-key"
  public_key = file(var.ssh_public_key_path)
}

# Master
resource "hcloud_server" "master-node" {
  name        = "master-node"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.me.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.1"
  }
  user_data = templatefile("${path.module}/cloud-init-master.tmpl", {
    pc_public_key     = trimspace(file(var.ssh_public_key_path))
    worker_public_key = trimspace(file(var.ssh_worker_public_key_path))
    k3s_token          = var.k3s_token
  })
  depends_on = [hcloud_network_subnet.private_network_subnet]
}

# Worker
resource "hcloud_server" "worker-nodes" {
  count       = var.worker_count
  name        = "worker-node-${count.index}"
  image       = var.image
  server_type = var.server_type
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.me.id]
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.private_network.id
    ip         = "10.0.1.${count.index + 2}"
  }
  user_data = templatefile("${path.module}/cloud-init-worker.tmpl", {
    pc_public_key      = trimspace(file(var.ssh_public_key_path))
    worker_private_key = indent(6, file(var.ssh_worker_private_key_path))
    k3s_token          = var.k3s_token
    worker_private_ip  = "10.0.1.${count.index + 2}"
  })

  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master-node]
}