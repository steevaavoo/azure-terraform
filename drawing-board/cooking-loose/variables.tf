variable "resource_group_name" {}
variable "location" {}
variable "admin_username" {}
variable "admin_password" {}
variable "vnet_name" {}

variable "vnet_address_space" {
  type = "list"
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
