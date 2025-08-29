terraform {
  required_version = ">= 1.8"
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = ">=0.9.0"
    }
    helm = {
      source                = "hashicorp/helm"
      version               = "~> 2.17.0"
      configuration_aliases = [helm.helmtemplate]
    }
  }
}
