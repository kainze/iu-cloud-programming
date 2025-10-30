variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "k3s_token" {
  description = "Shared token for k3s cluster (server/workers)"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Hetzner location (fsn1, nbg1, hel1)"
  type        = string
  default     = "fsn1"
}

variable "server_type" {
  description = "Hetzner server type"
  type        = string
  default     = "cax11"
}

variable "image" {
  description = "Base image"
  type        = string
  default     = "ubuntu-24.04"
}

variable "worker_count" {
  description = "Number of workers"
  type        = number
  default     = 2
}

variable "ssh_public_key_path" {
  description = "Path to your local public SSH key"
  type        = string
  default     = "~/.ssh/id_ed25519_hetzner.pub"
}

variable "my_public_key" {
  description = "my ssh public key"
  type        = string
  sensitive   = true
}
variable "ssh_worker_public_key_path" {
  description = "Path to worker public key"
  type        = string
  default     = "~/.ssh/id_ed25519_k8s_worker.pub"
}

variable "ssh_worker_private_key_path" {
  description = "Path to worker private key"
  type        = string
  default     = "~/.ssh/id_ed25519_k8s_worker"
}