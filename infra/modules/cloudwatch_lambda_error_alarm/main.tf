resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = var.threshold
  alarm_description   = "Lambda error rate exceeded ${var.threshold}%"
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  tags                = var.tags

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
        FunctionName = var.function_name
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
        FunctionName = var.function_name
      }
    }
  }
}
