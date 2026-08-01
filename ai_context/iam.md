# IAM Context

## Purpose
Document IAM roles, trust policies, permission scopes, wildcard audits, and service-role considerations for the Bedrock RAG chatbot.

## Current state
Implemented locally in Terraform module files:

- `infra/modules/core/iam.tf`
- `infra/modules/application/iam.tf`

Roles

- Bedrock Knowledge Base service role
- query Lambda role

Service integrations use resource policies or native service permissions for API Gateway, CloudFront OAC, SNS, and Budgets.

## Locked decisions
Lambda roles do not include `Resource = "*"`, broad actions such as `bedrock:*`, `s3:*`, `dynamodb:*`, `sqs:*`, `logs:*`, or permissions outside their workflows. Lambda log groups are pre-created so the runtime roles do not need `logs:CreateLogGroup`.

## Interfaces and dependencies
Knowledge Base role trust principal: `bedrock.amazonaws.com`, restricted by source account and `knowledge-base/*` source ARN pattern because the exact KB ARN is not available until creation. Permissions: S3 read/list on the exact source bucket and prefix, `bedrock:InvokeModel` on the Titan embedding model ARN, and S3 Vectors actions on the exact vector bucket/index ARNs.

Query Lambda trust principal: `lambda.amazonaws.com`. Permissions: `bedrock:Retrieve` on the exact KB ARN, `bedrock:InvokeModel` on the exact generation model ARN, DynamoDB `Query`, `GetItem`, and `PutItem` on the exact table ARN, and CloudWatch Logs stream/write on exact log group streams.

GitHub OIDC deployment role is not modified by this repository. The required OIDC provider is `token.actions.githubusercontent.com` with audience `sts.amazonaws.com`. The trust policy should evaluate the repository subject claim so only the intended repository and branch can assume the role.

## Validation evidence
`scripts/validate_iam.py` statically checks Lambda policy documents in `infra/modules/application/iam.tf` for wildcard resources and broad actions. The script passed locally on 2026-07-30. The only broad S3 action remains the non-Lambda TLS-deny bucket-policy statement.

## Open issues
Some AWS APIs may not support resource-level permissions exactly as modeled; AWS deployment validation is still required. If Bedrock model invocation later requires inference profile ARNs, the exact ARNs and data-residency implications must be documented before widening permissions.

## Change log
- 2026-07-28: Created the IAM matrix, scoped Lambda policies, KB service-role notes, and static audit script.
- 2026-07-30: Updated the context for the single-root Terraform layout and module-based IAM file locations.
- 2026-08-01: Removed the ingestion Lambda role after Knowledge Base document sync moved to GitHub Actions.
