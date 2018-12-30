provider "azurerm" {
  version = "=1.20.0"
}

terraform {
  backend "azurerm" {
    storage_account_name = "nomadtest"
    container_name       = "terraform-state"
    key                  = "prod.terraform.tfstate"
  }
}

data "azurerm_resource_group" "main" {
  name = "nomadtest"
}

data "azurerm_client_config" "current" {}

resource "azurerm_azuread_application" "consul" {
  name = "consul"
}

resource "azurerm_azuread_service_principal" "consul" {
  application_id = "${azurerm_azuread_application.consul.application_id}"
}

resource "random_string" "consul_password" {
  length  = 20
  special = false
}

resource "azurerm_azuread_service_principal_password" "consul" {
  service_principal_id = "${azurerm_azuread_service_principal.consul.id}"
  value                = "${random_string.consul_password.result}"
  end_date             = "${timeadd(timestamp(), "${365 * 24}h")}"
}

resource "azurerm_role_assignment" "consul" {
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = "${azurerm_azuread_service_principal.consul.id}"
}

data "azurerm_image" "consul" {
  name_regex          = "consul-ubuntu"
  sort_descending     = true
  resource_group_name = "${data.azurerm_resource_group.main.name}"
}

resource "azurerm_virtual_network" "main" {
  name                = "nomad-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.region}"
  resource_group_name = "${data.azurerm_resource_group.main.name}"
}

module "consul_cluster" {
  source                = "./compute"
  prefix                = "consul"
  image_id              = "${data.azurerm_image.consul.id}"
  resource_group        = "${data.azurerm_resource_group.main.name}"
  location              = "${var.region}"
  virtual_network_name  = "${azurerm_virtual_network.main.name}"
  subnet_address_prefix = "10.0.1.0/24"
  ssh_key_path          = "${var.admin_ssh_key_path}"
  organization_name     = "ilkkanomadtest"
  run_command           = "/opt/consul/bin/run-consul --server --subscription-id ${data.azurerm_client_config.current.subscription_id} --tenant-id ${data.azurerm_client_config.current.tenant_id} --client-id ${azurerm_azuread_application.consul.application_id} --secret-access-key ${random_string.consul_password.result}"
}

module "nomad_cluster" {
  source                = "./compute"
  prefix                = "nomad"
  image_id              = "${data.azurerm_image.consul.id}"
  resource_group        = "${data.azurerm_resource_group.main.name}"
  location              = "${var.region}"
  virtual_network_name  = "${azurerm_virtual_network.main.name}"
  subnet_address_prefix = "10.0.2.0/24"
  ssh_key_path          = "${var.admin_ssh_key_path}"
  organization_name     = "ilkkanomadtest"
  run_command           = "/opt/consul/bin/run-consul --client --scale-set-name ${module.consul_cluster.scale_set_name}  --subscription-id ${data.azurerm_client_config.current.subscription_id} --tenant-id ${data.azurerm_client_config.current.tenant_id} --client-id ${azurerm_azuread_application.consul.application_id} --secret-access-key ${random_string.consul_password.result}"
  cluster_size          = 2
}
