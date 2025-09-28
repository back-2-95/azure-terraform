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
  description = "Resource group name where the AKS cluster will be created"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for AKS nodes (Azure CNI)"
  type        = string
}

variable "node_count" {
  description = "Default node pool node count"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Optional Kubernetes version for AKS"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to AKS"
  type        = map(string)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "If set, enables Container Insights (OMS agent) and attaches this Log Analytics Workspace ID"
  type        = string
  default     = null
}
