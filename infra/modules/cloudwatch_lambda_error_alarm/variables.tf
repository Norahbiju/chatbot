variable "alarm_name" { type = string }
variable "function_name" { type = string }
variable "threshold" { type = number }
variable "alarm_actions" {
  type    = list(string)
  default = []
}
variable "tags" {
  type    = map(string)
  default = {}
}
