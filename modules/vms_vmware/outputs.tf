output "vm_ipv4_address_vms" {
  description = "IPv4 addresses"
  value = [
    vsphere_virtual_machine.vms
  ]
  sensitive = true
}

output "vm_disk_ids" {
  description = "Disk ids"
  value = {
    for name, vm in vsphere_virtual_machine.vms : trimprefix(name, "${var.cluster.name}-")
    => [for d in slice(vm.disk, 1, length(vm.disk)) : lower(replace(d.uuid, "-", ""))]
  }
}

output "config_ipv4_addresses" {
  description = "IPv4 addresses"
  value = {
    for name, vm in vsphere_virtual_machine.vms : name => element([for ip in vm.guest_ip_addresses : ip if ip != var.cluster.endpoint], 0) if length(vm.guest_ip_addresses) > 0
  }
}

output "qemu_ipv4_addresses" {
  description = "Qemu IPv4 addresses"
  depends_on  = [time_sleep.waiting_if_dhcp]
  value = {
    for name, vm in vsphere_virtual_machine.vms : trimprefix(name, "${var.cluster.name}-")
    => element([for ip in vm.guest_ip_addresses : ip if ip != var.cluster.endpoint], 0)
    if length(vm.guest_ip_addresses) > 0
  }
}