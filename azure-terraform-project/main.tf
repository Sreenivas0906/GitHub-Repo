provider "azurerm" {
  features {}
}

variable "location" {
  default = "East US"
}

variable "vm_size" {
  default = "Standard_B1s"
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  default = "ChangeMe123!" # Change this to a secure password or use SSH keys instead
}

# Resource Group
resource "azurerm_resource_group" "Resource_Group" {
  name     = "example-resource-group"
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "virtual_network" {
  name                = "example-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Resource_Group.location
  resource_group_name = azurerm_resource_group.Resource_Group.name
}

# Subnet
resource "azurerm_subnet" "example" {
  name                 = "example-subnet"
  resource_group_name  = azurerm_resource_group.Resource_Group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Interface
resource "azurerm_network_interface" "network_Interface" {
  count               = 10
  name                = "example-nic-${count.index}"
  location            = azurerm_resource_group.Resource_Group.location
  resource_group_name = azurerm_resource_group.Resource_Group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machines
resource "azurerm_virtual_machine" "example_vm" {
  count               = 10
  name                = "example-vm-${count.index}"
  location            = azurerm_resource_group.Resource_Group.location
  resource_group_name = azurerm_resource_group.Resource_Group.name
  network_interface_ids = [azurerm_network_interface.network_Interface[count.index].id]
  vm_size            = var.vm_size

  storage_os_disk {
    name              = "example-osdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "hostname-${count.index}"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
