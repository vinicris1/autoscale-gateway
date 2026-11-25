variable "proxmox_endpoint" {
  description = "URL API Proxmox"
  type        = string
}

variable "proxmox_api_token_file" {
  description = "Local file with Proxmox API token format: user@realm!id=secret"
  type        = string
  default     = "~/.config/proxmox/terraform-token"
}
variable "node_name" {
  description = "proxmox node name"
  type        = string
  default     = "vinicin"
}
variable "ssh_public_key" {
  description = "public ssh key added in the vms via cloud-init"
  type        = string
}

variable "vms" {
  description = "cluster vm configuration"
  type = map(object({
    cores  = number
    memory = number
    disk   = number
    ip     = string # CIDR, e.g. "192.168.1.51/24"
  }))
}
variable "gateway" {
  description = "default gateway for vms"
  type        = string
}
variable "template_id" {
  description = "template ID on proxmox"
  type        = number
  default     = 9000
}
variable "datastore_id" {
  description = "storage for the vm disk and cloud-init drive"
  type        = string
  default     = "local-zfs"
}
variable "snippets_datastore_id" {
  description = "Cloud-init files storage to install apps/packages..."
  type        = string
  default     = "local"
}
variable "user" {
  description = "default user for the vms"
  type        = string
  default     = "vinicin"
}
variable "bridge" {
  description = "network bridge for vms"
  type        = string
  default     = "vmbr0"
}
variable "disk_size" {
  description = "default disk space"
  type        = number
  default     = 20
}
variable "dns_servers" {
  description = "default dns server"
  type        = list(string)
}
