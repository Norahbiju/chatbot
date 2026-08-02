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

variable "force_destroy_buckets" {
  type    = bool
  default = true
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "reserved_concurrency" {
  type    = number
  default = null
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

variable "lambda_error_rate_threshold" {
  type    = number
  default = 5
}

variable "api_rate_limit" {
  type    = number
  default = 2
}

variable "api_burst_limit" {
  type    = number
  default = 4
}

variable "knowledge_base_id" {
  type = string
}

variable "model_id" {
  type = string
}

variable "alert_topic_arn" {
  type = string
}

variable "enable_live_doc_fetch" {
  type    = bool
  default = false
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
