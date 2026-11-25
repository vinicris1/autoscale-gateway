provider "proxmox" {
  endpoint           = var.proxmox_endpoint
  api_token          = trimspace(file(pathexpand(var.proxmox_api_token_file)))
  random_vm_ids      = true
  random_vm_id_start = 200
  random_vm_id_end   = 299
  ssh {
    username    = "root"
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
  }
}
