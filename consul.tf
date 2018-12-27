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

module "compute" {
  source            = "./compute"
  prefix            = "consul"
  resource_group    = "${azurerm_resource_group.consul.name}"
  location          = "${var.region}"
  net_prefix_16bit  = "10.0"
  ssh_key_path      = "${var.admin_ssh_key_path}"
  organization_name = "ilkkanomadtest"
}
