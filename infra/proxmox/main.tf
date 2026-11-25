#token password to workers join the cluster
resource "random_password" "k3s_token" {
  length  = 48
  special = false
}
locals {
  # IP do CP sem o "/24", para os workers saberem onde está o server
  cp_ip = split("/", one([for v in values(var.vms) : v.ip if v.role == "server"]))[0]
}
resource "proxmox_virtual_environment_file" "user_data" {
  for_each     = var.vms
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id
  node_name    = var.node_name

  source_raw {
    file_name = "${each.key}-user-data.yaml"
    data = templatefile("${path.module}/cloud-init/user-data.yaml.tftpl", {
      hostname       = each.key
      username       = var.user
      ssh_public_key = var.ssh_public_key
      role           = each.value.role
      cp_ip          = local.cp_ip
      k3s_token      = random_password.k3s_token.result
      k3s_version    = var.k3s_version
    })
  }
}
resource "proxmox_virtual_environment_vm" "vm" {
  for_each  = var.vms
  name      = each.key
  node_name = var.node_name

  clone {
    vm_id        = var.template_id
    full         = true
    datastore_id = var.datastore_id
  }

  agent { enabled = true } # require qemu-guest-agent

  cpu {
    cores = each.value.cores
    type  = "x86-64-v2-AES"
  }
  memory { dedicated = each.value.memory }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    size         = each.value.disk
    discard      = "on"
  }

  network_device { bridge = var.bridge }

  initialization {
    datastore_id      = var.datastore_id
    user_data_file_id = proxmox_virtual_environment_file.user_data[each.key].id #isso seta o cicustom para usar o que está configurado dentro de ./cloud-init que foi copiado pelo bloco user_data
    dns {
      servers = var.dns_servers
    }
    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = var.gateway
      }
    }
  }

  operating_system { type = "l26" }
}
