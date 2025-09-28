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

variable "key_vault_id" {
  description = "Resource ID of the Azure Key Vault where the MySQL admin password secret is stored"
  type        = string
}

variable "admin_password_secret_name" {
  description = "Name of the Key Vault secret that holds the MySQL admin password"
  type        = string
  default     = "mysql-admin-password"
}
