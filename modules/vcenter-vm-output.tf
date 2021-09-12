output "vm_default_ip_addr" {
  value = var.ssh_ip_address != "" ? var.ssh_ip_address : vsphere_virtual_machine.vm.default_ip_address
}
