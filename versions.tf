terraform {
  required_version = ">= 1.8"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.78.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">=2.38.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">=1.6.4"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.5.3"
    }
  }
}
