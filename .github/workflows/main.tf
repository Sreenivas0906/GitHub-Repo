provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "Resource_group" {
  name     = "Test-Rg"
  location = "UK South"
}

resource "azurerm_automation_account" "automation_account" {
  name                = "Test-Automation"
  location            = azurerm_resource_group.Resource_group.location
  resource_group_name = azurerm_resource_group.Resource_group.name
  sku_name            = "Basic"
}

resource "azurerm_automation_runbook" "start_vm" {
  name                    = "StartVMsRunbook"
  location                = azurerm_resource_group.Resource_group.location
  resource_group_name     = azurerm_resource_group.Resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_progress            = "true"
  log_verbose             = "true"
  runbook_type            = "PowerShell"
  content                 = <<EOT
  param (
      [string] \$ResourceGroupName
  )
  \$VMs = Get-AzVM -ResourceGroupName \$ResourceGroupName
  foreach (\$vm in \$VMs) {
      Start-AzVM -ResourceGroupName \$ResourceGroupName -Name \$vm.Name -NoWait
  }
  EOT
}

resource "azurerm_automation_runbook" "stop_vms" {
  name                    = "StopVMsRunbook"
  location                = azurerm_resource_group.Resource_group.location
  resource_group_name     = azurerm_resource_group.Resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  log_progress            = "true"
  log_verbose             = "true"
  runbook_type            = "PowerShell"
  content                 = <<EOT
  param (
      [string] \$ResourceGroupName
  )
  \$VMs = Get-AzVM -ResourceGroupName \$ResourceGroupName
  foreach (\$vm in \$VMs) {
      Stop-AzVM -ResourceGroupName \$ResourceGroupName -Name \$vm.Name -Force -NoWait
  }
  EOT
}

resource "azurerm_automation_schedule" "start_schedule" {
  name                    = "StartVMsSchedule"
  resource_group_name     = azurerm_resource_group.Resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = "2024-02-08T08:00:00Z"
}

resource "azurerm_automation_schedule" "stop_schedule" {
  name                    = "StopVMsSchedule"
  resource_group_name     = azurerm_resource_group.Resource_group.name
  automation_account_name = azurerm_automation_account.automation_account.name
  frequency               = "Day"
  interval                = 1
  timezone                = "UTC"
  start_time              = "2024-02-08T18:00:00Z"
}

resource "azurerm_automation_job_schedule" "start_job" {
  automation_account_name = azurerm_automation_account.automation_account.name
  resource_group_name     = azurerm_resource_group.Resource_group.name
  schedule_name           = azurerm_automation_schedule.start_schedule.name
  runbook_name            = azurerm_automation_runbook.start_vm.name
}

resource "azurerm_automation_job_schedule" "stop_job" {
  automation_account_name = azurerm_automation_account.automation_account.name
  resource_group_name     = azurerm_resource_group.Resource_group.name
  schedule_name           = azurerm_automation_schedule.stop_schedule.name
  runbook_name            = azurerm_automation_runbook.stop_vms.name
}
