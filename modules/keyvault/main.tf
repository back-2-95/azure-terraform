// Azure Key Vault module to store MySQL admin credentials

locals {
  base_name = "${var.project}-${var.env}"
}

data "azurerm_client_config" "current" {}

# Random suffix to ensure global KV name uniqueness; total length <= 24
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_key_vault" "this" {
  name                        = substr("kv-${local.base_name}-${random_string.suffix.result}", 0, 24)
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = var.sku_name
  soft_delete_retention_days  = 7
  purge_protection_enabled    = var.enable_purge_protection
  rbac_authorization_enabled   = false

  tags = merge({
    project = var.project
    env     = var.env
  }, var.tags)
}

# Allow current principal (the one running Terraform) to manage secrets
resource "azurerm_key_vault_access_policy" "current_principal" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore"
  ]
}

# Generate a strong MySQL admin password and store it in Key Vault
resource "random_password" "mysql_admin" {
  length           = 24
  special          = true
}

# Store MySQL admin username
resource "azurerm_key_vault_secret" "mysql_admin_username" {
  name         = "mysql-admin-username"
  value        = var.mysql_admin_username
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.current_principal]
}

# Store MySQL admin password (sensitive)
resource "azurerm_key_vault_secret" "mysql_admin_password" {
  name         = "mysql-admin-password"
  value        = random_password.mysql_admin.result
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_key_vault_access_policy.current_principal]
}

output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "Resource ID of the Key Vault"
}

output "key_vault_name" {
  value       = azurerm_key_vault.this.name
  description = "Name of the Key Vault"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "URI of the Key Vault"
}

output "mysql_admin_username_secret_id" {
  value       = azurerm_key_vault_secret.mysql_admin_username.id
  description = "Resource ID of the MySQL admin username secret"
}

output "mysql_admin_password_secret_id" {
  value       = azurerm_key_vault_secret.mysql_admin_password.id
  description = "Resource ID of the MySQL admin password secret"
  sensitive   = true
}
