# Creating the Resource Group
resource "azurerm_resource_group" "cl_rg" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"

  tags {
    environment = "dev"
    category    = "group"
  }
}

#region Networking
# Define the Virtual Network - to contain the subnets
resource "azurerm_virtual_network" "cl_vnet" {
  name                = "${var.vnet_name}"
  address_space       = "${var.vnet_address_space}"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  tags {
    environment = "dev"
    category    = "network"
  }
}

# Define the Remote Subnet - for external access and admin
resource "azurerm_subnet" "cl_remote_subnet" {
  name                      = "${var.remote["subnet_name"]}"
  resource_group_name       = "${azurerm_resource_group.cl_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.cl_vnet.name}"
  address_prefix            = "${var.remote["subnet_prefix"]}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_remote.id}"
}

# Define the WSM Subnet
resource "azurerm_subnet" "cl_wsm_subnet" {
  name                      = "${var.wsm["subnet_name"]}"
  resource_group_name       = "${azurerm_resource_group.cl_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.cl_vnet.name}"
  address_prefix            = "${var.wsm["subnet_prefix"]}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
}

# Define the Portishead Subnet
resource "azurerm_subnet" "cl_portishead_subnet" {
  name                      = "${var.portishead["subnet_name"]}"
  resource_group_name       = "${azurerm_resource_group.cl_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.cl_vnet.name}"
  address_prefix            = "${var.portishead["subnet_prefix"]}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
}

# Define the Winscombe Subnet
resource "azurerm_subnet" "cl_winscombe_subnet" {
  name                      = "${var.winscombe["subnet_name"]}"
  resource_group_name       = "${azurerm_resource_group.cl_rg.name}"
  virtual_network_name      = "${azurerm_virtual_network.cl_vnet.name}"
  address_prefix            = "${var.winscombe["subnet_prefix"]}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
}

#endregion Networking

#region Network Security
# Network Security Group and Rule for Remote Subnet
resource "azurerm_network_security_group" "cl_nsg_remote" {
  name                = "${var.remote["nsg_name"]}"
  location            = "${azurerm_resource_group.cl_rg.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  security_rule {
    name                       = "rdp-rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags {
    environment = "dev"
    category    = "network"
  }
}

# Not Using this as it has an issue - and causes a hang if used along with nested NSG definition in azurerm_subnet resources above
# # Associating the Remote Network Security Group with the Remote Subnet
# resource "azurerm_subnet_network_security_group_association" "remote_nsg_assoc" {
#   subnet_id                 = "${azurerm_subnet.cl_remote_subnet.id}"
#   network_security_group_id = "${azurerm_network_security_group.cl_nsg_remote.id}"
# }

# Network Security Group and Rule for Internal Subnets
resource "azurerm_network_security_group" "cl_nsg_internal" {
  name                = "internal-nsg"
  location            = "${azurerm_resource_group.cl_rg.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  # security_rule {
  #   name                       = "all-comms-rule"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }

  tags {
    environment = "dev"
    category    = "network"
  }
}

# Not Using this as it has an issue - and causes a hang if used along with nested NSG definition in azurerm_subnet resources above
# # Associating the Internal Network Security Group with the WSM Subnet
# resource "azurerm_subnet_network_security_group_association" "wsm_nsg_assoc" {
#   subnet_id                 = "${azurerm_subnet.cl_wsm_subnet.id}"
#   network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
# }

# Not Using this as it has an issue - and causes a hang if used along with nested NSG definition in azurerm_subnet resources above
# # Associating the Internal Network Security Group with the Portishead Subnet
# resource "azurerm_subnet_network_security_group_association" "portishead_nsg_assoc" {
#   subnet_id                 = "${azurerm_subnet.cl_portishead_subnet.id}"
#   network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
# }

# Not Using this as it has an issue - and causes a hang if used along with nested NSG definition in azurerm_subnet resources above
# # Associating the Internal Network Security Group with the Winscombe Subnet
# resource "azurerm_subnet_network_security_group_association" "winscombe_nsg_assoc" {
#   subnet_id                 = "${azurerm_subnet.cl_winscombe_subnet.id}"
#   network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
# }

#endregion Network Security

#region Jump Server
# Generating a random string for FQDN Prefix
resource "random_string" "fqdn" {
  length  = 6
  special = false
  upper   = false
  number  = false
}

# Requesting Public IP Address
resource "azurerm_public_ip" "cl_jump_pip" {
  name                = "jump-pip"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"
  allocation_method   = "Dynamic"
  domain_name_label   = "${random_string.fqdn.result}"

  tags {
    environment = "dev"
    category    = "network"
  }
}

# Creating Jump Server NIC and binding to Public IP
resource "azurerm_network_interface" "cl_jump_nic" {
  name                = "jump-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  ip_configuration {
    name                          = "cl-jump-nic-configuration"
    subnet_id                     = "${azurerm_subnet.cl_remote_subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.cl_jump_pip.id}"
  }

  tags {
    environment = "dev"
    category    = "network"
  }
}

