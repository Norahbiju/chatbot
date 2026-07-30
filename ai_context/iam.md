# IAM Context

## Purpose
Document IAM roles, trust policies, action scopes, wildcard audits, and service-role considerations for the Bedrock RAG chatbot.

## Current state
Implemented locally in Terraform. Roles: Bedrock Knowledge Base service role, ingestion Lambda role, query Lambda role, plus service permissions for API Gateway, EventBridge, SQS, CloudFront OAC, SNS, and Budgets through resource policies or service integrations.

## Locked decisions
Lambda roles do not include `Resource = "*"`, broad actions such as `bedrock:*`, `s3:*`, `dynamodb:*`, `sqs:*`, `logs:*`, or permissions outside their workflows. Lambda log groups are pre-created so Lambda roles do not need `logs:CreateLogGroup`.

## Interfaces and dependencies
Knowledge Base role trust principal: `bedrock.amazonaws.com`, restricted by source account and `knowledge-base/*` source ARN pattern because the exact KB ARN is not available until creation. Permissions: S3 read/list on the exact source bucket and prefix, `bedrock:InvokeModel` on Titan embedding model ARN, S3 Vectors actions on the exact vector bucket/index ARNs.

Ingestion Lambda trust principal: `lambda.amazonaws.com`. Permissions: SQS consume actions on the ingestion queue ARN, CloudWatch Logs stream/write on the exact log group streams, `bedrock:StartIngestionJob` and `bedrock:ListIngestionJobs` on the exact KB ARN where supported.

Query Lambda trust principal: `lambda.amazonaws.com`. Permissions: `bedrock:Retrieve` on the exact KB ARN, `bedrock:InvokeModel` on the exact generation model ARN, DynamoDB `Query`, `GetItem`, `PutItem` on the exact table ARN, CloudWatch Logs stream/write on exact log group streams.

GitHub OIDC deployment role is not modified by this repository. The required OIDC provider is `token.actions.githubusercontent.com` with audience `sts.amazonaws.com`.

Trust-policy subject concepts to authorize deliberately:
- Default-branch manual plan/apply/destroy: `repo:OWNER/REPOSITORY:ref:refs/heads/DEFAULT_BRANCH`
- Pull-request plan: `repo:OWNER/REPOSITORY:pull_request`

Do not copy these with fictional owner/repository names; replace with the real GitHub owner, repository, and default branch. GitHub Environments are not currently used; if approval environments are added later, the AWS trust policy must also allow the corresponding environment subject claims.

Deployment-role permissions are distinct from Lambda runtime roles. The deployment role needs S3 backend state and `.tflock` object access, Terraform plan read permissions, and apply/destroy permissions for the project resources: Bedrock Knowledge Bases/data sources, Bedrock model invocation permissions where Terraform validates them, S3 Vectors, S3 buckets/objects/policies, Lambda, IAM role/policy management for project roles, API Gateway, CloudFront, DynamoDB, SQS, EventBridge, SNS, CloudWatch, Budgets, and SSM parameters. A separate `AWS_PLAN_ROLE_ARN` is recommended for PR plans with read-oriented permissions where possible.

## Validation evidence
`scripts/validate_iam.py` statically checks Lambda policy documents for wildcard resources and broad actions, but could not be executed locally because Python is not installed/on PATH. Substitute PowerShell search found no Lambda wildcard resources or broad Lambda service actions. The only broad S3 action is in the non-Lambda TLS-deny S3 bucket policy. Pipeline security scan found no static AWS credential patterns and no unsafe PR target trigger.

## Open issues
Some AWS APIs may not support resource-level permissions exactly as modeled; Terraform validation and AWS deployment are required to confirm. If Bedrock model invocation requires inference profile ARNs in the account, enumerate exact ARNs and document data residency implications.

## Change log
- 2026-07-28: Created IAM matrix, scoped Lambda policies, KB service role notes, and static audit script.
- 2026-07-30: Added GitHub OIDC trust guidance, deployment-role requirements, plan-role recommendation, and pipeline security scan evidence.
- 2026-07-30: Updated OIDC notes after removing GitHub Environment gates for solo operation.
