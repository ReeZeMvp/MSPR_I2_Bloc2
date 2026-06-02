packer {
  required_plugins {
    vsphere = {
      version = "~> 1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

variable "vcenter_server" {
  type = string
}

variable "vcenter_username" {
  type = string
}

variable "vcenter_password" {
  type      = string
  sensitive = true
}

variable "vcenter_datacenter" {
  type = string
}

variable "vcenter_host" {
  type = string
}

variable "vcenter_datastore" {
  type = string
}

variable "vcenter_network" {
  type = string
}

variable "iso_path" {
  type = string
}

variable "ssh_username" {
  type    = string
  default = "admk3s"
}

variable "ssh_password" {
  type      = string
  sensitive = true
  default   = "K3s@MSPR2025!"
}

source "vsphere-iso" "ubuntu-k3s-template" {
  vcenter_server      = var.vcenter_server
  username            = var.vcenter_username
  password            = var.vcenter_password
  insecure_connection = true

  datacenter = var.vcenter_datacenter
  host       = var.vcenter_host
  datastore  = var.vcenter_datastore
  folder     = "Templates"

  vm_name              = "tpl-ubuntu2404-k3s"
  guest_os_type        = "ubuntu64Guest"
  CPUs                 = 2
  RAM                  = 4096
  RAM_reserve_all      = false
  disk_controller_type = ["pvscsi"]

  storage {
    disk_size             = 30720
    disk_thin_provisioned = true
  }

  network_adapters {
    network      = var.vcenter_network
    network_card = "vmxnet3"
  }

  iso_paths = [var.iso_path]

  cd_files = ["./http/user-data", "./http/meta-data"]
  cd_label = "cidata"

  boot_command = [
    "c<wait>",
    "linux /casper/vmlinuz autoinstall ds='nocloud;' ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  boot_wait = "5s"

  ssh_username           = var.ssh_username
  ssh_password           = var.ssh_password
  ssh_timeout            = "30m"
  ssh_handshake_attempts = 100

  convert_to_template = true
  remove_cdrom        = true
}

build {
  name    = "ubuntu-k3s"
  sources = ["source.vsphere-iso.ubuntu-k3s-template"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl wget open-iscsi nfs-common ca-certificates gnupg lsb-release qemu-guest-agent python3",
      "sudo systemctl enable qemu-guest-agent",
      "sudo systemctl enable iscsid",
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo truncate -s 0 /etc/machine-id",
      "sudo rm -f /var/lib/dbus/machine-id",
      "sudo cloud-init clean --logs --seed",
      "sudo rm -rf /tmp/* /var/tmp/*",
      "sudo apt-get clean",
      "sudo sync",
    ]
  }
}
