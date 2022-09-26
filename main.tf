# Terraform
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.24.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.4.3"
    }
  }
}

# Random provider
provider "random" {
}

# Azure provider
provider "azurerm" {
  features {}
}

resource "random_password" "vm_password" {
  length           = 12
  min_upper        = 2
  min_lower        = 2
  min_special      = 2
  numeric          = true
  special          = true
  override_special = "!@#$%&"
}

resource "random_string" "string" {
  length   = 8
  upper    = false
  numeric  = false
  lower    = true
  special  = false
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.rgname
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "ubuntu-${random_string.string.result}-vnet" 
  location            = azurerm_resource_group.rg.location
  address_space       = [var.vnet-cidr]
  
  tags = {
    environment = var.environment
  }
}

# Subnet
resource "azurerm_subnet" "vm-subnet" {
  resource_group_name    = azurerm_resource_group.rg.name
  name                   = "ubuntu-${random_string.string.result}-subnet"
  address_prefixes       = [var.network-subnet-cidr]
  virtual_network_name   = azurerm_virtual_network.vnet.name
}

# NSG for subnet
resource "azurerm_network_security_group" "nsg" {
  name                = "ubuntu-${var.environment}-${random_string.string.result}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowRDP"
    description                = "Allow RDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

  }

  security_rule {
    name                       = "AllowSSH"
    description                = "Allow SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  tags = {
    environment = var.environment
  }
}

# NSG -> Subnet Association
resource "azurerm_subnet_network_security_group_association" "nsg-subnet-assoc" {
  subnet_id                 = azurerm_subnet.vm-subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Public IP
resource "azurerm_public_ip" "vm-public-ip" {
  resource_group_name = azurerm_resource_group.rg.name
  name = "vm-${random_string.string.result}-publicip"
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"

  tags = {
    environment = var.environment
  }
}

# VM NIC
resource "azurerm_network_interface" "vm-nic" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "ubuntu-${random_string.string.result}-nic"
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name = "internal"
    subnet_id = azurerm_subnet.vm-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.vm-public-ip.id
  }
  
  tags = {
    environment = var.environment
  }
}

# VM
resource "azurerm_linux_virtual_machine" "vm" {
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "ubuntu-${random_string.string.result}-vm"
  location              = azurerm_resource_group.rg.location
  size                  = var.vm-size
  network_interface_ids = [azurerm_network_interface.vm-nic.id]
  
  source_image_reference {
    offer     = var.linux_vm_image_offer
    publisher = var.linux_vm_image_publisher
    sku       = var.ubuntu_1804_sku
    version   = "latest"
  }

  os_disk {
    name                 = "ubuntu-${random_string.string.result}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = var.linux_admin_username
    public_key = file("~/.ssh/dev-env.pub")
  }

  computer_name                   = "ubuntu-${random_string.string.result}-vm"
  admin_username                  = var.linux_admin_username
  admin_password                  = random_password.vm_password.result
  disable_password_authentication = false

  provisioner "local-exec" {
    command = templatefile("ssh-script.tpl", {
      hostname     = self.public_ip_address
      user         = var.linux_admin_username
      identifyfile = "~/.ssh/dev-env"
    })
    interpreter = ["Powershell", "-Command"]
  }

  tags = {
    environment = var.environment
  }
}