variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "project_name" {
  type    = string
  default = "bedrock-rag"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "repository" {
  type    = string
  default = "chatbot"
}

variable "cost_center" {
  type    = string
  default = null
}

variable "document_prefix" {
  type    = string
  default = "documents/"
}

variable "force_destroy_buckets" {
  type    = bool
  default = true
}

variable "embedding_model_id" {
  type    = string
  default = "amazon.titan-embed-text-v2:0"
}

variable "generation_model_id" {
  type    = string
  default = "apac.amazon.nova-micro-v1:0"
}

variable "embedding_dimensions" {
  type    = number
  default = 256

  validation {
    condition     = contains([256, 512, 1024], var.embedding_dimensions)
    error_message = "Titan Text Embeddings V2 supports 256, 512, and 1024 output dimensions. Changing this requires index replacement and re-ingestion."
  }
}

variable "alert_email" {
  type    = string
  default = null
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "query_lambda_reserved_concurrency" {
  type    = number
  default = null
}

variable "ingestion_lambda_reserved_concurrency" {
  type    = number
  default = null
}

variable "lambda_error_rate_threshold" {
  type    = number
  default = 5
}

variable "read_capacity" {
  type    = number
  default = 5
}

variable "write_capacity" {
  type    = number
  default = 5
}

variable "retrieval_count" {
  type    = number
  default = 4
}

variable "max_generation_tokens" {
  type    = number
  default = 500
}

variable "monthly_budget_limit_usd" {
  type    = string
  default = "5"
}

variable "api_rate_limit" {
  type    = number
  default = 2
}

variable "api_burst_limit" {
  type    = number
  default = 4
}

variable "enable_live_doc_fetch" {
  type    = bool
  default = true
}

variable "live_fetch_min_retrieval_score" {
  type    = number
  default = 0.65
}

variable "live_fetch_max_pages" {
  type    = number
  default = 3
}

variable "live_fetch_timeout_seconds" {
  type    = number
  default = 15
}

variable "live_fetch_max_response_bytes" {
  type    = number
  default = 2000000
}

variable "live_fetch_max_total_bytes" {
  type    = number
  default = 5000000
}

variable "live_fetch_max_redirects" {
  type    = number
  default = 3
}

variable "live_doc_source_registry_json" {
  type      = string
  default   = ""
  sensitive = true
}
