locals {
  base_name = "${var.project}-${var.env}"
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = merge({
    project = var.project
    env     = var.env
  }, var.tags)
}

resource "azurerm_virtual_network" "this" {
  name                = "vnet-${local.base_name}"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = merge({
    project = var.project
    env     = var.env
  }, var.tags)
}

resource "azurerm_subnet" "subnets" {
  for_each             = var.subnets
  name                 = "${each.key}-subnet"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "virtual_network_id" {
  value = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  value = { for k, s in azurerm_subnet.subnets : k => s.id }
}