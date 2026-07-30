resource "aws_cloudwatch_log_group" "query" {
  name              = "/aws/lambda/${local.name_prefix}-query"
  retention_in_days = 7
  tags              = local.default_tags
}

data "archive_file" "query_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/query_lambda"
  output_path = "${path.module}/.terraform/${local.name_prefix}-query.zip"
  excludes    = ["tests", "__pycache__", ".pytest_cache"]
}

resource "aws_lambda_function" "query" {
  function_name                  = "${local.name_prefix}-query"
  description                    = "Handles RAG chat requests"
  role                           = aws_iam_role.query_lambda.arn
  handler                        = "handler.lambda_handler"
  runtime                        = var.lambda_runtime
  filename                       = data.archive_file.query_lambda.output_path
  source_code_hash               = data.archive_file.query_lambda.output_base64sha256
  memory_size                    = 256
  timeout                        = 30
  reserved_concurrent_executions = 2
  tags                           = local.default_tags

  environment {
    variables = {
      CONVERSATION_TABLE_NAME = aws_dynamodb_table.conversation.name
      KNOWLEDGE_BASE_ID       = var.knowledge_base_id
      MODEL_ID                = var.model_id
      RETRIEVAL_COUNT         = tostring(var.retrieval_count)
      MAX_GENERATION_TOKENS   = tostring(var.max_generation_tokens)
      MAX_MESSAGE_LENGTH      = "2000"
      HISTORY_LIMIT           = "8"
      SESSION_TTL_SECONDS     = "86400"
      AWS_RETRY_MODE          = "standard"
      AWS_MAX_ATTEMPTS        = "3"
    }
  }
}
