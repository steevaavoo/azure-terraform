resource_group_name = "cl-dev-rg"

location = "EastUS"

admin_username = "cladmin"

admin_password = "G0ld5t4r!"

vnet_name = "cl-dev-vnet"

vnet_address_space = ["192.168.0.0/16"]

remote = {
  "subnet_name"   = "cl-dev-remote-subnet"
  "subnet_prefix" = "192.168.1.0/24"
  "vm_name"       = "cl-jump-vm"
  "nsg_name"      = "cl-remote-nsg"
}

wsm = {
  "subnet_name"   = "cl-dev-wsm-subnet"
  "subnet_prefix" = "192.168.14.0/24"
  "vm_name"       = "cl-wsm-dc"

  #  "nsg_name"      = "cl-wsm-nsg"
}

portishead = {
  "subnet_name"   = "cl-dev-portishead-subnet"
  "subnet_prefix" = "192.168.15.0/24"
  "vm_name"       = "cl-portishead-dc"

  #  "nsg_name"      = "cl-portishead-nsg"
}

winscombe = {
  "subnet_name"   = "cl-dev-winscombe-subnet"
  "subnet_prefix" = "192.168.16.0/24"
  "vm_name"       = "cl-winscombe-dc"

  #  "nsg_name"      = "cl-winscombe-nsg"
}
