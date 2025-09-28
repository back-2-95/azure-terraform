// AKS module: creates a minimal AKS cluster using Managed Identity and Azure CNI

locals {
  base_name = "${var.project}-${var.env}"
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-${local.base_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project}-${var.env}"

  kubernetes_version = var.kubernetes_version

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.vm_size
    type                = "VirtualMachineScaleSets"
    only_critical_addons_enabled = false
    vnet_subnet_id      = var.subnet_id
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
    network_policy = "azure"
  }

  role_based_access_control_enabled = true

  tags = merge({
    project = var.project
    env     = var.env
  }, var.tags)
}

output "name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "kube_config" {
  description = "Kube config connection details"
  value = {
    host                   = azurerm_kubernetes_cluster.this.kube_config[0].host
    client_certificate     = azurerm_kubernetes_cluster.this.kube_config[0].client_certificate
    client_key             = azurerm_kubernetes_cluster.this.kube_config[0].client_key
    cluster_ca_certificate = azurerm_kubernetes_cluster.this.kube_config[0].cluster_ca_certificate
  }
  sensitive = true
}
