provider "azurerm" {
  version = "=1.20.0"
}

variable "region" {
  default = "westeurope"
}

resource "azurerm_resource_group" "main" {
  name     = "nomadtest"
  location = "${var.region}"
}

resource "azurerm_storage_account" "main" {
  name                     = "nomadtest"
  resource_group_name      = "${azurerm_resource_group.main.name}"
  location                 = "${var.region}"
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "state" {
  name                  = "terraform-state"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  storage_account_name  = "${azurerm_storage_account.main.name}"
  container_access_type = "private"
}

output "resource_group_name" {
  value = "${azurerm_resource_group.main.name}"
}

output "storage_account_name" {
  value = "${azurerm_storage_account.main.name}"
}

output "storage_account_access_key" {
  value = "${azurerm_storage_account.main.primary_access_key}"
}

output "container_name" {
  value = "${azurerm_storage_container.state.name}"
}
