terraform {
  required_version = ">= 1.8"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.10"
    }
    helm = {
      source                = "hashicorp/helm"
      version               = "~> 3.1"
      configuration_aliases = [helm.helmtemplate]
    }
  }
}
