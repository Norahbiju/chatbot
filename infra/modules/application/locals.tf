locals {
  name_prefix    = "${var.project_name}-${var.environment}"
  account_suffix = substr(sha1("${data.aws_caller_identity.current.account_id}-${var.aws_region}"), 0, 10)
  kb_arn         = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}"
  model_arn      = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}::foundation-model/${var.model_id}"
  api_domain     = replace(aws_apigatewayv2_api.chat.api_endpoint, "https://", "")

  base_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = var.repository
  }

  default_tags = var.cost_center == null ? local.base_tags : merge(local.base_tags, { CostCenter = var.cost_center })
}
