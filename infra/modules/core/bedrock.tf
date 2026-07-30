resource "aws_bedrockagent_knowledge_base" "this" {
  name     = "${local.name_prefix}-kb"
  role_arn = aws_iam_role.kb.arn
  tags     = local.default_tags

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = local.model_arn
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = var.embedding_dimensions
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration {
      vector_bucket_arn = local.vector_bucket_arn
      index_name        = aws_s3vectors_index.this.index_name
    }
  }
}

resource "aws_bedrockagent_data_source" "documents" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${local.name_prefix}-documents"
  data_deletion_policy = "RETAIN"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn         = aws_s3_bucket.source_documents.arn
      inclusion_prefixes = ["${local.document_prefix}/"]
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 10
      }
    }
  }
}

resource "aws_ssm_parameter" "knowledge_base_id" {
  name  = "${local.ssm_prefix}/knowledge-base-id"
  type  = "String"
  value = aws_bedrockagent_knowledge_base.this.id
}

resource "aws_ssm_parameter" "model_id" {
  name  = "${local.ssm_prefix}/model-id"
  type  = "String"
  value = var.generation_model_id
}

resource "aws_ssm_parameter" "alert_topic_arn" {
  name  = "${local.ssm_prefix}/alert-topic-arn"
  type  = "String"
  value = aws_sns_topic.alerts.arn
}
