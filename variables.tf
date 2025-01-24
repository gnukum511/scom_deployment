variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "scom-resource-group"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  default     = "East US"
}

variable "vnet_name" {
  description = "Name of the virtual network"
  default     = "scom-vnet"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  default     = ["10.0.0.0/16"]
}

variable "subnet_name" {
  description = "Name of the subnet"
  default     = "scom-subnet"
}

variable "subnet_address_prefix" {
  description = "Address prefix for the subnet"
  default     = ["10.0.1.0/24"]
}

# Address space for the Bastion subnet
variable "bastion_subnet_address_prefix" {
  description = "The address prefix for the Azure Bastion subnet."
  type        = list(string)
  default     = ["10.0.2.0/24"] # Adjust as needed to fit your VNet
}


variable "vm_size" {
  description = "Size of the virtual machines"
  default     = "Standard_B1s"
}

variable "scom_server_name" {
  description = "Name of the SCOM server virtual machine"
  default     = "scom-server"
}

variable "scom_admin_username" {
  description = "Admin username for the SCOM server"
  default     = "azureuser"
}

variable "scom_admin_password" {
  description = "Admin password for the SCOM server"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "The public SSH key to be added to the Linux virtual machine"
  default     = "~/.ssh/id_rsa.pub" # You can replace this with the correct default path for your SSH public key.
}

variable "linux_agent_username" {
  description = "Admin username for the Linux agent"
  default     = "azureuser"
}

variable "windows_agent_username" {
  description = "Admin username for the Windows agent"
  default     = "azureuser"
}

variable "windows_agent_name" {
  description = "Name of the Windows agent virtual machine"
  default     = "windows-agent"
}

variable "linux_agent_name" {
  description = "Name of the Linux agent virtual machine"
  default     = "linux-agent"
}
