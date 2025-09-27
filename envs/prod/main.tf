terraform {
  required_version = ">= 1.6.0"

  # Remote state backend configured via per-env backend.hcl
  backend "s3" {}
}

provider "azurerm" {
  features {}
}
