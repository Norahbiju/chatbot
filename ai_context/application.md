# Application Context

## Purpose
Build a minimal Bedrock RAG chatbot that answers from a curated Markdown corpus, stores per-session conversation history in DynamoDB with TTL, and serves a safe vanilla frontend through CloudFront.

## Current state
Implemented locally. The query Lambda accepts API Gateway HTTP API payload version 2.0 requests at `POST /api/chat`, retrieves evidence with Bedrock Knowledge Bases `Retrieve`, invokes the configured model through `InvokeModel`, stores user and assistant messages separately, and returns citations. The ingestion Lambda consumes SQS batches from EventBridge S3 events and starts Knowledge Base ingestion when no active job exists.

The Terraform root now packages both Lambdas through `archive_file` data sources inside `infra/modules/core` and `infra/modules/application`.

On 2026-07-30, the ingestion Lambda was corrected to use a full SHA-256 hex digest as the Bedrock ingestion `clientToken`, which keeps the token within the Bedrock API length requirements.

API request: `{"sessionId":"uuid","message":"question"}`.

Success response: `{"sessionId":"uuid","answer":"text [1]","citations":[{"id":1,"title":"Terraform State, Backends, and Module Design","source":"documents/terraform-basics.md","excerpt":"...","score":0.82}]}`.

Error response: `{"error":{"code":"INVALID_REQUEST","message":"..."}}`.

## Locked decisions
Session TTL is 24 hours. Maximum user message length is 2,000 characters. Recent history is capped at 8 messages. Retrieval result count defaults to 4. Maximum generation tokens defaults to 500. Frontend stores only a browser-generated UUID and calls the relative path `/api/chat`.

## Interfaces and dependencies
Query Lambda environment variables: `CONVERSATION_TABLE_NAME`, `KNOWLEDGE_BASE_ID`, `MODEL_ID`, `RETRIEVAL_COUNT`, `MAX_GENERATION_TOKENS`, `MAX_MESSAGE_LENGTH`, `HISTORY_LIMIT`, `SESSION_TTL_SECONDS`.

DynamoDB schema: partition key `session_id`, sort key `message_id`, fields `role`, `content`, `created_at`, `expires_at`.

Prompt rules treat retrieved documents as untrusted evidence and require citation markers without fabrication. The new sample corpus is more intermediate-level and is based on official documentation themes for Terraform, Kubernetes, and GitHub Actions, but the repository text itself is original and shortened for cost-conscious retrieval.

## Validation evidence
`python -m compileall src scripts` passed. `python -m unittest discover -s src/ingestion_lambda/tests`, `python -m unittest discover -s src/query_lambda/tests`, and `python -m unittest discover -s scripts/tests` passed on 2026-07-30 using a local virtual environment with `boto3` and `botocore` installed for the run. Frontend uses DOM creation and `textContent`; no model output is inserted with `innerHTML`.

## Open issues
Requires AWS deployment validation for the final Bedrock generation-model switch, CloudFront/API integration retest, and any cross-Region inference IAM nuances in the target account. On July 30, 2026, live diagnostics showed that empty chatbot answers were caused first by a historical ingestion Lambda `clientToken` length bug and then by S3 Vectors filterable metadata limits in the vector index. A later live retrieve probe confirmed the knowledge base was returning Kubernetes results correctly, after which the remaining failure narrowed to `InvokeModel` access for `amazon.nova-micro-v1:0` from `ap-south-1`. The application has now been updated to use an APAC Bedrock inference-profile ID instead of unsupported direct on-demand invocation in Mumbai. Local JavaScript syntax validation still depends on Node.js being available on the machine that runs validation.

## Change log
- 2026-07-28: Initialized Lambda handlers, frontend, API contracts, prompt rules, DynamoDB schema, and tests.
- 2026-07-30: Refactored Terraform packaging into a single root with internal modules and upgraded the sample knowledge-base corpus to more intermediate-level summaries.
- 2026-07-30: Fixed the ingestion Lambda Bedrock `clientToken` length so automatic knowledge-base sync requests satisfy the Bedrock API requirements.
- 2026-07-30: Confirmed live retrieval failures were due to an empty knowledge base, diagnosed the S3 Vectors metadata-limit failure during manual sync, and updated the vector index design to mark Bedrock metadata fields as non-filterable.
- 2026-07-30: Switched the query path from direct `amazon.nova-micro-v1:0` invocation to an APAC inference-profile model ID because live diagnostics showed on-demand invocation was not supported from `ap-south-1`.
