terraform {
  required_version = ">= 1.5.0"

  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.6"
    }
  }
}

provider "vsphere" {
  user                 = var.vcenter_username
  password             = var.vcenter_password
  vsphere_server       = var.vcenter_server
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vcenter_datacenter
}

data "vsphere_host" "host" {
  name          = var.vcenter_host
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "ds" {
  name          = var.vcenter_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "net" {
  name          = var.vcenter_network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.vm_template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

locals {
  nodes = {
    "k3s-cp" = {
      cpu  = 2
      mem  = 4096
      disk = 30
    }
    "k3s-w1" = {
      cpu  = 2
      mem  = 4096
      disk = 30
    }
    "k3s-w2" = {
      cpu  = 2
      mem  = 4096
      disk = 30
    }
  }
}

resource "vsphere_virtual_machine" "k3s_nodes" {
  for_each = local.nodes

  name             = each.key
  resource_pool_id = data.vsphere_host.host.resource_pool_id
  datastore_id     = data.vsphere_datastore.ds.id

  num_cpus = each.value.cpu
  memory   = each.value.mem
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id   = data.vsphere_network.net.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = each.value.disk
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
  }
}
