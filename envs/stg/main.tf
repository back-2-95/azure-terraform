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
  env           = "stg"
  location      = module.common.location
  address_space = ["10.20.0.0/16"]
  subnets = {
    aks = "10.20.1.0/24"
    db  = "10.20.2.0/24"
    pe  = "10.20.3.0/24"
  }
  tags = module.common.tags
}

# MySQL Flexible Server
module "mysql" {
  source              = "../../modules/mysql"
  project             = module.common.project
  env                 = "stg"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  sku_name            = "GP_Standard_D2s_v3"
  storage_gb          = 50
}
