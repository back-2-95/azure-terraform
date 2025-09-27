// Common module to centralize shared settings across environments

variable "project" {
  description = "Project name used for naming resources"
  type        = string
  default     = "myapp"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "northeurope"
}

variable "tags" {
  description = "Common tags applied to resources (merged by consumers as needed)"
  type        = map(string)
  default = {
    owner = "myorg"
  }
}

output "project" {
  description = "Shared project name"
  value       = var.project
}

output "location" {
  description = "Shared Azure region"
  value       = var.location
}

output "tags" {
  description = "Shared common tags map"
  value       = var.tags
}
