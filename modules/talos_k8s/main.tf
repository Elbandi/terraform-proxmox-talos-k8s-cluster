locals {
  control_plane_nodes = { for k, v in var.nodes : k => v if v.machine_type == "controlplane" }
  control_plane_ips   = [for k, v in local.control_plane_nodes : v.ip]
  worker_nodes        = { for k, v in var.nodes : k => v if v.machine_type == "worker" }
  worker_ips          = [for k, v in local.worker_nodes : v.ip]
  first_control_plane = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  cluster_vip         = var.cluster.endpoint != null ? "https://${var.cluster.endpoint}:6443" : "https://${local.first_control_plane}:6443"
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.cluster.name
  cluster_endpoint = local.cluster_vip
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster.name
  cluster_endpoint = local.cluster_vip
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets
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
  for_each                    = local.control_plane_nodes
  node                        = each.value.ip
  endpoint                    = each.value.ip
  config_patches = compact([
    templatefile("${path.module}/config/control-plane.yaml.tmpl", {
      hostname       = each.key
      node_ip        = each.value.ip
      cluster_vip    = var.cluster.endpoint
      install_disk   = each.value.install_disk
      time_server    = each.value.time_server
      kernel_modules = each.value.kernel_modules
      node_labels    = each.value.node_labels
      cni            = var.cluster.cni
      enable_lvm     = anytrue(flatten([for i, n in var.nodes : [for j, d in n.data_disks : d.type == "lvm"]]))
      lvm_setup = templatefile("${path.module}/kubernetes/lvm-setup.yaml", {
        lvm_label_node = true
      })
      pod_subnet     = var.cluster.pod_subnet
      service_subnet = var.cluster.service_subnet
      custom_network = each.value.custom_network
      cloud_provider = var.cluster.cloud_provider
      extra_hosts    = var.cluster.extra_hosts
    }),
    var.cluster.cni == "cilium" ? templatefile("${path.module}/config/manifests.yaml.tmpl", {
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
    }) : "",
    var.cluster.cni == "calico" ? templatefile("${path.module}/config/manifests.yaml.tmpl", {
      manifests = [
        {
          name = "calico-felix"
          data = file("${path.module}/kubernetes/calico-felix.yaml")
        },
        {
          name = "calico-install"
          data = templatefile("${path.module}/kubernetes/calico-install.yaml.tmpl", {
            mtu        = var.cluster.mtu
            pod_subnet = var.cluster.pod_subnet
          })
        },
      ]
    }) : "",
    file("${path.module}/config/falco-patch.yaml"),
  ])
}

resource "talos_machine_configuration_apply" "worker" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each = {
    for k, v in local.worker_nodes : k => v
    if v.gpu == null
  }
  node = each.value.ip
  config_patches = [
    templatefile("${path.module}/config/worker.yaml.tmpl", {
      hostname       = each.key
      node_ip        = each.value.ip
      install_disk   = each.value.install_disk
      time_server    = each.value.time_server
      kernel_modules = each.value.kernel_modules
      node_labels    = each.value.node_labels
      enable_lvm     = anytrue([for i, d in each.value.data_disks : d.type == "lvm"])
      custom_network = each.value.custom_network
      cloud_provider = var.cluster.cloud_provider
      extra_hosts    = var.cluster.extra_hosts
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker_gpu" {
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  for_each = {
    for k, v in local.worker_nodes : k => v
    if v.gpu != null
  }
  node = each.value.ip
  config_patches = [
    templatefile("${path.module}/config/worker.yaml.tmpl", {
      hostname       = each.key
      node_ip        = each.value.ip
      install_disk   = each.value.install_disk
      time_server    = each.value.time_server
      kernel_modules = each.value.kernel_modules
      node_labels    = each.value.node_labels
      enable_lvm     = anytrue([for i, d in each.value.data_disks : d.type == "lvm"])
      custom_network = each.value.custom_network
      cloud_provider = var.cluster.cloud_provider
      extra_hosts    = var.cluster.extra_hosts
    }),
    file("${path.module}/config/gpu-worker-patch.yaml"),
    file("${path.module}/config/nvidia-default-runtimeclass.yaml"),
  ]
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

