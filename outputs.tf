output "schematic_id" {
  value = var.prepare_stage ? module.img_proxmox[0].schematic_id : null
}

output "schematic_nvidia_id" {
  value = var.prepare_stage ? module.img_proxmox[0].schematic_nvidia_id : null
}

output "vm_ipv4_address_vms" {
  description = "Retrieves IPv4 address for a k8s Talos cluster"
  value       = var.deploy_stage ? module.vms_proxmox[0].vm_ipv4_address_vms : null
}

output "config_ipv4_addresses" {
  description = "Retrieves VM names with IPv4 address for a k8s Talos cluster"
  value       = var.deploy_stage ? module.vms_proxmox[0].config_ipv4_addresses : null
}

output "qemu_ipv4_addresses" {
  description = "Retrieves VM names with IPv4 address for a k8s Talos cluster"
  value       = var.deploy_stage ? module.vms_proxmox[0].qemu_ipv4_addresses : null
}

output "kube_config" {
  description = "Retrieves the kubeconfig for a k8s Talos cluster"
  value       = var.deploy_stage ? module.talos_k8s[0].kube_config.kubeconfig_raw : null
  sensitive   = true
}

output "talos_config" {
  description = "Retrieves the talosconfig for a k8s Talos cluster"
  value       = var.deploy_stage ? module.talos_k8s[0].talos_config.talos_config : null
  sensitive   = true
}

resource "local_file" "talos_config" {
  count           = var.deploy_stage ? 1 : 0
  content         = module.talos_k8s[0].talos_config.talos_config
  filename        = "output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config" {
  count           = var.deploy_stage ? 1 : 0
  content         = module.talos_k8s[0].kube_config.kubeconfig_raw
  filename        = "output/kube-config.yaml"
  file_permission = "0600"
}

resource "local_file" "kube_config_home" {
  count           = var.deploy_stage ? 1 : 0
  content         = module.talos_k8s[0].kube_config.kubeconfig_raw
  filename        = pathexpand("~/.kube/${var.cluster.name}.yaml")
  file_permission = "0600"
}

resource "local_file" "talos_config_home" {
  count           = var.deploy_stage ? 1 : 0
  content         = module.talos_k8s[0].talos_config.talos_config
  filename        = pathexpand("~/.talos/${var.cluster.name}.yaml")
  file_permission = "0600"
}

output "cluster_name" {
  description = "Retrieves the name for a k8s Talos cluster"
  value       = var.cluster.name
  sensitive   = false
}
