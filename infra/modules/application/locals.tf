locals {
  name_prefix                = "${var.project_name}-${var.environment}"
  account_suffix             = substr(sha1("${data.aws_caller_identity.current.account_id}-${var.aws_region}"), 0, 10)
  kb_arn                     = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.knowledge_base_id}"
  model_is_inference_profile = length(regexall("^(us|eu|apac|global|au|ca|jp|kr|uk|sa|in)\\.", var.model_id)) > 0
  model_arn                  = local.model_is_inference_profile ? "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:inference-profile/${var.model_id}" : "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}::foundation-model/${var.model_id}"
  cross_region_model_arns = local.model_is_inference_profile && startswith(var.model_id, "apac.") ? [
    "arn:${data.aws_partition.current.partition}:bedrock:ap-south-1::foundation-model/amazon.nova-micro-v1:0",
    "arn:${data.aws_partition.current.partition}:bedrock:ap-southeast-1::foundation-model/amazon.nova-micro-v1:0",
    "arn:${data.aws_partition.current.partition}:bedrock:ap-southeast-2::foundation-model/amazon.nova-micro-v1:0",
    "arn:${data.aws_partition.current.partition}:bedrock:ap-northeast-1::foundation-model/amazon.nova-micro-v1:0",
    "arn:${data.aws_partition.current.partition}:bedrock:ap-northeast-2::foundation-model/amazon.nova-micro-v1:0"
  ] : []
  api_domain = replace(aws_apigatewayv2_api.chat.api_endpoint, "https://", "")

  base_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = var.repository
  }

  default_tags = var.cost_center == null ? local.base_tags : merge(local.base_tags, { CostCenter = var.cost_center })
}