resource "azurerm_virtual_machine" "cl_jump_server" {
  name                             = "${var.remote["vm_name"]}"
  location                         = "${var.location}"
  resource_group_name              = "${azurerm_resource_group.cl_rg.name}"
  network_interface_ids            = ["${azurerm_network_interface.cl_jump_nic.id}"]
  vm_size                          = "${var.vm["vm_size"]}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "${var.vm["sku"]}"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.remote["vm_name"]}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.vm["managed_disk_type"]}"
  }

  os_profile {
    computer_name  = "${var.remote["vm_name"]}"
    admin_username = "${var.vm["admin_username"]}"
    admin_password = "${var.vm["admin_password"]}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "${var.vm["provision_vm_agent"]}"
    enable_automatic_upgrades = "${var.vm["enable_automatic_upgrades"]}"
    timezone                  = "${var.vm["timezone"]}"

    # winrm                     = "${var.vm["winrm"]}"

    # additional_unattend_config = "${var.vm["additional_unattend_config"]}"
  }
}

#endregion Jump Server

#region WSM DC
# Creating WSM DC NIC
resource "azurerm_network_interface" "cl_wsm_dc_nic" {
  name                = "wsm-dc-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  ip_configuration {
    name                          = "cl-wsm-dc-nic-configuration"
    subnet_id                     = "${azurerm_subnet.cl_wsm_subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    environment = "dev"
    category    = "network"
  }
}

resource "azurerm_virtual_machine" "cl_wsm_dc_server" {
  name                             = "${var.wsm["vm_name"]}"
  location                         = "${var.location}"
  resource_group_name              = "${azurerm_resource_group.cl_rg.name}"
  network_interface_ids            = ["${azurerm_network_interface.cl_wsm_dc_nic.id}"]
  vm_size                          = "${var.vm["vm_size"]}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "${var.vm["sku"]}"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.wsm["vm_name"]}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.vm["managed_disk_type"]}"
  }

  os_profile {
    computer_name  = "${var.wsm["vm_name"]}"
    admin_username = "${var.vm["admin_username"]}"
    admin_password = "${var.vm["admin_password"]}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "${var.vm["provision_vm_agent"]}"
    enable_automatic_upgrades = "${var.vm["enable_automatic_upgrades"]}"
    timezone                  = "${var.vm["timezone"]}"

    # winrm                     = "${var.vm["winrm"]}"

    # additional_unattend_config = "${var.vm["additional_unattend_config"]}"
  }
}

#endregion WSM DC

#region Portishead DC
# Creating Portishead DC NIC
resource "azurerm_network_interface" "cl_portishead_dc_nic" {
  name                = "portishead-dc-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  ip_configuration {
    name                          = "cl-portishead-dc-nic-configuration"
    subnet_id                     = "${azurerm_subnet.cl_portishead_subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    environment = "dev"
    category    = "network"
  }
}

resource "azurerm_virtual_machine" "cl_portishead_dc_server" {
  name                             = "${var.portishead["vm_name"]}"
  location                         = "${var.location}"
  resource_group_name              = "${azurerm_resource_group.cl_rg.name}"
  network_interface_ids            = ["${azurerm_network_interface.cl_portishead_dc_nic.id}"]
  vm_size                          = "${var.vm["vm_size"]}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "${var.vm["sku"]}"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.portishead["vm_name"]}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.vm["managed_disk_type"]}"
  }

  os_profile {
    computer_name  = "${var.portishead["vm_name"]}"
    admin_username = "${var.vm["admin_username"]}"
    admin_password = "${var.vm["admin_password"]}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "${var.vm["provision_vm_agent"]}"
    enable_automatic_upgrades = "${var.vm["enable_automatic_upgrades"]}"
    timezone                  = "${var.vm["timezone"]}"

    # winrm                     = "${var.vm["winrm"]}"

    # additional_unattend_config = "${var.vm["additional_unattend_config"]}"
  }
}

#endregion Portishead DC

#region Winscombe DC
# Creating Winscombe DC NIC
resource "azurerm_network_interface" "cl_winscombe_dc_nic" {
  name                = "winscombe-dc-nic1"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.cl_rg.name}"

  ip_configuration {
    name                          = "cl-winscombe-dc-nic-configuration"
    subnet_id                     = "${azurerm_subnet.cl_winscombe_subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }

  tags {
    environment = "dev"
    category    = "network"
  }
}

resource "azurerm_virtual_machine" "cl_winscombe_dc_server" {
  name                             = "${var.winscombe["vm_name"]}"
  location                         = "${var.location}"
  resource_group_name              = "${azurerm_resource_group.cl_rg.name}"
  network_interface_ids            = ["${azurerm_network_interface.cl_winscombe_dc_nic.id}"]
  vm_size                          = "${var.vm["vm_size"]}"
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "${var.vm["sku"]}"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.winscombe["vm_name"]}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "${var.vm["managed_disk_type"]}"
  }

  os_profile {
    computer_name  = "${var.winscombe["vm_name"]}"
    admin_username = "${var.vm["admin_username"]}"
    admin_password = "${var.vm["admin_password"]}"
  }

  os_profile_windows_config {
    provision_vm_agent        = "${var.vm["provision_vm_agent"]}"
    enable_automatic_upgrades = "${var.vm["enable_automatic_upgrades"]}"
    timezone                  = "${var.vm["timezone"]}"

    # winrm                     = "${var.vm["winrm"]}"

    # additional_unattend_config = "${var.vm["additional_unattend_config"]}"
  }
}

#endregion Winscombe DC

