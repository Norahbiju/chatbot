module "query_error_alarm" {
  source        = "../../modules/cloudwatch_lambda_error_alarm"
  alarm_name    = "${local.name_prefix}-query-error-rate"
  function_name = module.query_lambda.function_name
  threshold     = var.lambda_error_rate_threshold
  alarm_actions = [data.aws_ssm_parameter.alert_topic_arn.value]
  tags          = local.default_tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_rate" {
  alarm_name          = "${local.name_prefix}-api-5xx-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5
  treat_missing_data  = "notBreaching"
  alarm_actions       = [data.aws_ssm_parameter.alert_topic_arn.value]
  tags                = local.default_tags

  metric_query {
    id          = "e1"
    expression  = "IF(m2>0,100*m1/m2,0)"
    label       = "5xxRate"
    return_data = true
  }
  metric_query {
    id = "m1"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "5xx"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiId = aws_apigatewayv2_api.chat.id
        Stage = aws_apigatewayv2_stage.default.name
      }
    }
  }
  metric_query {
    id = "m2"
    metric {
      namespace   = "AWS/ApiGateway"
      metric_name = "Count"
      period      = 300
      stat        = "Sum"
      dimensions = {
        ApiId = aws_apigatewayv2_api.chat.id
        Stage = aws_apigatewayv2_stage.default.name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "dynamodb_throttled" {
  alarm_name          = "${local.name_prefix}-dynamodb-throttled"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRequests"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"
  alarm_actions       = [data.aws_ssm_parameter.alert_topic_arn.value]
  dimensions = {
    TableName = aws_dynamodb_table.conversation.name
  }
  tags = local.default_tags
}
