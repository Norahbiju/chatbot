variable "function_name" { type = string }
variable "description" { type = string }
variable "source_dir" { type = string }
variable "excludes" {
  type    = list(string)
  default = ["tests/**", "**/__pycache__/**", "**/.pytest_cache/**"]
}
variable "handler" { type = string }
variable "runtime" { type = string }
variable "role_arn" { type = string }
variable "environment_variables" {
  type    = map(string)
  default = {}
}
variable "memory_size" {
  type    = number
  default = 128
}
variable "timeout" {
  type    = number
  default = 30
}
variable "reserved_concurrent_executions" {
  type    = number
  default = -1
}
variable "log_group_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
