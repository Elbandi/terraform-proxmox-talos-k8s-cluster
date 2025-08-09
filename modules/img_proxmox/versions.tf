terraform {
  required_version = ">= 1.8"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.95"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
  }
}
