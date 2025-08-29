locals {
  kubernetes = {
    host                   = local.deploy_stage ? module.talos_k8s[0].kube_config.kubernetes_client_configuration.host : ""
    client_certificate     = local.deploy_stage ? base64decode(module.talos_k8s[0].kube_config.kubernetes_client_configuration.client_certificate) : ""
    client_key             = local.deploy_stage ? base64decode(module.talos_k8s[0].kube_config.kubernetes_client_configuration.client_key) : ""
    cluster_ca_certificate = local.deploy_stage ? base64decode(module.talos_k8s[0].kube_config.kubernetes_client_configuration.ca_certificate) : ""
  }
}

provider "vsphere" {
  vsphere_server       = var.vmware.endpoint
  user                 = var.vmware.username
  password             = var.vmware.password
  allow_unverified_ssl = var.vmware.insecure
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

provider "helm" {
  kubernetes {

  }
  alias = "helmtemplate"
}
