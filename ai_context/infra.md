# Infrastructure Context

## Purpose
Document the two-stack Terraform architecture for a low-cost Amazon Bedrock RAG chatbot using S3 documents, Bedrock Knowledge Bases, S3 Vectors, DynamoDB, HTTP API, CloudFront, SNS alarms, and AWS Budgets.

## Current state
Implemented locally as two independent Terraform roots: `infra/stacks/core` and `infra/stacks/application`. The core stack owns source documents, S3 Vectors, Bedrock KB/data source, ingestion queue/Lambda, SNS, alarms, and SSM parameters. The application stack reads SSM parameters at plan time and owns DynamoDB, query Lambda, HTTP API, frontend S3 bucket, CloudFront, alarms, and budget.

## Locked decisions
Region `ap-south-1`; prefix `project_name-environment`; default tags `Project`, `Environment`, `ManagedBy`, `Repository`, optional `CostCenter`; backend is partial `backend "s3" {}` with separate keys `bedrock-rag/dev/core/terraform.tfstate` and `bedrock-rag/dev/application/terraform.tfstate`; no Terraform workspaces.

SSM names: `/bedrock-rag/dev/bedrock/knowledge-base-id`, `/bedrock-rag/dev/bedrock/model-id`, `/bedrock-rag/dev/bedrock/alert-topic-arn`.

## Interfaces and dependencies
Deployment order: core before application. Destroy order: application before core. Application planning depends on SSM parameters produced by core. Source documents depend on the ingestion event path so initial uploads are not missed. S3 buckets use private access, versioning, SSE-S3, TLS-only policies, lifecycle rules, and `force_destroy = true` by default for dev.

Pipeline backend generation uses temporary HCL files under `RUNNER_TEMP`; tracked backend files remain partial `backend "s3" {}`. Pipeline state keys are `<TF_STATE_PREFIX>/dev/core/terraform.tfstate` and `<TF_STATE_PREFIX>/dev/application/terraform.tfstate`. Apply is constrained to exact saved plan artifacts from default-branch manual plans. Destroy is constrained to exact saved destroy plans and blocks core destroy while application state still has resources.

## Validation evidence
Official documentation reviewed: HashiCorp documents S3 backend `use_lockfile` and S3 Vectors resources; AWS documents S3 Vectors with Bedrock Knowledge Bases and Titan Text Embeddings V2. `terraform init -backend=false` succeeded for both stacks and created `.terraform.lock.hcl` files with `hashicorp/aws v6.56.0` and `hashicorp/archive v2.8.0`. `terraform fmt -check -recursive`, `terraform -chdir=infra/stacks/core validate`, and `terraform -chdir=infra/stacks/application validate` passed. Provider schema dump was attempted but remained unavailable because the partial S3 backend caused Terraform to require backend initialization for that subcommand; provider-backed `validate` was used as substitute validation.

## Open issues
Model and service availability must be confirmed in the target AWS account. No deployment or AWS-backed plan was run. The exact S3 Vectors ARN format is derived because the provider resources do not export `arn` attributes; AWS deployment validation should confirm IAM resource matching.

## Change log
- 2026-07-28: Created Terraform modules, root stacks, environment examples, SSM dependency model, cost controls, and deployment documentation.
- 2026-07-30: Added pipeline state-key conventions, temporary backend generation, exact-plan constraints, destroy-order enforcement, and renamed the application budget variable to `monthly_budget_limit_usd` to match `TF_VAR_monthly_budget_limit_usd`.
