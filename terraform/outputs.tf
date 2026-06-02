output "vm_names" {
  value = {
    for name, vm in vsphere_virtual_machine.k3s_nodes :
    name => vm.default_ip_address
  }
  description = "Noms et IPs des VMs deployees"
}
