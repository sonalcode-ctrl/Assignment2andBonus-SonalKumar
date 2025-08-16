
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.40.0"
    }
    random = {
     source  = "hashicorp/random"
     version = ">= 3.5.0"
    }
  }
}

provider "azurerm" {
  features {
   
  }
  
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# ------------------ Resource Group ------------------
resource "azurerm_resource_group" "rg" {
  name     = "rg-patch-${random_string.suffix.result}"
  location = var.location
  tags     = var.tags
}

# ------------------ Log Analytics Workspace ------------------
module "log_analytics_workspace" {
  source              = "./modules/log_analytics_workspace"
  name                = "law-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  retention_in_days   = 30
  tags                = var.tags
}

# ------------------ Automation Account (linked to LAW) ------------------
module "automation_account" {
  source                     = "./modules/automation_account"
  name                       = "aa-${random_string.suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  sku_name                   = "Basic"
  log_analytics_workspace_id = module.log_analytics_workspace.id
  tags                       = var.tags
}

# ------------------ Networking ------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${random_string.suffix.result}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${random_string.suffix.result}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags

  security_rule {
    name                       = "rdp"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# ------------------ Windows VM ------------------
resource "azurerm_windows_virtual_machine" "vm" {
  name                  = "vm-${random_string.suffix.result}"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  size                  = var.vm_size
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  network_interface_ids = [azurerm_network_interface.nic.id]
  provision_vm_agent    = true

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = var.tags
}

# ------------------ VM Extension: Microsoft Monitoring Agent (MMA) ------------------
# NOTE: MMA is deprecated in favor of Azure Monitor Agent (AMA), but this is used here
# to satisfy classic Update Management (Automation) linkage. See README for guidance.
resource "azurerm_virtual_machine_extension" "mma" {
  name                 = "mma-agent"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "MicrosoftMonitoringAgent"
  type_handler_version = "1.0"

  settings = jsonencode({
    workspaceId = module.log_analytics_workspace.workspace_id
  })

  protected_settings = jsonencode({
    workspaceKey = module.log_analytics_workspace.primary_shared_key
  })

  depends_on = [module.log_analytics_workspace]
}

# ------------------ Update Management (SUC) ------------------
module "update_management" {
  source                = "./modules/update_management"
  name                  = "weekly-windows-patch"
  automation_account_id = module.automation_account.id
  duration              = var.update_duration

  schedule_description    = var.update_schedule_description
  schedule_frequency      = var.update_schedule_frequency
  schedule_interval       = var.update_schedule_interval
  schedule_start_time_utc = var.update_schedule_start_time_utc
  schedule_time_zone      = var.update_schedule_time_zone

  target_scope_id = azurerm_resource_group.rg.id
  target_location = var.location

  windows_classifications = var.windows_classifications
  linux_classifications   = var.linux_classifications
  reboot_setting_windows  = var.reboot_setting_windows
  reboot_setting_linux    = var.reboot_setting_linux

  # Ensure MMA is installed and LAW link created before SUC
  depends_on = [
    module.automation_account,
    azurerm_virtual_machine_extension.mma
  ]
}

# ------------------ Outputs ------------------
output "resource_group_name" { value = azurerm_resource_group.rg.name }
output "automation_account_name" { value = module.automation_account.name }
output "log_analytics_workspace" { value = module.log_analytics_workspace.name }
output "software_update_config" { value = module.update_management.name }
output "virtual_network_name" { value = azurerm_virtual_network.vnet.name }
output "subnet_name" { value = azurerm_subnet.subnet.name }
output "nsg_name" { value = azurerm_network_security_group.nsg.name }
output "vm_name" { value = azurerm_windows_virtual_machine.vm.name }
