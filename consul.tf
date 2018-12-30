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

resource "azurerm_resource_group" "consul" {
  name     = "consul-resources"
  location = "${var.region}"
}

resource "azurerm_resource_group" "nomad" {
  name     = "nomad-resources"
  location = "${var.region}"
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

data "azurerm_image" "consul" {
  name_regex          = "consul-ubuntu"
  sort_descending     = true
  resource_group_name = "nomadtest"
}

output "consul_server_command_line" {
  value = "/opt/consul/bin/run-consul --server --subscription-id ${data.azurerm_client_config.current.subscription_id} --tenant-id ${data.azurerm_client_config.current.tenant_id} --client-id ${azurerm_azuread_application.consul.application_id} --secret-access-key ${random_string.consul_password.result}"
}

module "consul_cluster" {
  source            = "./compute"
  prefix            = "consul"
  image_id          = "${data.azurerm_image.consul.id}"
  resource_group    = "${azurerm_resource_group.consul.name}"
  location          = "${var.region}"
  net_prefix_16bit  = "10.0"
  ssh_key_path      = "${var.admin_ssh_key_path}"
  organization_name = "ilkkanomadtest"
  run_command       = "/opt/consul/bin/run-consul --server --subscription-id ${data.azurerm_client_config.current.subscription_id} --tenant-id ${data.azurerm_client_config.current.tenant_id} --client-id ${azurerm_azuread_application.consul.application_id} --secret-access-key ${random_string.consul_password.result}"
}

module "nomad_cluster" {
  source            = "./compute"
  prefix            = "nomad"
  image_id          = "${data.azurerm_image.consul.id}"
  resource_group    = "${azurerm_resource_group.nomad.name}"
  location          = "${var.region}"
  net_prefix_16bit  = "10.1"
  ssh_key_path      = "${var.admin_ssh_key_path}"
  organization_name = "ilkkanomadtest"
  run_command       = "/opt/consul/bin/run-consul --client --scale-set ${module.consul_cluster.scale_set_name}  --subscription-id ${data.azurerm_client_config.current.subscription_id} --tenant-id ${data.azurerm_client_config.current.tenant_id} --client-id ${azurerm_azuread_application.consul.application_id} --secret-access-key ${random_string.consul_password.result}"
}
