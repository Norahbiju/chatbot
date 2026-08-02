# Infrastructure Context

## Purpose
Document the single-root Terraform architecture for a low-cost Amazon Bedrock RAG chatbot using S3 documents, Bedrock Knowledge Bases, S3 Vectors, DynamoDB, HTTP API, CloudFront, SNS alarms, and AWS Budgets.

## Current state
Implemented locally as one Terraform root at `infra/`. The root calls two internal modules:

- `infra/modules/core` for the source document bucket, S3 Vectors, Bedrock KB/data source, automatic ingestion path, SNS, and SSM parameters
- `infra/modules/application` for DynamoDB, query Lambda, HTTP API, frontend S3 bucket, CloudFront, alarms, and budget

The root reads the SSM parameters created by the core module during deployment and passes those resolved values into the application module so the full system can be planned and applied together in one state.

## Locked decisions
Region `ap-south-1`; prefix `project_name-environment`; default tags `Project`, `Environment`, `ManagedBy`, `Repository`, optional `CostCenter`; backend is the shared S3 state bucket `chatbot-aws-tf-state-484632959006` with key `bedrock-rag/dev/terraform.tfstate`; no Terraform workspaces.

SSM names:

- `/bedrock-rag/dev/bedrock/knowledge-base-id`
- `/bedrock-rag/dev/bedrock/model-id`
- `/bedrock-rag/dev/bedrock/alert-topic-arn`

## Interfaces and dependencies
One Terraform apply now creates the infrastructure system. Internally, the core module publishes the knowledge base ID, model ID, and SNS topic ARN to SSM Parameter Store; the root reads those SSM parameters and passes the resolved values into the application module. The core module also uploads the initial contents of `documents/` to the source bucket as Terraform-managed S3 objects after the automatic ingestion path exists. The `Sync Documents` GitHub Actions workflow remains an optional later upload/delete path, and S3 object changes trigger Bedrock ingestion through EventBridge, SQS, and the ingestion Lambda.

The application module owns an SSM SecureString source registry for optional live documentation fetching. The query Lambda receives the registry parameter name and live-fetch limits through environment variables, but live fetch is disabled by default. No VPC, NAT Gateway, scheduled crawler, external search provider, cache table, or live-page ingestion resources are added for the approved URL-fetch and citation-only implementation.

S3 buckets use private access, versioning, SSE-S3, TLS-only policies, lifecycle rules, and `force_destroy = true` by default for this dev-oriented setup. Lambda packaging, bucket hardening, alarms, and IAM are implemented directly inside the child modules instead of through extra helper modules.

The S3 Vectors index is configured with Bedrock metadata fields `AMAZON_BEDROCK_METADATA` and `AMAZON_BEDROCK_TEXT` as non-filterable metadata keys so Bedrock ingestion does not exceed the 2 KB filterable metadata limit enforced by S3 Vectors.

The application module now treats Bedrock generation model IDs with geography prefixes such as `apac.` as inference profiles instead of foundation models. For the current deployment, the generator default is `apac.amazon.nova-micro-v1:0`, and IAM explicitly allows both the source-region inference-profile ARN and the APAC destination foundation-model ARNs needed for geographic cross-Region inference.

Pipeline backend generation uses temporary HCL files under `RUNNER_TEMP` that should match the tracked S3 backend configuration. The pipeline state key is `<TF_STATE_KEY>`. Apply is constrained to exact saved plan artifacts from default-branch manual plans. Destroy is constrained to exact saved destroy plans and checks for active Knowledge Base ingestion before proceeding.

## Validation evidence
Official documentation reviewed: HashiCorp documents S3 backend `use_lockfile` and S3 Vectors resources; AWS documents S3 Vectors with Bedrock Knowledge Bases and Titan Text Embeddings V2. `terraform fmt -check -recursive` passed. `terraform -chdir=infra init -backend=false` and `terraform -chdir=infra validate` passed. `python scripts/validate_iam.py`, `python scripts/check_cost_guardrails.py`, `python -m compileall src scripts`, `python -m unittest discover -s src/query_lambda/tests`, and `python -m unittest discover -s scripts/tests` all passed on 2026-07-30 using a local virtual environment with `boto3` and `botocore` installed for the test run. GitHub Actions repair run `30581281039`, manual plan run `30581357958`, and exact apply run `30581480625` all succeeded on 2026-07-30. A live probe returned HTTP `200` from the CloudFront frontend and a grounded Kubernetes answer with citations from the deployed `POST /api/chat` path.

## Open issues
Changing the S3 Vectors index metadata configuration is a vector-index replacement concern and requires a fresh ingestion after deployment. The exact S3 Vectors ARN format is still derived because the provider resources do not export ARN attributes directly; AWS deployment validation should confirm IAM resource matching. On July 30, 2026, a live destroy run failed because Bedrock returned `DELETE_UNSUCCESSFUL` while trying to remove data-source embeddings from the vector store. The Terraform data source is now set to `data_deletion_policy = "RETAIN"` so destroy no longer depends on Bedrock deleting vector-store records during data-source teardown.

## Change log
- 2026-07-28: Created the original Terraform architecture, cost controls, and deployment documentation.
- 2026-07-30: Simplified the previous multi-root layout into one Terraform root with `core` and `application` child modules, preserved SSM handoff behavior, and updated validation evidence.
- 2026-07-30: Added S3 Vectors non-filterable Bedrock metadata keys so Bedrock ingestion can succeed within S3 Vectors metadata limits.
- 2026-07-30: Simplified the single-root dependency flow by replacing same-apply SSM reads with direct module-output wiring from `core` to `application`.
- 2026-07-30: Switched the default generation model to an APAC inference-profile ID and updated application IAM/resource handling so Bedrock generation can work from `ap-south-1`.
- 2026-07-30: Updated the Bedrock data source to `data_deletion_policy = "RETAIN"` after a real destroy run failed while Bedrock tried to delete vector-store data during data-source removal.
- 2026-07-30: Corrected the live Bedrock data source deletion policy, reran the exact-plan pipeline, verified the deployed frontend and chat API successfully, and then removed the temporary recovery workflow.
- 2026-08-01: Removed Terraform-managed source document objects and moved document uploads to the `Sync Documents` workflow.
- 2026-08-02: Restored automatic S3 document ingestion through EventBridge, SQS, and an ingestion Lambda, while keeping `Sync Documents` upload-only. The root now reads core-published SSM parameters at deploy time before wiring the application module.
- 2026-08-02: Added Terraform-managed initial document uploads from `documents/` so the first apply seeds the source bucket; the sync workflow remains available as an optional content update path.
- 2026-08-02: Added the optional live documentation source registry and query Lambda feature flags without scheduled crawling, caching, or live-page ingestion.
