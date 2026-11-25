terraform {
  required_version = ">= 1.17"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.123"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}
