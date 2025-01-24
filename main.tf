terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "azurerm" {
  features {}
}

data "azurerm_client_config" "current" {}

# Declare the resource group
resource "azurerm_resource_group" "scom_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Declare the virtual network
resource "azurerm_virtual_network" "scom_vnet" {
  name                = var.vnet_name
  location            = azurerm_resource_group.scom_rg.location
  resource_group_name = azurerm_resource_group.scom_rg.name
  address_space       = var.vnet_address_space
}

# Declare the subnet
resource "azurerm_subnet" "scom_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.scom_rg.name
  virtual_network_name = azurerm_virtual_network.scom_vnet.name
  address_prefixes     = var.subnet_address_prefix
}

data "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  key_vault_id = azurerm_key_vault.scom_rg.id
}

# Fetch secret from the Key Vault
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "admin-password"
  key_vault_id = azurerm_key_vault.scom_rg.id
  value        = ""  # Set a value here or leave it empty to update it manually
}

# Declare the Key Vault
resource "azurerm_key_vault" "scom_rg" {
  name                        = "scom-keyvault"
  location                    = azurerm_resource_group.scom_rg.location
  resource_group_name         = azurerm_resource_group.scom_rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete"]
  }
}

# Declare the network interface for the SCOM server
resource "azurerm_network_interface" "scom_server_nic" {
  name                = "scom_server_nic"
  location            = azurerm_resource_group.scom_rg.location
  resource_group_name = azurerm_resource_group.scom_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.scom_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Declare the virtual machine for the SCOM server
resource "azurerm_virtual_machine" "scom_server" {
  name                  = var.scom_server_name
  location              = azurerm_resource_group.scom_rg.location
  resource_group_name   = azurerm_resource_group.scom_rg.name
  network_interface_ids = [azurerm_network_interface.scom_server_nic.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "osdisk-${var.scom_server_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  os_profile {
    computer_name  = var.scom_server_name
    admin_username = var.scom_admin_username
    admin_password = data.azurerm_key_vault_secret.admin_password.value
  }

  tags = {
    environment = "development"
    project     = "scom_project"
  }
}

# Declare the network interface for the Windows agent
resource "azurerm_network_interface" "windows_agent_nic" {
  name                = "windows_agent_nic"
  location            = azurerm_resource_group.scom_rg.location
  resource_group_name = azurerm_resource_group.scom_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.scom_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Bastion Host Public IP
resource "azurerm_public_ip" "scom_bastion_ip" {
  name                = "scom-vnet-bastion-ip"
  location            = azurerm_resource_group.scom_rg.location
  resource_group_name = azurerm_resource_group.scom_rg.name
  allocation_method   = "Static"
  sku                 = "Standard" # Required for Bastion

  tags = {
    environment = "development"
    project     = "scom_project"
  }
}

# Bastion Subnet
resource "azurerm_subnet" "scom_bastion_subnet" {
  name                 = "AzureBastionSubnet" # Must be named exactly this
  resource_group_name  = azurerm_resource_group.scom_rg.name
  virtual_network_name = azurerm_virtual_network.scom_vnet.name
  address_prefixes     = var.bastion_subnet_address_prefix # Add to variables
}

# Bastion Host
resource "azurerm_bastion_host" "scom_bastion" {
  name                = "scom-vnet-bastion"
  location            = azurerm_resource_group.scom_rg.location
  resource_group_name = azurerm_resource_group.scom_rg.name

  ip_configuration {
    name                 = "scom-bastion-ipconfig"
    subnet_id            = azurerm_subnet.scom_bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.scom_bastion_ip.id
  }

  tags = {
    environment = "development"
    project     = "scom_project"
  }
}


# Declare the virtual machine for the Windows agent
resource "azurerm_virtual_machine" "windows_agent" {
  name                  = var.windows_agent_name
  location              = azurerm_resource_group.scom_rg.location
  resource_group_name   = azurerm_resource_group.scom_rg.name
  network_interface_ids = [azurerm_network_interface.windows_agent_nic.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "osdisk-${var.windows_agent_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_profile_windows_config {
    provision_vm_agent        = true
    enable_automatic_upgrades = true
  }

  os_profile {
    computer_name  = var.windows_agent_name
    admin_username = var.windows_agent_username
    admin_password = data.azurerm_key_vault_secret.admin_password.value
  }

  tags = {
    environment = "development"
    project     = "windows_agent_project"
  }
}

# Declare the network interface for the Linux agent
resource "azurerm_network_interface" "linux_agent_nic" {
  name                = "linux_agent_nic"
  location            = azurerm_resource_group.scom_rg.location
  resource_group_name = azurerm_resource_group.scom_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.scom_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Declare the virtual machine for the Linux agent
resource "azurerm_virtual_machine" "linux_agent" {
  name                  = var.linux_agent_name
  location              = azurerm_resource_group.scom_rg.location
  resource_group_name   = azurerm_resource_group.scom_rg.name
  network_interface_ids = [azurerm_network_interface.linux_agent_nic.id]
  vm_size               = var.vm_size

  storage_os_disk {
    name              = "osdisk-${var.linux_agent_name}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = var.linux_agent_name
    admin_username = var.linux_agent_username
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.linux_agent_username}/.ssh/authorized_keys"
      key_data = file(var.ssh_public_key)
    }
  }

  tags = {
    environment = "development"
    project     = "linux_agent_project"
  }
}
