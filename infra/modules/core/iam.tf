data "aws_iam_policy_document" "kb_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:bedrock:${var.aws_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"]
    }
  }
}

resource "aws_iam_role" "kb" {
  name               = "${local.name_prefix}-kb-role"
  assume_role_policy = data.aws_iam_policy_document.kb_trust.json
  tags               = local.default_tags
}

data "aws_iam_policy_document" "kb" {
  statement {
    sid       = "ReadSourceDocuments"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.source_documents.arn, "${aws_s3_bucket.source_documents.arn}/${local.document_prefix}/*"]
  }
  statement {
    sid       = "InvokeEmbeddingModel"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.model_arn]
  }
  statement {
    sid = "UseS3VectorsIndex"
    actions = [
      "s3vectors:GetVectorBucket",
      "s3vectors:GetIndex",
      "s3vectors:ListIndexes",
      "s3vectors:PutVectors",
      "s3vectors:GetVectors",
      "s3vectors:DeleteVectors",
      "s3vectors:QueryVectors"
    ]
    resources = [
      local.vector_bucket_arn,
      local.vector_index_arn
    ]
  }
}

resource "aws_iam_role_policy" "kb" {
  name   = "${local.name_prefix}-kb-policy"
  role   = aws_iam_role.kb.id
  policy = data.aws_iam_policy_document.kb.json
}

data "aws_iam_policy_document" "ingestion_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ingestion_lambda" {
  name               = "${local.name_prefix}-ingestion-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.ingestion_trust.json
  tags               = local.default_tags
}

data "aws_iam_policy_document" "ingestion_lambda" {
  statement {
    sid = "ConsumeIngestionQueue"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [aws_sqs_queue.ingestion.arn]
  }
  statement {
    sid = "WriteLogs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.ingestion.arn}:*"]
  }
  statement {
    sid = "ManageKnowledgeBaseIngestion"
    actions = [
      "bedrock:StartIngestionJob",
      "bedrock:ListIngestionJobs"
    ]
    resources = [local.kb_arn]
  }
}

resource "aws_iam_role_policy" "ingestion_lambda" {
  name   = "${local.name_prefix}-ingestion-lambda-policy"
  role   = aws_iam_role.ingestion_lambda.id
  policy = data.aws_iam_policy_document.ingestion_lambda.json
}

