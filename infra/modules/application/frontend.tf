resource "aws_s3_bucket" "frontend" {
  bucket        = "${local.name_prefix}-frontend-${local.account_suffix}"
  force_destroy = var.force_destroy_buckets
  tags          = local.default_tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

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

locals {
  frontend_content_types = {
    "index.html" = "text/html; charset=utf-8"
    "styles.css" = "text/css; charset=utf-8"
    "app.js"     = "application/javascript; charset=utf-8"
  }
}

resource "aws_s3_object" "frontend" {
  for_each      = local.frontend_content_types
  bucket        = aws_s3_bucket.frontend.id
  key           = each.key
  source        = "${path.module}/../../../frontend/${each.key}"
  etag          = filemd5("${path.module}/../../../frontend/${each.key}")
  content_type  = each.value
  cache_control = each.key == "index.html" ? "no-cache, max-age=0" : "public, max-age=31536000, immutable"
}
