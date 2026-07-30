module "source_documents" {
  source        = "../../modules/secure_s3_bucket"
  bucket_name   = local.source_bucket
  force_destroy = var.force_destroy_buckets
  tags          = local.default_tags
}

resource "aws_s3_bucket_notification" "eventbridge" {
  bucket      = module.source_documents.bucket
  eventbridge = true
}

resource "aws_s3_object" "documents" {
  for_each     = local.document_files
  bucket       = module.source_documents.bucket
  key          = "${local.document_prefix}/${each.value}"
  source       = "${path.root}/../../../documents/${each.value}"
  etag         = filemd5("${path.root}/../../../documents/${each.value}")
  content_type = "text/markdown; charset=utf-8"

  depends_on = [
    aws_lambda_event_source_mapping.ingestion,
    aws_cloudwatch_event_target.ingestion_queue
  ]
}
