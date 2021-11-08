########################################
# Generic cloud OOB management tooling #
########################################

## Create Azure Resource Group

resource "azurerm_resource_group" "avx-management" {
  name     = "atulrg-oob"
  location = "West Europe"

  tags = {
    environment = "prd"
    solution    = "mgmt"
  }
}

## Create VNet for Aviatrix Controller, Copilot and Fortimanager

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

# Aviatrix CoPilot
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
/*
# Fortimanager
resource "azurerm_network_security_group" "fnt-fortiman-nsg" {
  name                = "fnt-fortiman-nsg"
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
    description                = "https-for-fortimanager"
  }

  security_rule {
    name                       = "AllowDevRegInbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "514"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow 514 in for device registration"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allowout"
  }

  #   security_rule {
  #   name                       = "ssh"
  #   priority                   = 300
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

# nsg attached to Copilot
resource "azurerm_network_interface_security_group_association" "copilot-iface-nsg" {
  network_interface_id      = azurerm_network_interface.avx-copilot-iface.id
  network_security_group_id = azurerm_network_security_group.avx-copilot-nsg.id
}
/*
# nsg attached to FortiManager
resource "azurerm_network_interface_security_group_association" "fortiman-iface-nsg" {
  network_interface_id      = azurerm_network_interface.fnt-manager-iface.id
  network_security_group_id = azurerm_network_security_group.fnt-fortiman-nsg.id
}
*/

## Aviatrix Controller

# AVX Controller Public IP
resource "azurerm_public_ip" "avx-controller-public-ip" {
  name                    = "avx-controller-public-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  domain_name_label       = "heiavicontrol"
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
  name                  = "hei-gdt-mgmt-aviatrix-ctlr-01"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.avx-ctrl-iface.id]
  vm_size               = "Standard_D2s_v3"

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

## Aviatrix Copilot

# AVX Copilot Public IP
resource "azurerm_public_ip" "avx-copilot-public-ip" {
  name                    = "avx-controller-copilot-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  domain_name_label       = "heiavicopilot"
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
  name                  = "hei-gdt-mgmt-aviatrix-cplt-01"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.avx-copilot-iface.id]
  vm_size               = "Standard_D4_v3"

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

/*
## Fortimanager resources

# Fortimanager static public IP
resource "azurerm_public_ip" "fnt-manager-public-ip" {
  name                    = "fnt-manager-public-ip"
  location                = azurerm_resource_group.avx-management.location
  resource_group_name     = azurerm_resource_group.avx-management.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
  domain_name_label       = "heifortiman01"
}

# Fortimanager Network Interface + private IP
resource "azurerm_network_interface" "fnt-manager-iface" {
  name                = "fnt-manager-nic"
  location            = azurerm_resource_group.avx-management.location
  resource_group_name = azurerm_resource_group.avx-management.name

  ip_configuration {
    name                          = "fnt-manager-nic"
    subnet_id                     = azurerm_subnet.avx-management-vnet-subnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.10.10.20"
    public_ip_address_id          = azurerm_public_ip.fnt-manager-public-ip.id
  }
}

# Fortigate Manager VM instance
resource "azurerm_virtual_machine" "fnt-manager" {
  name                  = "hei-gdt-mgmt-fortimanager-ctlr-01"
  location              = azurerm_resource_group.avx-management.location
  resource_group_name   = azurerm_resource_group.avx-management.name
  network_interface_ids = [azurerm_network_interface.fnt-manager-iface.id]
  vm_size               = "Standard_D2_v2"

  delete_data_disks_on_termination = true

  storage_image_reference {
    offer     = "fortinet-fortimanager"
    publisher = "fortinet"
    sku       = "fortinet-fortimanager"
    version   = "6.4.5"
  }

  plan {
    name      = "fortinet-fortimanager"
    publisher = "fortinet"
    product   = "fortinet-fortimanager"
  }

  storage_os_disk {
    name              = "fgtdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "fortimanager"
    admin_username = "heiadmin" #Code Message="The Admin Username specified is not allowed."
    admin_password = "Avi@tr1xRocks!!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
*/
