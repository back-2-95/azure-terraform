terraform {
  required_version = ">= 1.6.0"

  # Remote state backend configured via per-env backend.hcl
  backend "s3" {}
}

provider "azurerm" {
  features {}
}

# Common shared settings
module "common" {
  source = "../../modules/common"
}

# Networking and Resource Group
module "network" {
  source        = "../../modules/network"
  project       = module.common.project
  env           = "prod"
  location      = module.common.location
  address_space = ["10.30.0.0/16"]
  subnets = {
    aks = "10.30.1.0/24"
    db  = "10.30.2.0/24"
    pe  = "10.30.3.0/24"
  }
  tags = module.common.tags
}

# Key Vault to store MySQL admin credentials (password generated here)
module "keyvault" {
  source              = "../../modules/keyvault"
  project             = module.common.project
  env                 = "prod"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  tags                = module.common.tags
  # Optionally override username; default is "mysqladmin"
  # mysql_admin_username = "mysqladmin"
}

# MySQL Flexible Server; reads admin password from Key Vault
module "mysql" {
  source              = "../../modules/mysql"
  project             = module.common.project
  env                 = "prod"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  sku_name            = "GP_Standard_D2s_v3"
  storage_gb          = 100
  key_vault_id        = module.keyvault.key_vault_id
  depends_on          = [module.keyvault]
}
