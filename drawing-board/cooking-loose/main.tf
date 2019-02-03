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

# Associating the Remote Network Security Group with the Remote Subnet
resource "azurerm_subnet_network_security_group_association" "remote_nsg_assoc" {
  subnet_id                 = "${azurerm_subnet.cl_remote_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_remote.id}"
}

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

# Associating the Internal Network Security Group with the WSM Subnet
resource "azurerm_subnet_network_security_group_association" "wsm_nsg_assoc" {
  subnet_id                 = "${azurerm_subnet.cl_wsm_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
}

# Associating the Internal Network Security Group with the Portishead Subnet
resource "azurerm_subnet_network_security_group_association" "portishead_nsg_assoc" {
  subnet_id                 = "${azurerm_subnet.cl_portishead_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
}

# Associating the Internal Network Security Group with the Winscombe Subnet
resource "azurerm_subnet_network_security_group_association" "winscombe_nsg_assoc" {
  subnet_id                 = "${azurerm_subnet.cl_winscombe_subnet.id}"
  network_security_group_id = "${azurerm_network_security_group.cl_nsg_internal.id}"
}

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
    private_ip_address_allocation = "dynamic"
    public_ip_address_id          = "${azurerm_public_ip.cl_jump_pip.id}"
  }

  tags {
    environment = "dev"
    category    = "network"
  }
}

resource "azurerm_virtual_machine" "cl_jump_server" {
  name                  = "${var.remote["vm_name"]}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.cl_rg.name}"
  network_interface_ids = ["${azurerm_network_interface.cl_jump_nic.id}"]
  vm_size               = "Standard_D1"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.remote["vm_name"]}-os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.remote["vm_name"]}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
  }

  os_profile_windows_config {
    enable_automatic_upgrades = false
  }
}

#endregion Jump Server

