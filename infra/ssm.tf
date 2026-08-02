data "aws_ssm_parameter" "knowledge_base_id" {
  name       = module.core.ssm_parameter_names.knowledge_base_id
  depends_on = [module.core]
}

data "aws_ssm_parameter" "model_id" {
  name       = module.core.ssm_parameter_names.model_id
  depends_on = [module.core]
}

data "aws_ssm_parameter" "alert_topic_arn" {
  name       = module.core.ssm_parameter_names.alert_topic_arn
  depends_on = [module.core]
}
