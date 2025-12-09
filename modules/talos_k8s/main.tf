locals {
  control_plane_nodes = { for k, v in var.nodes : k => v if v.machine_type == "controlplane" }
  control_plane_ips   = [for k, v in local.control_plane_nodes : v.ip]
  worker_nodes        = { for k, v in var.nodes : k => v if v.machine_type == "worker" }
  worker_ips          = [for k, v in local.worker_nodes : v.ip]
  first_control_plane = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]

  # Determine cluster endpoint with priority:
  # 1. VIP if configured (for HA control plane with virtual IP)
  # 2. Explicit endpoint if provided
  # 3. First control plane IP (for DHCP or when endpoint not specified)
  cluster_endpoint = (
    var.cluster.vip_ip != null ? var.cluster.vip_ip :
    var.cluster.endpoint != null ? var.cluster.endpoint :
    local.first_control_plane
  )

  # Detect GPU type for each node (same logic as in vms_proxmox module)
  node_gpu_types = {
    for k, v in var.nodes : k => (
      v.gpu == null ? "none" : (
        can(regex("(?i)nvidia", v.gpu)) ? "nvidia" : "none"
      )
    )
  }

  # GPU patch file paths by type
  gpu_patch_files = {
    nvidia = "${path.module}/config/gpu-nvidia-patch.yaml"
  }
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${local.cluster_endpoint}:6443"
  machine_type       = "controlplane"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${local.cluster_endpoint}:6443"
  machine_type       = "worker"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = local.control_plane_ips
  nodes                = concat(local.control_plane_ips, local.worker_ips)
}

resource "talos_machine_configuration_apply" "controlplane" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  apply_mode                  = "auto"
  for_each                    = local.control_plane_nodes
  node                        = each.value.ip
  config_patches = concat(
    [
      templatefile("${path.module}/config/control-plane.yaml.tmpl", {
        talos_version                      = var.cluster.talos_version
        kubernetes_version                 = var.cluster.kubernetes_version
        hostname                           = each.key
        node_ip                            = each.value.ip
        install_disk                       = each.value.install_disk
        allow_scheduling_on_control_planes = var.cluster.allow_scheduling_on_control_planes
        vip_ip                             = var.cluster.vip_ip
        vip_interface                      = var.cluster.vip_interface
        time_server                        = each.value.time_server
        kernel_modules                     = each.value.kernel_modules
        node_labels                        = each.value.node_labels
        cni                                = var.cluster.cni
        enable_lvm                         = anytrue(flatten([for i, n in var.nodes : [for j, d in n.user_disks : d.type == "lvm"]]))
        lvm_setup = templatefile("${path.module}/kubernetes/lvm-setup.yaml", {
          lvm_label_node = true
        })
        pod_subnet     = var.cluster.pod_subnet
        service_subnet = var.cluster.service_subnet
        custom_network = each.value.custom_network
        cloud_provider = var.cluster.cloud_provider
        extra_hosts    = var.cluster.extra_hosts
      }),
    ],
    var.cluster.cni == "cilium" ? [
      templatefile("${path.module}/config/manifests.yaml.tmpl", {
        manifests = [
          {
            name = "cilium_values"
            data = templatefile("${path.module}/kubernetes/cilium-values.yaml", {
              cluster_name = var.cluster.name
              cluster_id   = var.cluster.id
            })
          },
          {
            name = "cilium_install"
            data = file("${path.module}/kubernetes/cilium-install.yaml")
          }
        ]
      })
    ] : [],
    var.cluster.cni == "calico" ? [
      templatefile("${path.module}/config/manifests.yaml.tmpl", {
        manifests = [
          {
            name = "calico-felix"
            data = file("${path.module}/kubernetes/calico-felix.yaml")
          },
          {
            name = "calico-install"
            data = file("${path.module}/kubernetes/calico-install.yaml")
          },
        ]
      })
    ] : [],
    # Add GPU patch if this control plane node has a GPU
    local.node_gpu_types[each.key] != "none" ? [
      file(local.gpu_patch_files[local.node_gpu_types[each.key]])
    ] : []
  )
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  apply_mode                  = "auto"
  for_each                    = local.worker_nodes
  node                        = each.value.ip
  config_patches = concat(
    [
      templatefile("${path.module}/config/worker.yaml.tmpl", {
        talos_version      = var.cluster.talos_version
        kubernetes_version = var.cluster.kubernetes_version
        hostname           = each.key
        node_ip            = each.value.ip
        install_disk       = each.value.install_disk
        time_server        = each.value.time_server
        kernel_modules     = each.value.kernel_modules
        node_labels        = each.value.node_labels
        enable_lvm         = anytrue([for i, v in each.value.user_disks : v.type == "lvm"])
        custom_network     = each.value.custom_network
        cloud_provider     = var.cluster.cloud_provider
        extra_hosts        = var.cluster.extra_hosts
      }),
    ],
    # Add GPU patch if this worker node has a GPU
    local.node_gpu_types[each.key] != "none" ? [
      file(local.gpu_patch_files[local.node_gpu_types[each.key]])
    ] : []
  )
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.controlplane]

  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane
}

resource "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.this]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane
}

# tflint-ignore: terraform_unused_declarations
data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.controlplane,
    talos_machine_configuration_apply.worker,
    talos_machine_bootstrap.this
  ]
  client_configuration   = data.talos_client_configuration.this.client_configuration
  control_plane_nodes    = local.control_plane_ips
  worker_nodes           = local.worker_ips
  endpoints              = data.talos_client_configuration.this.endpoints
  skip_kubernetes_checks = true

  timeouts = {
    read = "10m"
  }
}
