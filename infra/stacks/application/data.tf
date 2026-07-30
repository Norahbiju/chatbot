data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

data "aws_ssm_parameter" "knowledge_base_id" {
  name = "${local.ssm_prefix}/knowledge-base-id"
}

data "aws_ssm_parameter" "model_id" {
  name = "${local.ssm_prefix}/model-id"
}

data "aws_ssm_parameter" "alert_topic_arn" {
  name = "${local.ssm_prefix}/alert-topic-arn"
}
