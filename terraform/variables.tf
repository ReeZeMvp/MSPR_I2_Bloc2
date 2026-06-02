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

variable "vm_template_name" {
  type    = string
  default = "Templates/tpl-ubuntu2404-k3s"
}
