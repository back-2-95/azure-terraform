
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
  description = "Resource group name where the Key Vault will be created"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "sku_name" {
  description = "Key Vault SKU name (standard or premium)"
  type        = string
  default     = "standard"
}

variable "enable_purge_protection" {
  description = "Enable purge protection on the Key Vault"
  type        = bool
  default     = false
}

variable "mysql_admin_username" {
  description = "MySQL admin username to store as a secret"
  type        = string
  default     = "mysqladmin"
}
