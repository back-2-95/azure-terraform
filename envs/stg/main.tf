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
  source = "../_modules/common"
}

# Networking and Resource Group
module "network" {
  source        = "../_modules/network"
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

# Key Vault to store MySQL admin credentials (password generated here)
module "keyvault" {
  source              = "../_modules/keyvault"
  project             = module.common.project
  env                 = "stg"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  tags                = module.common.tags
  # Optionally override username; default is "mysqladmin"
  # mysql_admin_username = "mysqladmin"
}

# MySQL Flexible Server; reads admin password from Key Vault
module "mysql" {
  source              = "../_modules/mysql"
  project             = module.common.project
  env                 = "stg"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  sku_name            = "GP_Standard_D2s_v3"
  storage_gb          = 50
  key_vault_id        = module.keyvault.key_vault_id
  depends_on          = [module.keyvault]
}

# Log Analytics workspace for Container Insights
resource "azurerm_log_analytics_workspace" "aks" {
  name                = "law-${module.common.project}-stg"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = module.common.tags
}

# AKS cluster (smallest) using Azure CNI on aks subnet
module "aks" {
  source              = "../_modules/aks"
  project             = module.common.project
  env                 = "stg"
  location            = module.common.location
  resource_group_name = module.network.resource_group_name
  subnet_id           = module.network.subnet_ids["aks"]
  node_count          = 1
  vm_size             = "Standard_B2s"
  tags                = module.common.tags
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aks.id
}

# Kubernetes provider configured from AKS outputs
provider "kubernetes" {
  host                   = module.aks.kube_config.host
  client_certificate     = base64decode(module.aks.kube_config.client_certificate)
  client_key             = base64decode(module.aks.kube_config.client_key)
  cluster_ca_certificate = base64decode(module.aks.kube_config.cluster_ca_certificate)
}

# Example nginx app in namespace myapp
resource "kubernetes_namespace_v1" "myapp" {
  metadata { name = "myapp" }
}

resource "kubernetes_deployment_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace_v1.myapp.metadata[0].name
    labels = {
      app = "nginx"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = { app = "nginx" }
    }
    template {
      metadata {
        labels = { app = "nginx" }
      }
      spec {
        container {
          name  = "nginx"
          image = "nginx:stable"
          port { container_port = 80 }
          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
          }
          resources {
            limits = { cpu = "200m", memory = "256Mi" }
            requests = { cpu = "100m", memory = "128Mi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "nginx" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace_v1.myapp.metadata[0].name
  }
  spec {
    selector = { app = "nginx" }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
    type = "LoadBalancer"
  }
}
