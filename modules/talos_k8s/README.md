<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.1 |
| <a name="requirement_talos"></a> [talos](#requirement\_talos) | ~> 0.10 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_helm.helmtemplate"></a> [helm.helmtemplate](#provider\_helm.helmtemplate) | ~> 3.1 |
| <a name="provider_talos"></a> [talos](#provider\_talos) | 0.10.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [talos_cluster_kubeconfig.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/cluster_kubeconfig) | resource |
| [talos_machine_bootstrap.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_bootstrap) | resource |
| [talos_machine_configuration_apply.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_configuration_apply.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_configuration_apply) | resource |
| [talos_machine_secrets.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/resources/machine_secrets) | resource |
| [helm_template.cilium_from_values](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template) | data source |
| [talos_client_configuration.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/client_configuration) | data source |
| [talos_cluster_health.this](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/cluster_health) | data source |
| [talos_machine_configuration.controlplane](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |
| [talos_machine_configuration.worker](https://registry.terraform.io/providers/siderolabs/talos/latest/docs/data-sources/machine_configuration) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Cluster configuration | <pre>object({<br/>    name                               = string<br/>    id                                 = optional(number, 0)<br/>    talos_version                      = optional(string)<br/>    kubernetes_version                 = optional(string)<br/>    endpoint                           = string<br/>    network_dhcp                       = optional(bool, false)<br/>    allow_scheduling_on_control_planes = optional(bool, true)<br/>    vip_ip                             = optional(string)<br/>    vip_interface                      = optional(string, "eth0")<br/>    lvm_label_node                     = optional(bool, true)<br/>    cni                                = optional(string, "cilium")<br/>    pod_subnet                         = optional(string, "10.244.0.0/16")<br/>    service_subnet                     = optional(string, "10.96.0.0/12")<br/>    mtu                                = optional(number, 1450)<br/>    cloud_provider                     = optional(string, "none")<br/>    extra_hosts                        = optional(map(list(string)), {})<br/>    registries = optional(map(object({<br/>      username = string<br/>      password = string<br/>    })), {})<br/>  })</pre> | n/a | yes |
| <a name="input_nodes"></a> [nodes](#input\_nodes) | Configuration for worker nodes | <pre>map(object({<br/>    machine_type = string<br/>    ip           = string<br/>    swap_size    = optional(number, 0)<br/>    install_disk = optional(string, "/dev/sda")<br/>    user_disks = optional(list(object({<br/>      type = optional(string)<br/>      dev  = optional(string)<br/>      name = optional(string)<br/>    })), [])<br/>    extra_mounts = optional(list(object({<br/>      destination = string<br/>      type        = string<br/>      source      = string<br/>      options     = optional(list(string), [])<br/>    })), [])<br/>    gpu            = optional(string)<br/>    time_server    = optional(string)<br/>    kernel_modules = optional(list(string), [])<br/>    node_labels    = optional(map(any), {})<br/>    custom_network = optional(string)<br/>    disk_uuid      = map(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | Kubernetes configuration file |
| <a name="output_talos_config"></a> [talos\_config](#output\_talos\_config) | Talos configuration file |
<!-- END_TF_DOCS -->