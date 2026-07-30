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

resource "aws_cloudwatch_metric_alarm" "ingestion_error_rate" {
  alarm_name          = "${local.name_prefix}-ingestion-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.lambda_error_rate_threshold
  alarm_description   = "Lambda error rate exceeded ${var.lambda_error_rate_threshold}%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  tags                = local.default_tags

  metric_query {
    id          = "e1"
    expression  = "IF(m2>0,100*m1/m2,0)"
    label       = "ErrorRate"
    return_data = true
  }

  metric_query {
    id = "m1"

    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Errors"
      period      = 300
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.ingestion.function_name
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      namespace   = "AWS/Lambda"
      metric_name = "Invocations"
      period      = 300
      stat        = "Sum"
      dimensions = {
        FunctionName = aws_lambda_function.ingestion.function_name
      }
    }
  }
}
