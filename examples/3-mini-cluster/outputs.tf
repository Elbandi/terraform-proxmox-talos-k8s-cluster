output "cluster_name" {
  description = "Cluster name"
  value       = module.talos_k8s_cluster.cluster_name
  sensitive   = false
}

output "config_ipv4_addresses" {
  description = "IPv4 addresses"
  value       = module.talos_k8s_cluster.config_ipv4_addresses
}

output "schematic_id" {
  value = module.talos_k8s_cluster.schematic_id
}

output "schematic_nvidia_id" {
  value = module.talos_k8s_cluster.schematic_nvidia_id
}
