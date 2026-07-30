# Pipeline Context

## Purpose
Document the GitHub Actions Terraform CI/CD pipeline for safe validation, planning, exact saved-plan promotion, apply, and destroy of the single Terraform root.

## Current state
Pipeline status: `IMPLEMENTED LOCALLY - GITHUB-HOSTED RUN VALIDATION REQUIRED`.

Files implemented:

- `.github/actions/terraform-bootstrap/action.yml`
- `.github/workflows/terraform.yml`
- `scripts/detect_terraform_stacks.sh`
- `scripts/create_plan_metadata.py`
- `scripts/verify_plan_metadata.py`
- `scripts/render_plan_comment.py`
- `scripts/check_destroy_order.sh`
- `scripts/tests/test_plan_metadata.py`
- `scripts/tests/test_destroy_order.py`

## Locked decisions
Workflow triggers:

- `pull_request` for infra, source, frontend, documents, workflow/action, and `.terraform-version` changes
- `workflow_dispatch` with `action` of `plan`, `apply`, or `destroy`; optional `source_run_id` and `destroy_confirmation`

Repository variables:

- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `TF_STATE_BUCKET`
- `TF_STATE_REGION`
- `TF_STATE_PREFIX`
- `TF_ALERT_EMAIL`
- `TF_MONTHLY_BUDGET_LIMIT_USD`

The workflow currently pins the deployment role ARN directly in `.github/workflows/terraform.yml` as `arn:aws:iam::484632959006:role/aws-chatbot`.

State key:

- `<TF_STATE_PREFIX>/dev/terraform.tfstate`

Artifact names:

- PR speculative: `tfplan-pr-<run-id>-infra-dev`
- Manual applyable plan: `tfplan-manual-<run-id>-infra-dev`
- Destroy plan: `tfdestroy-manual-<run-id>-infra-dev`

Artifacts retain for 3 days.

## Interfaces and dependencies
Composite action responsibilities:

- set up pinned Terraform
- configure Terraform plugin cache
- configure AWS credentials through OIDC
- verify the assumed AWS account through `aws sts get-caller-identity`
- generate temporary backend HCL under `RUNNER_TEMP`
- run `terraform init` with S3 backend `use_lockfile = true`
- run `terraform validate`

The composite action does not run `terraform plan`, `apply`, `destroy`, `import`, or repository scripts after credentials are configured.

Pull requests:

- fork PRs receive no AWS credentials and only get static validation plus a skip explanation comment
- same-repository PRs run one speculative plan for the single Terraform root
- speculative artifacts are marked `applyable=false`

Manual trusted plan:

- must run from the repository default branch
- produces `tfplan`, `tfplan.txt`, `tfplan.sha256`, and `metadata.json`
- marks metadata with `applyable=true`, `event=workflow_dispatch`, `action=plan`

Apply:

- requires `source_run_id`
- validates the source run and exact workflow file
- checks out the exact recorded commit
- verifies plan and lockfile SHA-256
- applies only `terraform apply -input=false -auto-approve tfplan`

Destroy:

- requires exact confirmation string `DESTROY dev infra`
- must run from the default branch
- checks for active Bedrock ingestion jobs before creating the destroy plan
- generates a saved destroy plan and applies only that saved plan in a separate job

Metadata schema version is `1` and includes applyability, event/action, repository, workflow file, run ID, stack, environment, commit SHA, branches, Terraform version, state key, plan SHA-256, lockfile SHA-256, creation time, and expiration time.

## Validation evidence
Local validation passed on 2026-07-30:

- `terraform fmt -check -recursive`
- `terraform -chdir=infra init -backend=false`
- `terraform -chdir=infra validate`
- `python -m unittest discover -s scripts/tests`

The pipeline configuration was also aligned with the repository Python unit tests, IAM audit script, and cost guardrail script. GitHub-hosted execution is still required to validate OIDC claims, artifact promotion, and sticky PR comments end to end.

## Open issues
GitHub-hosted execution is still required to validate workflow expressions, OIDC claim behavior, artifact download from source runs, and PR comments. AWS account validation is required for role permissions, state bucket access, S3 lockfile access, S3 Vectors planning, and Bedrock ingestion checks.

## Change log
- 2026-07-28: Initialized pipeline context with required behavior and risks.
- 2026-07-30: Implemented the single-root Terraform workflow, exact-plan metadata flow, destroy safeguards, and updated path/state conventions after the module refactor.
