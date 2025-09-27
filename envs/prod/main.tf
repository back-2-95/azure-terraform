terraform {
  required_version = ">= 1.6.0"

  # Remote state backend configured via per-env backend.hcl
  backend "s3" {}
}

provider "azurerm" {
  features {}
}

# Networking and Resource Group
module "network" {
  source        = "../../modules/network"
  project       = "myapp"
  env           = "prod"
  location      = "northeurope"
  address_space = ["10.30.0.0/16"]
  subnets = {
    aks = "10.30.1.0/24"
    db  = "10.30.2.0/24"
    pe  = "10.30.3.0/24"
  }
  tags = {
    owner = "CHANGE_ME"
  }
}
