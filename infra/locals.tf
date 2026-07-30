locals {
  base_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = var.repository
  }

  default_tags = var.cost_center == null ? local.base_tags : merge(local.base_tags, { CostCenter = var.cost_center })
}
