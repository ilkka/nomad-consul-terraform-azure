variable "resource_group" {}
variable "location" {}
variable "prefix" {}
variable "net_prefix_16bit" {}
variable "ssh_key_path" {}
variable "organization_name" {}
variable "image_id" {}
variable "run_command" {}

variable "count" {
  default = "3"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-vnet"
  address_space       = ["${var.net_prefix_16bit}.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${var.resource_group}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "${var.net_prefix_16bit}.2.0/24"
}

resource "azurerm_virtual_machine_scale_set" "nodes" {
  name                = "${var.prefix}-cluster"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group}"
  upgrade_policy_mode = "Manual"

  sku {
    capacity = "${var.count}"
    name     = "Standard_F2"
    tier     = "Standard"
  }

  storage_profile_image_reference {
    id = "${var.image_id}"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_profile_data_disk {
    lun           = 0
    caching       = "ReadWrite"
    create_option = "Empty"
    disk_size_gb  = 10
  }

  os_profile {
    computer_name_prefix = "${var.prefix}"
    admin_username       = "${var.prefix}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys = [{
      key_data = "${file(var.ssh_key_path)}"
      path     = "/home/${var.prefix}/.ssh/authorized_keys"
    }]
  }

  network_profile {
    name    = "${var.prefix}-network-profile"
    primary = true

    ip_configuration {
      name      = "${var.prefix}-ip-config"
      primary   = true
      subnet_id = "${azurerm_subnet.internal.id}"

      public_ip_address_configuration {
        name              = "${var.prefix}-public-ip-config"
        idle_timeout      = 4
        domain_name_label = "${var.organization_name}-${var.prefix}"
      }
    }
  }

  extension {
    name                 = "provision"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.0"

    settings = <<SETTINGS
    {
      "commandToExecute": "${var.run_command}"
    }
    SETTINGS
  }
}

output "scale_set_name" {
  value = "${azurerm_virtual_machine_scale_set.nodes.name}"
}
