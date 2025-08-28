locals {
  prepare_stage = terraform.workspace == "prepare"
  deploy_stage  = terraform.workspace == "deploy"
}

module "img_proxmox" {
  source = "./modules/img_proxmox"
  count  = local.prepare_stage ? 1 : 0

  proxmox = var.proxmox
  cluster = var.cluster
  vms     = var.vms
}

module "vms_proxmox" {
  source = "./modules/vms_proxmox"
  count  = local.deploy_stage ? 1 : 0

  schematic_id        = var.schematic_id
  schematic_nvidia_id = var.schematic_nvidia_id

  proxmox = var.proxmox
  cluster = var.cluster
  vms     = var.vms
  pci     = var.pci
}

module "talos_k8s" {
  depends_on = [module.vms_proxmox]
  source     = "./modules/talos_k8s"
  count      = local.deploy_stage ? 1 : 0

  cluster = {
    name           = var.cluster.name
    id             = var.cluster.id
    endpoint       = var.cluster.endpoint
    network_dhcp   = var.cluster.network_dhcp
    pod_subnet     = var.cluster.pod_subnet
    service_subnet = var.cluster.service_subnet
  }

  nodes = { for k, vm in var.vms : k => merge(vm, {
    ip = lookup(module.vms_proxmox[0].qemu_ipv4_addresses, k, vm.ip)
  }) }
}

module "init_k8s" {
  depends_on = [module.talos_k8s]
  source     = "./modules/init_k8s"
  count      = local.deploy_stage && (var.certificate != null) ? 1 : 0

  providers = {
    kubernetes = kubernetes
  }

  certificate = var.certificate
}


module "gitops_k8s" {
  depends_on = [module.init_k8s]
  source     = "./modules/gitops_k8s"
  count      = local.deploy_stage && (var.gitops != null) ? 1 : 0

  gitops = var.gitops
}

module "argocd_k8s" {
  depends_on = [module.init_k8s]
  source     = "./modules/argocd_k8s"
  count      = local.deploy_stage && (var.argocd != null) ? 1 : 0

  argocd          = var.argocd
  git_credentials = var.git_credentials
  repo            = var.repo
}