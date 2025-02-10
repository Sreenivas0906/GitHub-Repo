provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "vm-auto-rg"
  location = "East US"
}

# Automation Account
resource "azurerm_automation_account" "auto_acc" {
  name                = "vm-auto-account"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Basic"
}

# Automation Runbook for VM Start
resource "azurerm_automation_runbook" "start_vm" {
  name                    = "StartVMRunbook"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.auto_acc.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  content                 = <<EOT
param (
    [string]$ResourceGroupName = "vm-auto-rg"
)

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -TenantId $Conn.TenantId -ApplicationId $Conn.ApplicationId -CertificateThumbprint $Conn.CertificateThumbprint

$vms = Get-AzVM -ResourceGroupName $ResourceGroupName
foreach ($vm in $vms) {
    Start-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -NoWait
}
EOT
}

# Automation Runbook for VM Stop
resource "azurerm_automation_runbook" "stop_vm" {
  name                    = "StopVMRunbook"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.auto_acc.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  content                 = <<EOT
param (
    [string]$ResourceGroupName = "vm-auto-rg"
)

$Conn = Get-AutomationConnection -Name AzureRunAsConnection
Connect-AzAccount -ServicePrincipal -TenantId $Conn.TenantId -ApplicationId $Conn.ApplicationId -CertificateThumbprint $Conn.CertificateThumbprint

$vms = Get-AzVM -ResourceGroupName $ResourceGroupName
foreach ($vm in $vms) {
    Stop-AzVM -ResourceGroupName $ResourceGroupName -Name $vm.Name -Force
}
EOT
}

# Schedule to Start VM at 10 AM
resource "azurerm_automation_schedule" "start_schedule" {
  name                    = "StartVMSchedule"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.auto_acc.name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = "2024-02-12T10:00:00Z"
}

# Schedule to Stop VM at 6 PM
resource "azurerm_automation_schedule" "stop_schedule" {
  name                    = "StopVMSchedule"
  resource_group_name     = azurerm_resource_group.rg.name
  automation_account_name = azurerm_automation_account.auto_acc.name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = "2024-02-12T18:00:00Z"
}

# Linking Runbooks with Schedules
resource "azurerm_automation_job_schedule" "start_job" {
  automation_account_name = azurerm_automation_account.auto_acc.name
  resource_group_name     = azurerm_resource_group.rg.name
  schedule_name           = azurerm_automation_schedule.start_schedule.name
  runbook_name           = azurerm_automation_runbook.start_vm.name
}

resource "azurerm_automation_job_schedule" "stop_job" {
  automation_account_name = azurerm_automation_account.auto_acc.name
  resource_group_name     = azurerm_resource_group.rg.name
  schedule_name           = azurerm_automation_schedule.stop_schedule.name
  runbook_name           = azurerm_automation_runbook.stop_vm.name
}
