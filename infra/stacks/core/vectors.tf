resource "aws_s3vectors_vector_bucket" "this" {
  vector_bucket_name = "${local.name_prefix}-vectors-${local.account_suffix}"
}

resource "aws_s3vectors_index" "this" {
  vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
  index_name         = "${local.name_prefix}-kb-index"
  dimension          = var.embedding_dimensions
  data_type          = "float32"
  distance_metric    = "cosine"
}
