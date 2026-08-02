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
  reserved_concurrent_executions = var.reserved_concurrency
  tags                           = local.default_tags

  environment {
    variables = {
      CONVERSATION_TABLE_NAME            = aws_dynamodb_table.conversation.name
      KNOWLEDGE_BASE_ID                  = var.knowledge_base_id
      MODEL_ID                           = var.model_id
      RETRIEVAL_COUNT                    = tostring(var.retrieval_count)
      MAX_GENERATION_TOKENS              = tostring(var.max_generation_tokens)
      MAX_MESSAGE_LENGTH                 = "2000"
      HISTORY_LIMIT                      = "8"
      SESSION_TTL_SECONDS                = "86400"
      ENABLE_LIVE_DOC_FETCH              = tostring(var.enable_live_doc_fetch)
      LIVE_DOC_SOURCE_REGISTRY_PARAMETER = aws_ssm_parameter.live_doc_sources.name
      LIVE_FETCH_MIN_RETRIEVAL_SCORE     = tostring(var.live_fetch_min_retrieval_score)
      LIVE_FETCH_MAX_PAGES               = tostring(var.live_fetch_max_pages)
      LIVE_FETCH_TIMEOUT_SECONDS         = tostring(var.live_fetch_timeout_seconds)
      LIVE_FETCH_MAX_RESPONSE_BYTES      = tostring(var.live_fetch_max_response_bytes)
      LIVE_FETCH_MAX_TOTAL_BYTES         = tostring(var.live_fetch_max_total_bytes)
      LIVE_FETCH_MAX_REDIRECTS           = tostring(var.live_fetch_max_redirects)
      AWS_RETRY_MODE                     = "standard"
      AWS_MAX_ATTEMPTS                   = "3"
    }
  }
}
