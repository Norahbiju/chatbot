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
  default = "chatbot-aws"
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
