resource "aws_cloudwatch_log_group" "ingestion" {
  name              = "/aws/lambda/${local.name_prefix}-ingestion"
  retention_in_days = 7
  tags              = local.default_tags
}

resource "aws_sqs_queue" "ingestion_dlq" {
  name                      = "${local.name_prefix}-ingestion-dlq"
  message_retention_seconds = 1209600
  tags                      = local.default_tags
}

resource "aws_sqs_queue" "ingestion" {
  name                       = "${local.name_prefix}-ingestion"
  visibility_timeout_seconds = 120
  message_retention_seconds  = 345600
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ingestion_dlq.arn
    maxReceiveCount     = 5
  })
  tags = local.default_tags
}

data "archive_file" "ingestion_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../src/ingestion_lambda"
  output_path = "${path.module}/.terraform/${local.name_prefix}-ingestion.zip"
  excludes    = ["tests", "__pycache__", ".pytest_cache"]
}

resource "aws_lambda_function" "ingestion" {
  function_name                  = "${local.name_prefix}-ingestion"
  description                    = "Starts Bedrock Knowledge Base ingestion after document bucket changes"
  role                           = aws_iam_role.ingestion_lambda.arn
  handler                        = "handler.lambda_handler"
  runtime                        = var.lambda_runtime
  filename                       = data.archive_file.ingestion_lambda.output_path
  source_code_hash               = data.archive_file.ingestion_lambda.output_base64sha256
  memory_size                    = 128
  timeout                        = 30
  reserved_concurrent_executions = var.reserved_concurrency
  tags                           = local.default_tags

  environment {
    variables = {
      KNOWLEDGE_BASE_ID = aws_bedrockagent_knowledge_base.this.id
      DATA_SOURCE_ID    = aws_bedrockagent_data_source.documents.data_source_id
      DOCUMENT_PREFIX   = "${local.document_prefix}/"
      AWS_RETRY_MODE    = "standard"
      AWS_MAX_ATTEMPTS  = "3"
    }
  }
}

resource "aws_lambda_event_source_mapping" "ingestion" {
  event_source_arn                   = aws_sqs_queue.ingestion.arn
  function_name                      = aws_lambda_function.ingestion.function_name
  batch_size                         = 10
  maximum_batching_window_in_seconds = 30
  function_response_types            = ["ReportBatchItemFailures"]
}

resource "aws_cloudwatch_event_rule" "documents" {
  name        = "${local.name_prefix}-document-events"
  description = "Document object changes for Bedrock KB ingestion"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created", "Object Deleted"]
    detail = {
      bucket = { name = [aws_s3_bucket.source_documents.bucket] }
      object = { key = [{ prefix = "${local.document_prefix}/" }] }
    }
  })
  tags = local.default_tags
}

resource "aws_cloudwatch_event_target" "ingestion_queue" {
  rule      = aws_cloudwatch_event_rule.documents.name
  target_id = "ingestion-queue"
  arn       = aws_sqs_queue.ingestion.arn
}

data "aws_iam_policy_document" "ingestion_queue" {
  statement {
    sid       = "AllowOnlyDocumentEventRule"
    effect    = "Allow"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.ingestion.arn]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.documents.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "ingestion" {
  queue_url = aws_sqs_queue.ingestion.id
  policy    = data.aws_iam_policy_document.ingestion_queue.json
}
