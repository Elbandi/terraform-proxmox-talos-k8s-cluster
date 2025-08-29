locals {
  prepare_stage = terraform.workspace == "prepare"
  deploy_stage  = terraform.workspace == "deploy"
}

module "img_vmware" {
  source = "./modules/img_vmware"
  count  = local.prepare_stage ? 1 : 0

  vmware  = var.vmware
  cluster = var.cluster
  vms     = var.vms
}

module "vms_vmware" {
  source = "./modules/vms_vmware"
  count  = local.deploy_stage ? 1 : 0

  vmware  = var.vmware
  cluster = var.cluster
  vms     = var.vms
  pci     = var.pci
}

module "talos_k8s" {
  depends_on = [module.vms_vmware]
  source     = "./modules/talos_k8s"
  count      = local.deploy_stage ? 1 : 0

  cluster = {
    name                               = var.cluster.name
    id                                 = var.cluster.id
    talos_version                      = var.cluster.talos_version
    kubernetes_version                 = var.cluster.kubernetes_version
    endpoint                           = var.cluster.endpoint
    network_dhcp                       = var.cluster.network_dhcp
    allow_scheduling_on_control_planes = var.cluster.allow_scheduling_on_control_planes
    vip_ip                             = var.cluster.vip_ip
    vip_interface                      = var.cluster.vip_interface
    cni                                = var.cluster.cni
    pod_subnet                         = var.cluster.pod_subnet
    service_subnet                     = var.cluster.service_subnet
    mtu                                = var.cluster.mtu
    cloud_provider                     = var.cluster.cloud_provider
    extra_hosts                        = var.cluster.extra_hosts
    registries                         = var.cluster.registries
  }

  nodes = { for k, vm in var.vms : k => merge(vm, {
    ip        = lookup(module.vms_vmware[0].qemu_ipv4_addresses, k, vm.ip)
    disk_uuid = { for i, d in vm.user_disks : lookup(module.vms_vmware[0].vm_disk_ids, k)[i] => "${d.type}-${d.name}-${i + 1}" }
  }) }

  providers = {
    helm.helmtemplate = helm.helmtemplate
  }
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
