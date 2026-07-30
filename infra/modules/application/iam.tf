data "aws_iam_policy_document" "query_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "query_lambda" {
  name               = "${local.name_prefix}-query-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.query_trust.json
  tags               = local.default_tags
}

data "aws_iam_policy_document" "query_lambda" {
  statement {
    sid       = "RetrieveKnowledgeBase"
    actions   = ["bedrock:Retrieve"]
    resources = [local.kb_arn]
  }
  statement {
    sid       = "InvokeGenerationModel"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.model_arn]
  }
  statement {
    sid = "UseConversationTable"
    actions = [
      "dynamodb:Query",
      "dynamodb:GetItem",
      "dynamodb:PutItem"
    ]
    resources = [aws_dynamodb_table.conversation.arn]
  }
  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.query.arn}:*"]
  }
}

resource "aws_iam_role_policy" "query_lambda" {
  name   = "${local.name_prefix}-query-lambda-policy"
  role   = aws_iam_role.query_lambda.id
  policy = data.aws_iam_policy_document.query_lambda.json
}
