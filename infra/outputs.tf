output "source_document_bucket_name" {
  value = module.core.source_document_bucket_name
}

output "document_prefix" {
  value = module.core.document_prefix
}

output "managed_document_object_count" {
  value = module.core.managed_document_object_count
}

output "vector_bucket_arn" {
  value = module.core.vector_bucket_arn
}

output "vector_index_arn" {
  value = module.core.vector_index_arn
}

output "knowledge_base_id" {
  value = module.core.knowledge_base_id
}

output "knowledge_base_arn" {
  value = module.core.knowledge_base_arn
}

output "data_source_id" {
  value = module.core.data_source_id
}

output "sns_topic_arn" {
  value = module.core.sns_topic_arn
}

output "ingestion_queue_url" {
  value = module.core.ingestion_queue_url
}

output "ingestion_dlq_url" {
  value = module.core.ingestion_dlq_url
}

output "ingestion_lambda_name" {
  value = module.core.ingestion_lambda_name
}

output "ssm_parameter_names" {
  value = module.core.ssm_parameter_names
}

output "api_gateway_invoke_url" {
  value = module.application.api_gateway_invoke_url
}

output "cloudfront_domain_name" {
  value = module.application.cloudfront_domain_name
}

output "cloudfront_distribution_id" {
  value = module.application.cloudfront_distribution_id
}

output "frontend_bucket_name" {
  value = module.application.frontend_bucket_name
}

output "dynamodb_table_name" {
  value = module.application.dynamodb_table_name
}

output "query_lambda_name" {
  value = module.application.query_lambda_name
}

output "api_id" {
  value = module.application.api_id
}

output "budget_name" {
  value = module.application.budget_name
}

output "live_doc_source_registry_parameter_name" {
  value = module.application.live_doc_source_registry_parameter_name
}
