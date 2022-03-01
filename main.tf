########################################
# Generic cloud OOB management tooling #
########################################

## Create Azure Resource Group


terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "avx-management" {
  name     = "atulrg-oob"
  location = "West Europe"

  tags = {
    environment = "prd"
    solution    = "mgmt"
  }
}

## Create VNet for Aviatrix Controller, Copilot 

resource "azurerm_virtual_network" "avx-management-vnet" {
  name                = "atuvnet-oob"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name
  address_space       = ["10.10.10.0/24"]
}

resource "azurerm_subnet" "avx-management-vnet-subnet1" {
  name                 = "atulsub-oob"
  resource_group_name  = azurerm_resource_group.avx-management.name
  virtual_network_name = azurerm_virtual_network.avx-management-vnet.name
  address_prefixes     = ["10.10.10.0/24"]
}

## Create Network Security Groups

# Aviatrix controller
resource "azurerm_network_security_group" "avx-controller-nsg" {
  name                = "atulavtx-controller"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  security_rule {
    name                       = "https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "https-for-controller"
  }

  #   security_rule {
  #   name                       = "ssh"
  #   priority                   = 200
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  #   description = "ssh-for-controller" # only when AVX Support asks !!
  #
  # }

  lifecycle {
    ignore_changes = [security_rule]
  }
}

/* Aviatrix CoPilot
resource "azurerm_network_security_group" "avx-copilot-nsg" {
  name                = "atlavtx-copilot"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  security_rule {
    name                       = "https"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "https-for-copilot"
  }

  security_rule {
    name                       = "netflow"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "udp"
    source_port_range          = "*"
    destination_port_range     = "31283"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "netflow-for-copilot"
  }

  security_rule {
    name                       = "syslog"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "udp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "syslog-for-copilot"
  }
  #   security_rule {
  #   name                       = "ssh"
  #   priority                   = 400
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "22"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  #   description = "ssh-for-copilot" # only when AVX Support asks !!
  #
  # }
  lifecycle {
    ignore_changes = [security_rule]
  }
}
*/
## Attach Network Interface and a Network Security Group

# nsg attached to Controller
resource "azurerm_network_interface_security_group_association" "controller-iface-nsg" {
  network_interface_id      = azurerm_network_interface.avx-ctrl-iface.id
  network_security_group_id = azurerm_network_security_group.avx-controller-nsg.id
}



## Aviatrix Controller

# AVX Controller Public IP
resource "azurerm_public_ip" "avx-controller-public-ip" {
  name                    = "avx-controller-public-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  domain_name_label       = "atulavtx-ctrl"
}

# AVX Controller Interface
resource "azurerm_network_interface" "avx-ctrl-iface" {
  name                = "avx-ctrl-nic"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  ip_configuration {
    name                          = "avx-controller-nic"
    subnet_id                     = azurerm_subnet.avx-management-vnet-subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.10.10"
    public_ip_address_id          = azurerm_public_ip.avx-controller-public-ip.id
  }
}

# AVX Controller VM instance
resource "azurerm_virtual_machine" "avx-controller" {
  name                  = "atulavtx-ctlr01"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.avx-ctrl-iface.id]
  vm_size               = "Standard_B1ms"

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "aviatrix-systems"
    offer     = "aviatrix-bundle-payg"
    sku       = "aviatrix-enterprise-bundle-byol"
    version   = "latest"
  }

  plan {
    name      = "aviatrix-enterprise-bundle-byol"
    publisher = "aviatrix-systems"
    product   = "aviatrix-bundle-payg"
  }

  storage_os_disk {
    name              = "avxdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "avx-controller"
    admin_username = "avxadmin" #Code Message="The Admin Username specified is not allowed."
    admin_password = "Avi@tr1xRocks!!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
/*
## Aviatrix Copilot

# AVX Copilot Public IP
resource "azurerm_public_ip" "avx-copilot-public-ip" {
  name                    = "avx-controller-copilot-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  domain_name_label       = "atulavtx-copilot"
}

# AVX Copilot Interface
resource "azurerm_network_interface" "avx-copilot-iface" {
  name                = "avx-copilot-nic"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  ip_configuration {
    name                          = "avx-copilot-nic"
    subnet_id                     = azurerm_subnet.avx-management-vnet-subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.10.15"
    public_ip_address_id          = azurerm_public_ip.avx-copilot-public-ip.id
  }
}

# AVX Copilot VM instance
resource "azurerm_virtual_machine" "avx-copilot" {
  name                  = "atulavtx-cplt01"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.avx-copilot-iface.id]
  vm_size               = "Standard_B1ms"

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "aviatrix-systems"
    offer     = "aviatrix-copilot"
    sku       = "avx-cplt-byol-01"
    version   = "latest"
  }

  plan {
    name      = "avx-cplt-byol-01"
    publisher = "aviatrix-systems"
    product   = "aviatrix-copilot"
  }

  storage_os_disk {
    name              = "avxcpltdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "avx-copilot "
    admin_username = "avxadmin"           #Code Message="The Admin Username specified is not allowed."
    admin_password = "Avi@tr1xRocks!!HnK" #
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
*/

module "copilot_build_azure" {
  source                         = "github.com/AviatrixSystems/terraform-modules-copilot.git//copilot_build_azure"
  copilot_name                   = "atulcopilot"
  virtual_machine_admin_username = "attila10"
  virtual_machine_admin_password = "Aviatrix123#"
  location                       = "West Europe"
  use_existing_vnet              = "true"
  resource_group_name            = azurerm_resource_group.avx-management.name
  subnet_id                      = azurerm_subnet.avx-management-vnet-subnet1.id


  allowed_cidrs = {
    "tcp_cidrs" = {
      priority = "100"
      protocol = "tcp"
      ports    = ["443"]
      cidrs    = ["0.0.0.0/0"]
    }
    "udp_cidrs" = {
      priority = "200"
      protocol = "udp"
      ports    = ["5000", "31283"]
      cidrs    = ["0.0.0.0/0"]
    }
  }

  additional_disks = {
    "one" = {
      managed_disk_id = "copilotdata"
      lun             = "1"
    }
    "two" = {
      managed_disk_id = "copilotdata2"
      lun             = "2"
    }
  }
  depends_on = [
    azurerm_subnet.avx-management-vnet-subnet1,
  ]  
}
