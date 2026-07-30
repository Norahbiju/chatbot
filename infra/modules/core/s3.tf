resource "aws_s3_bucket" "source_documents" {
  bucket        = local.source_bucket
  force_destroy = var.force_destroy_buckets
  tags          = local.default_tags
}

resource "aws_s3_bucket_public_access_block" "source_documents" {
  bucket                  = aws_s3_bucket.source_documents.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "source_documents" {
  bucket = aws_s3_bucket.source_documents.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "source_documents" {
  bucket = aws_s3_bucket.source_documents.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source_documents" {
  bucket = aws_s3_bucket.source_documents.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "source_documents" {
  bucket = aws_s3_bucket.source_documents.id

  rule {
    id     = "low-cost-retention"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

data "aws_iam_policy_document" "source_documents_tls_only" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.source_documents.arn,
      "${aws_s3_bucket.source_documents.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "source_documents" {
  bucket = aws_s3_bucket.source_documents.id
  policy = data.aws_iam_policy_document.source_documents_tls_only.json
}

resource "aws_s3_bucket_notification" "eventbridge" {
  bucket      = aws_s3_bucket.source_documents.id
  eventbridge = true
}

resource "aws_s3_object" "documents" {
  for_each     = local.document_files
  bucket       = aws_s3_bucket.source_documents.id
  key          = "${local.document_prefix}/${each.value}"
  source       = "${path.module}/../../../documents/${each.value}"
  etag         = filemd5("${path.module}/../../../documents/${each.value}")
  content_type = "text/markdown; charset=utf-8"

  depends_on = [
    aws_lambda_event_source_mapping.ingestion,
    aws_cloudwatch_event_target.ingestion_queue
  ]
}
