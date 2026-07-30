resource "aws_cloudwatch_log_group" "query" {
  name              = "/aws/lambda/${local.name_prefix}-query"
  retention_in_days = 7
  tags              = local.default_tags
}

module "query_lambda" {
  source                         = "../../modules/lambda_function"
  function_name                  = "${local.name_prefix}-query"
  description                    = "Handles RAG chat requests"
  source_dir                     = "${path.root}/../../../src/query_lambda"
  handler                        = "handler.lambda_handler"
  runtime                        = var.lambda_runtime
  role_arn                       = aws_iam_role.query_lambda.arn
  memory_size                    = 256
  timeout                        = 30
  reserved_concurrent_executions = 2
  log_group_name                 = aws_cloudwatch_log_group.query.name
  tags                           = local.default_tags
  environment_variables = {
    CONVERSATION_TABLE_NAME = aws_dynamodb_table.conversation.name
    KNOWLEDGE_BASE_ID       = data.aws_ssm_parameter.knowledge_base_id.value
    MODEL_ID                = data.aws_ssm_parameter.model_id.value
    RETRIEVAL_COUNT         = tostring(var.retrieval_count)
    MAX_GENERATION_TOKENS   = tostring(var.max_generation_tokens)
    MAX_MESSAGE_LENGTH      = "2000"
    HISTORY_LIMIT           = "8"
    SESSION_TTL_SECONDS     = "86400"
    AWS_RETRY_MODE          = "standard"
    AWS_MAX_ATTEMPTS        = "3"
  }
}
