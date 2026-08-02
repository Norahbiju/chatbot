module "core" {
  source = "./modules/core"

  aws_region            = var.aws_region
  project_name          = var.project_name
  environment           = var.environment
  repository            = var.repository
  cost_center           = var.cost_center
  document_prefix       = var.document_prefix
  force_destroy_buckets = var.force_destroy_buckets
  embedding_model_id    = var.embedding_model_id
  generation_model_id   = var.generation_model_id
  embedding_dimensions  = var.embedding_dimensions
  alert_email           = var.alert_email
  lambda_runtime        = var.lambda_runtime

  ingestion_lambda_reserved_concurrency = var.ingestion_lambda_reserved_concurrency
  lambda_error_rate_threshold           = var.lambda_error_rate_threshold
}

module "application" {
  source = "./modules/application"

  aws_region                     = var.aws_region
  project_name                   = var.project_name
  environment                    = var.environment
  repository                     = var.repository
  cost_center                    = var.cost_center
  force_destroy_buckets          = var.force_destroy_buckets
  lambda_runtime                 = var.lambda_runtime
  reserved_concurrency           = var.query_lambda_reserved_concurrency
  read_capacity                  = var.read_capacity
  write_capacity                 = var.write_capacity
  retrieval_count                = var.retrieval_count
  max_generation_tokens          = var.max_generation_tokens
  monthly_budget_limit_usd       = var.monthly_budget_limit_usd
  lambda_error_rate_threshold    = var.lambda_error_rate_threshold
  api_rate_limit                 = var.api_rate_limit
  api_burst_limit                = var.api_burst_limit
  knowledge_base_id              = data.aws_ssm_parameter.knowledge_base_id.value
  model_id                       = data.aws_ssm_parameter.model_id.value
  alert_topic_arn                = data.aws_ssm_parameter.alert_topic_arn.value
  enable_live_doc_fetch          = var.enable_live_doc_fetch
  live_fetch_min_retrieval_score = var.live_fetch_min_retrieval_score
  live_fetch_max_pages           = var.live_fetch_max_pages
  live_fetch_timeout_seconds     = var.live_fetch_timeout_seconds
  live_fetch_max_response_bytes  = var.live_fetch_max_response_bytes
  live_fetch_max_total_bytes     = var.live_fetch_max_total_bytes
  live_fetch_max_redirects       = var.live_fetch_max_redirects
  live_doc_source_registry_json  = var.live_doc_source_registry_json
}
