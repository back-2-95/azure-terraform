// Azure Database for MySQL Flexible Server module

locals {
  base_name = "${var.project}-${var.env}"
}

# Read admin password from Key Vault
data "azurerm_key_vault_secret" "admin_password" {
  name         = var.admin_password_secret_name
  key_vault_id = var.key_vault_id
}

resource "azurerm_mysql_flexible_server" "this" {
  name                   = "mysql-${local.base_name}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_login
  administrator_password = data.azurerm_key_vault_secret.admin_password.value
  version                = "8.0.21"
  sku_name               = var.sku_name

  storage {
    size_gb           = var.storage_gb
    auto_grow_enabled = true
  }

  #backup {
  #  retention_days                = var.backup_retention_days
  #geo_redundant_backup_enabled  = var.geo_redundant_backup
  #}

  public_network_access = var.public_network_access ? "Enabled" : "Disabled"

  tags = {
    project = var.project
    env     = var.env
  }
}

output "server_name" {
  description = "Name of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.this.name
}

output "fqdn" {
  description = "FQDN of the MySQL Flexible Server"
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "admin_login" {
  description = "Administrator login for MySQL"
  value       = azurerm_mysql_flexible_server.this.administrator_login
}

output "admin_password" {
  description = "Administrator password for MySQL (sensitive)"
  value       = data.azurerm_key_vault_secret.admin_password.value
  sensitive   = true
}

output "port" {
  description = "MySQL server port"
  value       = 3306
}
