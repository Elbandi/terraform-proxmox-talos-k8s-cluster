module "img_proxmox" {
  source = "./modules/img_proxmox"
  count  = var.prepare_stage ? 1 : 0

  proxmox = var.proxmox

  cluster = {
    name                  = var.cluster.name
    gateway               = var.cluster.gateway
    dns_domain            = var.cluster.dns_domain
    dns_servers           = var.cluster.dns_servers
    cidr                  = var.cluster.cidr
    vlan_id               = var.cluster.vlan_id
    talos_version         = var.cluster.talos_version
    network_dhcp          = var.cluster.network_dhcp
    network_device_bridge = var.cluster.network_device_bridge
  }

  vms = var.vms
  pci = var.pci
}

module "vms_proxmox" {
  source = "./modules/vms_proxmox"
  count  = var.deploy_stage ? 1 : 0

  schematic_id        = var.schematic_id
  schematic_nvidia_id = var.schematic_nvidia_id

  proxmox = var.proxmox

  cluster = {
    name                  = var.cluster.name
    gateway               = var.cluster.gateway
    dns_domain            = var.cluster.dns_domain
    dns_servers           = var.cluster.dns_servers
    cidr                  = var.cluster.cidr
    vlan_id               = var.cluster.vlan_id
    talos_version         = var.cluster.talos_version
    network_dhcp          = var.cluster.network_dhcp
    network_device_bridge = var.cluster.network_device_bridge
  }

  vms = var.vms
  pci = var.pci
}

module "talos_k8s" {
  depends_on = [module.vms_proxmox]
  source     = "./modules/talos_k8s"
  count      = var.deploy_stage ? 1 : 0

  cluster = {
    name         = var.cluster.name
    endpoint     = var.cluster.endpoint
    network_dhcp = var.cluster.network_dhcp
  }

  nodes = { for k, vm in var.vms : k => merge(vm, {
    ip = lookup(module.vms_proxmox[0].qemu_ipv4_addresses, k, vm.ip)
  }) }
}

module "init_k8s" {
  depends_on = [module.talos_k8s]
  source     = "./modules/init_k8s"
  count      = var.deploy_stage && (var.certificate != null) ? 1 : 0

  providers = {
    kubernetes = kubernetes
  }

  certificate = var.certificate
}


module "gitops_k8s" {
  depends_on = [module.init_k8s]
  source     = "./modules/gitops_k8s"
  count      = var.deploy_stage && (var.gitops != null) ? 1 : 0

  gitops = var.gitops
}

module "argocd_k8s" {
  depends_on = [module.init_k8s]
  source     = "./modules/argocd_k8s"
  count      = var.deploy_stage && (var.argocd != null) ? 1 : 0

  argocd          = var.argocd
  git_credentials = var.git_credentials
  repo            = var.repo
}