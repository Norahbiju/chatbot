locals {
  initial_document_source_dir = "${path.module}/../../../documents"
  initial_document_files      = fileset(local.initial_document_source_dir, "**/*")
}

resource "aws_s3_object" "initial_documents" {
  for_each = toset(local.initial_document_files)

  bucket      = aws_s3_bucket.source_documents.id
  key         = "${local.document_prefix}/${each.value}"
  source      = "${local.initial_document_source_dir}/${each.value}"
  source_hash = filemd5("${local.initial_document_source_dir}/${each.value}")
  content_type = lookup({
    md   = "text/markdown"
    txt  = "text/plain"
    json = "application/json"
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    pdf  = "application/pdf"
  }, lower(element(reverse(split(".", each.value)), 0)), "application/octet-stream")

  depends_on = [
    aws_s3_bucket_notification.eventbridge,
    aws_cloudwatch_event_target.ingestion_queue,
    aws_sqs_queue_policy.ingestion,
    aws_lambda_event_source_mapping.ingestion
  ]
}
