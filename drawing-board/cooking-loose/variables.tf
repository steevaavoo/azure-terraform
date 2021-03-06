variable "resource_group_name" {}
variable "location" {}
variable "vnet_name" {}

variable "vnet_address_space" {
  type = "list"
}

variable "vm" {
  type = "map"
}

variable "remote" {
  type = "map"
}

variable "wsm" {
  type = "map"
}

variable "portishead" {
  type = "map"
}

variable "winscombe" {
  type = "map"
}
