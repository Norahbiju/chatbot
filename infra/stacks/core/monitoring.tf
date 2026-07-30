resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"
  tags = local.default_tags
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

module "ingestion_error_alarm" {
  source        = "../../modules/cloudwatch_lambda_error_alarm"
  alarm_name    = "${local.name_prefix}-ingestion-error-rate"
  function_name = module.ingestion_lambda.function_name
  threshold     = var.lambda_error_rate_threshold
  alarm_actions = [aws_sns_topic.alerts.arn]
  tags          = local.default_tags
}
