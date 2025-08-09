locals {
  kubernetes = {
    host                   = var.deploy_stage ? module.talos_k8s[0].kube_config.kubernetes_client_configuration.host : ""
    client_certificate     = var.deploy_stage ? base64decode(module.talos_k8s[0].kube_config.kubernetes_client_configuration.client_certificate) : ""
    client_key             = var.deploy_stage ? base64decode(module.talos_k8s[0].kube_config.kubernetes_client_configuration.client_key) : ""
    cluster_ca_certificate = var.deploy_stage ? base64decode(module.talos_k8s[0].kube_config.kubernetes_client_configuration.ca_certificate) : ""
  }
}

provider "proxmox" {
  endpoint           = var.proxmox.endpoint
  api_token          = var.proxmox.api_token
  username           = var.proxmox.username != null ? "${var.proxmox.username}@${var.proxmox.realm}" : null
  password           = var.proxmox.password
  insecure           = var.proxmox.insecure
  tmp_dir            = "/tmp"
  random_vm_ids      = var.proxmox.random_vm_ids
  random_vm_id_start = var.proxmox.random_vm_id_start
  random_vm_id_end   = var.proxmox.random_vm_id_end

  ssh {
    agent    = var.proxmox.ssh_agent
    username = var.proxmox.username
    password = var.proxmox.password
  }
}

provider "kubernetes" {
  host                   = local.kubernetes.host
  client_certificate     = local.kubernetes.client_certificate
  client_key             = local.kubernetes.client_key
  cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
}

provider "flux" {
  kubernetes = local.kubernetes
  git = {
    url = (var.gitops != null) ? var.gitops.repository : "https://dummy"
    http = {
      username = "git" # This can be any string when using a personal access token
      password = (var.gitops != null) ? var.gitops.token : null
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = local.kubernetes.host
    client_certificate     = local.kubernetes.client_certificate
    client_key             = local.kubernetes.client_key
    cluster_ca_certificate = local.kubernetes.cluster_ca_certificate
  }
}
