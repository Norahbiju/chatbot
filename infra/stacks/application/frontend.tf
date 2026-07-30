module "frontend_bucket" {
  source        = "../../modules/secure_s3_bucket"
  bucket_name   = "${local.name_prefix}-frontend-${local.account_suffix}"
  force_destroy = var.force_destroy_buckets
  tags          = local.default_tags
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
  bucket        = module.frontend_bucket.bucket
  key           = each.key
  source        = "${path.root}/../../../frontend/${each.key}"
  etag          = filemd5("${path.root}/../../../frontend/${each.key}")
  content_type  = each.value
  cache_control = each.key == "index.html" ? "no-cache, max-age=0" : "public, max-age=31536000, immutable"
}
