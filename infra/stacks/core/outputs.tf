output "source_document_bucket_name" {
  value = module.source_documents.bucket
}

output "vector_bucket_arn" {
  value = local.vector_bucket_arn
}

output "vector_index_arn" {
  value = local.vector_index_arn
}

output "knowledge_base_id" {
  value = aws_bedrockagent_knowledge_base.this.id
}

output "knowledge_base_arn" {
  value = local.kb_arn
}

output "data_source_id" {
  value = aws_bedrockagent_data_source.documents.data_source_id
}

output "ingestion_queue_url" {
  value = aws_sqs_queue.ingestion.url
}

output "ingestion_dlq_url" {
  value = aws_sqs_queue.ingestion_dlq.url
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "ssm_parameter_names" {
  value = {
    knowledge_base_id = aws_ssm_parameter.knowledge_base_id.name
    model_id          = aws_ssm_parameter.model_id.name
    alert_topic_arn   = aws_ssm_parameter.alert_topic_arn.name
  }
}
