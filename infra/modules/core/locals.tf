locals {
  name_prefix       = "${var.project_name}-${var.environment}"
  account_suffix    = substr(sha1("${data.aws_caller_identity.current.account_id}-${var.aws_region}"), 0, 10)
  source_bucket     = "${local.name_prefix}-docs-${local.account_suffix}"
  ssm_prefix        = "/${var.project_name}/${var.environment}/bedrock"
  model_arn         = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}::foundation-model/${var.embedding_model_id}"
  generation_arn    = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}::foundation-model/${var.generation_model_id}"
  kb_arn            = "arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/${aws_bedrockagent_knowledge_base.this.id}"
  vector_bucket_arn = "arn:${data.aws_partition.current.partition}:s3vectors:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bucket/${aws_s3vectors_vector_bucket.this.vector_bucket_name}"
  vector_index_arn  = "arn:${data.aws_partition.current.partition}:s3vectors:${var.aws_region}:${data.aws_caller_identity.current.account_id}:bucket/${aws_s3vectors_vector_bucket.this.vector_bucket_name}/index/${aws_s3vectors_index.this.index_name}"
  document_files    = fileset("${path.module}/../../../documents", "*.md")
  document_prefix   = trimsuffix(var.document_prefix, "/")

  base_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = var.repository
  }

  default_tags = var.cost_center == null ? local.base_tags : merge(local.base_tags, { CostCenter = var.cost_center })
}
