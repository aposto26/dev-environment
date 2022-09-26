variable "rgname" {
  type = string
  description = "Name of the resource group"
}

variable "location" {
  type = string
  description = "Azure region where the resource group/resources are being deployed"
}

variable "vnet-cidr" {
  type = string
  description = "Address given to the virtual network"
  default = "10.0.0.0/16"
}

variable "network-subnet-cidr" {
  type = string
  description = "Address given to subnet sitting within the virtual network"
  default = "10.0.0.0/24"
}

variable "environment" {
  type = string
  description = "Label definition of the VM workspace"
}

variable "linux_admin_username" {
  type = string
  description = "Name given to the VM administrator"
}

variable "vm-size" {
  type = string
  description = "Describes the SKU size used for the VM"
  default = "Standard_B2s"
}
