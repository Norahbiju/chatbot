# Application Context

## Purpose
Build a minimal Bedrock RAG chatbot that answers from a small Markdown corpus, stores per-session conversation history in DynamoDB with TTL, and serves a safe vanilla frontend through CloudFront.

## Current state
Implemented locally. The query Lambda accepts API Gateway HTTP API payload version 2.0 requests at `POST /api/chat`, retrieves evidence with Bedrock Knowledge Bases `Retrieve`, invokes the configured model through `InvokeModel`, stores user and assistant messages separately, and returns citations. The ingestion Lambda consumes SQS batches from EventBridge S3 events and starts Knowledge Base ingestion when no active job exists. Lambda packages exclude test folders through the Terraform `lambda_function` module; the GitHub Actions pipeline validates Python tests before plan/apply/destroy workflows continue.

API request: `{"sessionId":"uuid","message":"question"}`. Success response: `{"sessionId":"uuid","answer":"text [1]","citations":[{"id":1,"title":"Terraform Basics","source":"documents/terraform-basics.md","excerpt":"...","score":0.82}]}`. Error response: `{"error":{"code":"INVALID_REQUEST","message":"..."}}`.

## Locked decisions
Session TTL is 24 hours. Maximum user message length is 2,000 characters. Recent history is capped at 8 messages. Retrieval result count defaults to 4. Maximum generation tokens defaults to 500. Frontend stores only a browser-generated UUID and calls the relative path `/api/chat`.

## Interfaces and dependencies
Query Lambda environment variables: `CONVERSATION_TABLE_NAME`, `KNOWLEDGE_BASE_ID`, `MODEL_ID`, `RETRIEVAL_COUNT`, `MAX_GENERATION_TOKENS`, `MAX_MESSAGE_LENGTH`, `HISTORY_LIMIT`, `SESSION_TTL_SECONDS`. DynamoDB schema: partition key `session_id`, sort key `message_id`, fields `role`, `content`, `created_at`, `expires_at`. Prompt rules treat retrieved documents as untrusted evidence and require citation markers without fabrication.

## Validation evidence
Unit tests were written for ingestion and query behavior. Local execution was attempted with `python -m compileall` and `python -m unittest`, but Python is not installed/on PATH on this workstation. Frontend uses DOM creation and `textContent`; no model output is inserted with `innerHTML`. `node --check frontend/app.js` was attempted, but Node.js is not installed/on PATH.

## Open issues
Requires AWS deployment validation for Bedrock model access, S3 Vectors regional/account support, Knowledge Base ingestion, and CloudFront/API integration. The local machine currently lacks `python` on PATH.

## Change log
- 2026-07-28: Initialized Lambda handlers, frontend, API contracts, prompt rules, DynamoDB schema, and tests.
- 2026-07-30: Documented pipeline validation impact on application packaging and tests.
