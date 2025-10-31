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

resource "hcloud_load_balancer" "ingress_lb" {
  name = "k8s-ingress-lb"
  load_balancer_type = "lb11"
  location           = var.location
}

resource "hcloud_load_balancer_service" "http_service" {
  load_balancer_id = hcloud_load_balancer.ingress_lb.id
  protocol         = "tcp"
  listen_port      = 80
  destination_port = 80
}

resource "hcloud_load_balancer_service" "https_service" {
  load_balancer_id = hcloud_load_balancer.ingress_lb.id
  protocol         = "tcp"
  listen_port      = 443
  destination_port = 443 
}

# Resource: Load Balancer Targets (Attach Workers to the Load Balancer)
resource "hcloud_load_balancer_target" "worker_targets" {
  count            = var.worker_count
  load_balancer_id = hcloud_load_balancer.ingress_lb.id
  type             = "server"
  server_id        = hcloud_server.worker-nodes[count.index].id
  use_private_ip   = true
}

# Resource: Load Balancer Network Attachment (NEW)
resource "hcloud_load_balancer_network" "lb_private_network" {
  load_balancer_id = hcloud_load_balancer.ingress_lb.id
  network_id       = hcloud_network.private_network.id
  ip               = "10.0.1.254" 
}

output "ingress_ip" {
  value = hcloud_load_balancer.ingress_lb.ipv4
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
    k3s_token = var.k3s_token
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
  }
  user_data = templatefile("${path.module}/cloud-init-worker.tmpl", {
    k3s_token          = var.k3s_token
  })

  depends_on = [hcloud_network_subnet.private_network_subnet, hcloud_server.master-node]
}