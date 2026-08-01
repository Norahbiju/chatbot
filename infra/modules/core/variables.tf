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

variable "reserved_concurrency" {
  type    = number
  default = null
}

variable "lambda_error_rate_threshold" {
  type    = number
  default = 5
}
