# Talos Kubernetes on Proxmox

Terraform module for creating a Kubernetes Cluster

* on Proxmox Virtual Environment
* using Talos OS
* and bootraping it with fluxcd

## Prerequisites

* [Proxmox Virtual Environment 9.0](<https://www.proxmox.com/en/>)
* [OpenTofu v1.9.0](<https://opentofu.org/>)
* [Talos v1.10](<https://www.talos.dev/v1.9/introduction/getting-started/>)
* [Kubernetes](<https://kubernetes.io/docs/reference/kubectl/>)
* [fluxcd 2.6.0](<https://fluxcd.io/>)

Before running the module, you need to have an up and running Proxmox cluster configured for [Terraform](<https://registry.terraform.io/providers/bpg/proxmox/latest/docs>)

## Usage

```sh
cat main.tf
module "talos_k8s_cluster" {
  source  = "vdupain/talos-k8s-cluster/proxmox"
  version = "1.7.0"

  cluster = {
    name     = "cluster-demo"
    gateway  = "192.168.10.1"
    cidr     = 24
    endpoint = "192.168.10.210"
  }

  vms = {
    "k8s-cp-0" = {
      host_node      = "pve1"
      machine_type   = "controlplane"
      ip             = "192.168.10.210"
      cpu            = 2
      ram_dedicated  = 4096
      os_disk_size   = 10
      data_disk_size = 10
      datastore_id   = "local-lvm"
    }
    "k8s-cp-1" = {
      host_node      = "pve1"
      machine_type   = "controlplane"
      ip             = "192.168.10.211"
      cpu            = 2
      ram_dedicated  = 4096
      os_disk_size   = 10
      data_disk_size = 10
      datastore_id   = "local-lvm"
    }
    "k8s-cp-2" = {
      host_node      = "pve1"
      machine_type   = "controlplane"
      ip             = "192.168.10.212"
      cpu            = 2
      ram_dedicated  = 4096
      os_disk_size   = 10
      data_disk_size = 10
      datastore_id   = "local-lvm"
    }
  }

  proxmox = {
    endpoint     = "https://pve.domain"
    insecure     = true
    username     = "user"
    password     = "password"
    api_token    = "user@pve!terraform=secret"
  }

  gitops = {
    repository   = "https://github.com/vdupain/gitops.git"
    token        = "github_pat"
    cluster_name = "my-cluster"
  }

}
```

```sh
tofu init
...
tofu apply
...
module.talos_k8s_cluster.module.fluxcd[0].flux_bootstrap_git.this: Still creating... [50s elapsed]
module.talos_k8s_cluster.module.fluxcd[0].flux_bootstrap_git.this: Still creating... [1m0s elapsed]
module.talos_k8s_cluster.module.fluxcd[0].flux_bootstrap_git.this: Creation complete after 1m0s [id=flux-system]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.
```

## Using cluster

Configuration files are store in output folder

```sh
$ ls -l output
total 8
-rw------- 1 devbox devbox 2295 Nov  2 17:23 kube-config.yaml
-rw------- 1 devbox devbox 1653 Nov  2 17:23 talos-config.yaml
```

### Kubernetes cluster

```sh
$ kubectl --kubeconfig output/kube-config.yaml get nodes
NAME   STATUS     ROLES           AGE   VERSION
cp-0   NotReady   control-plane   43s   v1.31.1
cp-1   NotReady   control-plane   43s   v1.31.1
cp-2   NotReady   control-plane   43s   v1.31.1
```

### Talos OS cluster

```sh
$ export CONTROL_PLANE_IP=192.168.10.210
$ export WORKER_IP=192.168.10.211
$ export TALOSCONFIG="output/talos-config.yaml"
$ talosctl config endpoint $CONTROL_PLANE_IP
$ talosctl config node $WORKER_IP
$ talosctl health
discovered nodes: ["192.168.10.210" "192.168.10.211" "192.168.10.212"]
waiting for etcd to be healthy: ...
waiting for etcd to be healthy: OK
waiting for etcd members to be consistent across nodes: ...
waiting for etcd members to be consistent across nodes: OK
waiting for etcd members to be control plane nodes: ...
waiting for etcd members to be control plane nodes: OK
waiting for apid to be ready: ...
waiting for apid to be ready: OK
waiting for all nodes memory sizes: ...
waiting for all nodes memory sizes: OK
waiting for all nodes disk sizes: ...
waiting for all nodes disk sizes: OK
waiting for no diagnostics: ...
waiting for no diagnostics: OK
waiting for kubelet to be healthy: ...
waiting for kubelet to be healthy: OK
waiting for all nodes to finish boot sequence: ...
waiting for all nodes to finish boot sequence: OK
waiting for all k8s nodes to report: ...
waiting for all k8s nodes to report: OK
waiting for all control plane static pods to be running: ...
waiting for all control plane static pods to be running: OK
waiting for all control plane components to be ready: ...
waiting for all control plane components to be ready: OK
waiting for all k8s nodes to report ready: ...
waiting for all k8s nodes to report ready: OK
waiting for kube-proxy to report ready: ...
waiting for kube-proxy to report ready: SKIP
waiting for coredns to report ready: ...
waiting for coredns to report ready: OK
waiting for all k8s nodes to report schedulable: ...
waiting for all k8s nodes to report schedulable: OK
```

### Flux bootstrap

```sh
$ flux --kubeconfig output/kube-config.yaml get kustomization -A
NAMESPACE  	NAME       	REVISION          	SUSPENDED	READY	MESSAGE
flux-system	flux-system	main@sha1:5902d505	False    	True 	Applied revision: main@sha1:5902d505
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.8 |
| <a name="requirement_flux"></a> [flux](#requirement\_flux) | >=1.6.4 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.17.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >=2.38.0 |
| <a name="requirement_local"></a> [local](#requirement\_local) | >=2.5.3 |
| <a name="requirement_proxmox"></a> [proxmox](#requirement\_proxmox) | >=0.78.1 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_local"></a> [local](#provider\_local) | 2.5.2 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_argocd_k8s"></a> [argocd\_k8s](#module\_argocd\_k8s) | ./modules/argocd_k8s | n/a |
| <a name="module_gitops_k8s"></a> [gitops\_k8s](#module\_gitops\_k8s) | ./modules/gitops_k8s | n/a |
| <a name="module_img_proxmox"></a> [img\_proxmox](#module\_img\_proxmox) | ./modules/img_proxmox | n/a |
| <a name="module_init_k8s"></a> [init\_k8s](#module\_init\_k8s) | ./modules/init_k8s | n/a |
| <a name="module_talos_k8s"></a> [talos\_k8s](#module\_talos\_k8s) | ./modules/talos_k8s | n/a |
| <a name="module_vms_proxmox"></a> [vms\_proxmox](#module\_vms\_proxmox) | ./modules/vms_proxmox | n/a |

## Resources

| Name | Type |
|------|------|
| [local_file.kube_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.kube_config_home](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.talos_config](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [local_file.talos_config_home](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd"></a> [argocd](#input\_argocd) | ArgoCD configuration | <pre>object({<br/>    admin_password = string<br/>    namespace      = string<br/>    chart_version  = string<br/>    oidc_config = optional(object({<br/>      name             = string<br/>      issuer           = string<br/>      client_id        = string<br/>      client_secret    = string<br/>      requested_scopes = list(string)<br/>    }))<br/>    custom_rbac = optional(object({<br/>      scopes = list(string)<br/>      policy = list(string)<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_certificate"></a> [certificate](#input\_certificate) | Certificate for k8s sealed-secrets | <pre>object({<br/>    cert = string<br/>    key  = string<br/>  })</pre> | `null` | no |
| <a name="input_cluster"></a> [cluster](#input\_cluster) | Cluster configuration | <pre>object({<br/>    name                  = string<br/>    id                    = optional(number, 0)<br/>    talos_version         = optional(string, "v1.11.3")<br/>    network_dhcp          = optional(bool, false)<br/>    gateway               = optional(string)<br/>    dns_domain            = optional(string)<br/>    dns_servers           = optional(list(string))<br/>    cidr                  = optional(number)<br/>    vlan_id               = optional(number, null)<br/>    network_device_bridge = optional(string, "vmbr0")<br/>    endpoint              = optional(string)<br/>    lvm_label_node        = optional(bool, true)<br/>    cni                   = optional(string, "cilium")<br/>    pod_subnet            = optional(string, "10.244.0.0/16")<br/>    service_subnet        = optional(string, "10.96.0.0/12")<br/>  })</pre> | n/a | yes |
| <a name="input_git_credentials"></a> [git\_credentials](#input\_git\_credentials) | Git repository credentials | <pre>object({<br/>    username    = string<br/>    password    = optional(string)<br/>    private_key = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_gitops"></a> [gitops](#input\_gitops) | GitOps configuration | <pre>object({<br/>    repository   = string<br/>    token        = string<br/>    cluster_name = string<br/>  })</pre> | `null` | no |
| <a name="input_pci"></a> [pci](#input\_pci) | Mapping PCI configuration | <pre>map(object({<br/>    name         = string<br/>    id           = string<br/>    iommu_group  = number<br/>    node         = string<br/>    path         = string<br/>    subsystem_id = string<br/>  }))</pre> | `null` | no |
| <a name="input_proxmox"></a> [proxmox](#input\_proxmox) | Proxmox configuration | <pre>object({<br/>    endpoint           = optional(string)<br/>    insecure           = optional(bool)<br/>    username           = optional(string)<br/>    password           = optional(string)<br/>    realm              = optional(string, "pam")<br/>    api_token          = optional(string)<br/>    ssh_agent          = optional(string, false)<br/>    random_vm_ids      = optional(string, false)<br/>    random_vm_id_start = optional(number, 1000)<br/>    random_vm_id_end   = optional(number, 2000)<br/>  })</pre> | n/a | yes |
| <a name="input_repo"></a> [repo](#input\_repo) | Git repo and path to the ArgoCD Applications | <pre>object({<br/>    name            = string<br/>    repo_url        = string<br/>    branch          = optional(string, "main")<br/>    manifest_path   = string<br/>    project_name    = optional(string, "default")<br/>    recurse         = optional(bool, true)<br/>    ssh_known_hosts = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_schematic_id"></a> [schematic\_id](#input\_schematic\_id) | n/a | `string` | `""` | no |
| <a name="input_schematic_nvidia_id"></a> [schematic\_nvidia\_id](#input\_schematic\_nvidia\_id) | n/a | `string` | `""` | no |
| <a name="input_vms"></a> [vms](#input\_vms) | VMs configuration | <pre>map(object({<br/>    host_node     = string<br/>    vm_id         = optional(number)<br/>    machine_type  = string<br/>    datastore_id  = optional(string, "local-lvm")<br/>    ip            = optional(string)<br/>    cpu           = number<br/>    ram_dedicated = number<br/>    os_disk_size  = optional(number, 10)<br/>    data_disks = optional(list(object({<br/>      size = number<br/>      type = optional(string)<br/>      dev  = optional(string)<br/>      name = optional(string)<br/>    })), [])<br/>    install_disk     = optional(string, "/dev/sda")<br/>    disk_file_format = optional(string, "raw")<br/>    gpu              = optional(string)<br/>    time_server      = optional(string)<br/>    kernel_modules   = optional(list(string), [])<br/>    custom_network   = optional(string)<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Retrieves the name for a k8s Talos cluster |
| <a name="output_config_ipv4_addresses"></a> [config\_ipv4\_addresses](#output\_config\_ipv4\_addresses) | Retrieves VM names with IPv4 address for a k8s Talos cluster |
| <a name="output_kube_config"></a> [kube\_config](#output\_kube\_config) | Retrieves the kubeconfig for a k8s Talos cluster |
| <a name="output_qemu_ipv4_addresses"></a> [qemu\_ipv4\_addresses](#output\_qemu\_ipv4\_addresses) | Retrieves VM names with IPv4 address for a k8s Talos cluster |
| <a name="output_schematic_id"></a> [schematic\_id](#output\_schematic\_id) | n/a |
| <a name="output_schematic_nvidia_id"></a> [schematic\_nvidia\_id](#output\_schematic\_nvidia\_id) | n/a |
| <a name="output_talos_config"></a> [talos\_config](#output\_talos\_config) | Retrieves the talosconfig for a k8s Talos cluster |
| <a name="output_vm_ipv4_address_vms"></a> [vm\_ipv4\_address\_vms](#output\_vm\_ipv4\_address\_vms) | Retrieves IPv4 address for a k8s Talos cluster |
<!-- END_TF_DOCS -->