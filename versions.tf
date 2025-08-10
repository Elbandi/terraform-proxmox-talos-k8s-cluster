terraform {
  required_version = ">= 1.8"
  required_providers {
    vsphere = {
      source  = "elsoa-invitech/vsphere"
      version = "2.14.1-dev1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.7"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }
  }
}
