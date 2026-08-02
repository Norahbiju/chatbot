# Application Context

## Purpose
Build a minimal Bedrock RAG chatbot that answers from a curated Markdown corpus, stores per-session conversation history in DynamoDB with TTL, and serves a safe vanilla frontend through CloudFront.

## Current state
Implemented locally. The query Lambda accepts API Gateway HTTP API payload version 2.0 requests at `POST /api/chat`, retrieves evidence with Bedrock Knowledge Bases `Retrieve`, invokes the configured model through `InvokeModel`, stores user and assistant messages separately, and returns citations. Knowledge Base documents are initially uploaded by Terraform from `documents/`; the `Sync Documents` GitHub Actions workflow remains an optional later update path. Ingestion is triggered automatically from S3 object changes through EventBridge, SQS, and the ingestion Lambda.

The query Lambda also has an optional live documentation fallback for allowlisted official documentation sources. The feature is disabled by default. When enabled, the Lambda retrieves from the Knowledge Base first, evaluates deterministic sufficiency rules, searches the administrator-controlled source registry catalogue, validates candidate URLs, fetches a small number of HTTPS pages, extracts clean text, and returns backend-validated citations with real documentation URLs. There is no scheduled crawling, no external search provider, no live-page cache, and no automatic ingestion of fetched pages.

The Terraform root packages the query Lambda through an `archive_file` data source inside `infra/modules/application`. The knowledge-base corpus now goes beyond the original three overview notes and includes additional curated documents on GitHub Actions workflow syntax, contexts and runners, Kubernetes networking and policy, Kubernetes stateful/storage/security behavior, Terraform language and CLI behavior, and Terraform AWS provider serverless patterns.

API request: `{"sessionId":"uuid","message":"question"}`.

Success response: `{"sessionId":"uuid","answer":"text [1]","citations":[{"id":1,"title":"Terraform State, Backends, and Module Design","source":"documents/terraform-basics.md","url":null,"source_type":"KNOWLEDGE_BASE","excerpt":"...","score":0.82}],"live_fetch_used":false,"live_fetch_reason":null}`.

Error response: `{"error":{"code":"INVALID_REQUEST","message":"..."}}`.

## Locked decisions
Session TTL is 24 hours. Maximum user message length is 2,000 characters. Recent history is capped at 8 messages. Retrieval result count defaults to 4. Maximum generation tokens defaults to 500. Frontend stores only a browser-generated UUID and calls the relative path `/api/chat`.

## Interfaces and dependencies
Query Lambda environment variables: `CONVERSATION_TABLE_NAME`, `KNOWLEDGE_BASE_ID`, `MODEL_ID`, `RETRIEVAL_COUNT`, `MAX_GENERATION_TOKENS`, `MAX_MESSAGE_LENGTH`, `HISTORY_LIMIT`, `SESSION_TTL_SECONDS`.

DynamoDB schema: partition key `session_id`, sort key `message_id`, fields `role`, `content`, `created_at`, `expires_at`.

Prompt rules treat retrieved documents as untrusted evidence and require citation markers without fabrication. The corpus is based on official documentation themes for Terraform, Kubernetes, and GitHub Actions, but the repository text itself remains original, curated, and shortened for cost-conscious retrieval.

## Validation evidence
`python -m compileall src scripts` passed. `python -m unittest discover -s src/query_lambda/tests` and `python -m unittest discover -s scripts/tests` passed on 2026-07-30 using a local virtual environment with `boto3` and `botocore` installed for the run. Frontend uses DOM creation and `textContent`; no model output is inserted with `innerHTML`. After the July 30, 2026 repair and exact apply, a live API probe returned a Kubernetes answer with four citations from the deployed knowledge base.

## Open issues
Requires AWS deployment validation for the final Bedrock generation-model switch, CloudFront/API integration retest, and any cross-Region inference IAM nuances in the target account. On July 30, 2026, live diagnostics showed that empty chatbot answers were caused first by a historical ingestion client-token issue and then by S3 Vectors filterable metadata limits in the vector index. A later live retrieve probe confirmed the knowledge base was returning Kubernetes results correctly, after which the remaining failure narrowed to `InvokeModel` access for `amazon.nova-micro-v1:0` from `ap-south-1`. The application has now been updated to use an APAC Bedrock inference-profile ID instead of unsupported direct on-demand invocation in Mumbai. Local JavaScript syntax validation still depends on Node.js being available on the machine that runs validation.

## Change log
- 2026-07-28: Initialized Lambda handlers, frontend, API contracts, prompt rules, DynamoDB schema, and tests.
- 2026-07-30: Refactored Terraform packaging into a single root with internal modules and upgraded the sample knowledge-base corpus to more intermediate-level summaries.
- 2026-07-30: Fixed the historical automatic ingestion client token so knowledge-base sync requests satisfy the Bedrock API requirements.
- 2026-07-30: Confirmed live retrieval failures were due to an empty knowledge base, diagnosed the S3 Vectors metadata-limit failure during manual sync, and updated the vector index design to mark Bedrock metadata fields as non-filterable.
- 2026-07-30: Switched the query path from direct `amazon.nova-micro-v1:0` invocation to an APAC inference-profile model ID because live diagnostics showed on-demand invocation was not supported from `ap-south-1`.
- 2026-07-30: Expanded the curated knowledge-base corpus with additional intermediate GitHub Actions, Kubernetes, and Terraform notes derived from official documentation themes.
- 2026-07-30: Verified the deployed chat path end to end after the Bedrock data-source repair; CloudFront served the frontend and the API returned grounded Kubernetes citations.
- 2026-08-01: Moved Knowledge Base document uploads out of Terraform and into the `Sync Documents` GitHub Actions workflow.
- 2026-08-02: Restored automatic ingestion from S3 document changes through EventBridge, SQS, and the ingestion Lambda.
- 2026-08-02: Added Terraform-managed initial document upload while keeping `Sync Documents` as an optional later update path.
- 2026-08-02: Added an optional allowlisted live documentation fallback and trusted citation validation; optional cache and live-page ingestion remain excluded.
