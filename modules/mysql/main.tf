// Azure Database for MySQL Flexible Server module

variable "project" {
  description = "Project name used for naming resources"
  type        = string
}

variable "env" {
  description = "Environment name (dev, stg, prod)"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name where the MySQL server will be created"
  type        = string
}

variable "admin_login" {
  description = "Administrator login name for MySQL"
  type        = string
  default     = "mysqladmin"
}

variable "sku_name" {
  description = "SKU name for MySQL Flexible Server (e.g., B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
}

variable "storage_gb" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

variable "backup_retention_days" {
  description = "Backup retention in days"
  type        = number
  default     = 7
}

variable "geo_redundant_backup" {
  description = "Enable geo-redundant backups"
  type        = bool
  default     = false
}

variable "public_network_access" {
  description = "Enable public network access (Enabled/Disabled). For now we keep it Enabled for simplicity."
  type        = bool
  default     = true
}

resource "random_password" "admin" {
  length           = 20
  special          = true
}

locals {
  base_name = "${var.project}-${var.env}"
}

resource "azurerm_mysql_flexible_server" "this" {
  name                   = "mysql-${local.base_name}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  administrator_login    = var.admin_login
  administrator_password = random_password.admin.result
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
  value       = random_password.admin.result
  sensitive   = true
}

output "port" {
  description = "MySQL server port"
  value       = 3306
}
