# Pipeline Context

## Purpose
Document the GitHub Actions Terraform CI/CD pipeline for safe validation, planning, exact saved-plan promotion, apply, and destroy of the single Terraform root.

## Current state
Pipeline status: `IMPLEMENTED, SPLIT BY TRIGGER TYPE, AND VALIDATED IN GITHUB ACTIONS`.

Files implemented:

- `.github/actions/terraform-bootstrap/action.yml`
- `.github/actions/repo-validate/action.yml`
- `.github/actions/terraform-plan/action.yml`
- `.github/actions/restore-plan-artifact/action.yml`
- `.github/workflows/terraform-pr-plan.yml`
- `.github/workflows/terraform-dispatch.yml`
- `scripts/detect_terraform_stacks.sh`
- `scripts/create_plan_metadata.py`
- `scripts/verify_plan_metadata.py`
- `scripts/render_plan_comment.py`
- `scripts/check_destroy_order.sh`
- `scripts/tests/test_plan_metadata.py`
- `scripts/tests/test_destroy_order.py`

## Locked decisions
Workflow triggers:

- `pull_request` in `.github/workflows/terraform-pr-plan.yml` for infra, source, frontend, documents, workflow/action, and `.terraform-version` changes
- `workflow_dispatch` in `.github/workflows/terraform-dispatch.yml` with `action` of `plan`, `apply`, or `destroy`; optional `source_run_id` and `destroy_confirmation`

Repository variables:

- `AWS_REGION`
- `AWS_ACCOUNT_ID`
- `AWS_ROLE_ARN`
- `TF_WORKING_DIRECTORY`
- `TF_STATE_BUCKET`
- `TF_STATE_REGION`
- `TF_STATE_KEY`
- `TF_ALERT_EMAIL`
- `TF_MONTHLY_BUDGET_LIMIT_USD`

The workflows now read the fixed working directory, backend state key, and deployment role ARN from repository variables instead of workflow-level `env` blocks.

State key:

- `<TF_STATE_KEY>`

Artifact names:

- PR speculative: `tfplan-pr-<run-id>`
- Manual applyable plan: `tfplan-manual-<run-id>`
- Destroy plan: `tfdestroy-manual-<run-id>`

Artifacts retain for 3 days.

Repository secret used by PR comment jobs:

- `PR_COMMENT_TOKEN`

## Interfaces and dependencies
Composite action responsibilities:

- `terraform-bootstrap` sets up pinned Terraform
- configure Terraform plugin cache
- configure AWS credentials through OIDC
- verify the assumed AWS account through `aws sts get-caller-identity`
- generate temporary backend HCL under `RUNNER_TEMP`
- run `terraform init` with S3 backend `use_lockfile = true`
- run `terraform validate`

Additional composite actions now handle:

- `repo-validate`: Terraform fmt/init/validate, Python tests, IAM/cost audits, and JS syntax checks
- `terraform-plan`: normal or destroy planning, checksums, metadata, PR comment rendering, and job summaries
- `restore-plan-artifact`: saved plan verification, exact-commit checkout, and optional Lambda ZIP restoration

The composite action does not run `terraform plan`, `apply`, `destroy`, `import`, or repository scripts after credentials are configured.

Pull requests:

- same-repository PRs run one speculative plan for the single Terraform root
- fork-specific skip/comment handling was removed to keep the PR workflow smaller
- speculative artifacts are marked `applyable=false`

Manual trusted plan:

- must run from the repository default branch
- produces `tfplan`, `tfplan.txt`, `tfplan.sha256`, and `metadata.json`
- also uploads the generated Lambda ZIP bundles from `infra/modules/*/.terraform/*.zip`
- marks metadata with `applyable=true`, `event=workflow_dispatch`, `action=plan`

Apply:

- requires `source_run_id`
- validates the source run and exact workflow file
- checks out the exact recorded commit
- verifies plan and lockfile SHA-256
- restores the Lambda ZIP bundles saved with the reviewed plan artifact
- applies only `terraform apply -input=false -auto-approve tfplan`

Destroy:

- requires exact confirmation string `DESTROY`
- must run from the default branch
- checks for active Bedrock ingestion jobs before creating the destroy plan
- generates a saved destroy plan and applies only that saved plan in a separate job

Metadata schema version is `1` and includes applyability, event/action, repository, workflow file, run ID, commit SHA, branches, Terraform version, state key, plan SHA-256, lockfile SHA-256, creation time, and expiration time.

## Validation evidence
Local validation passed on 2026-07-30:

- `terraform fmt -check -recursive`
- `terraform -chdir=infra init -backend=false`
- `terraform -chdir=infra validate`
- `python -m unittest discover -s src/ingestion_lambda/tests`
- `python -m unittest discover -s scripts/tests`

GitHub Actions validation on July 30, 2026:

- PR speculative run `30551176122` succeeded, including sticky PR plan comment posting
- Manual trusted plan run `30551450633` succeeded on `main`
- Manual apply run `30551578404` failed and exposed two fixes:
  - CloudFront disabled-cache policy cannot use `query_string_behavior = "all"`
  - exact-plan apply must restore Lambda ZIP artifacts generated during plan
- Manual trusted plan run `30581357958` succeeded on `main`
- Manual exact apply run `30581480625` succeeded from source run `30581357958`
- Live verification after apply returned HTTP `200` from CloudFront and a citation-backed Kubernetes response from the deployed API

## Open issues
SonarCloud is still failing separately and is not part of the Terraform promotion path.

## Change log
- 2026-07-28: Initialized pipeline context with required behavior and risks.
- 2026-07-30: Implemented the single-root Terraform workflow, exact-plan metadata flow, destroy safeguards, and updated path/state conventions after the module refactor.
- 2026-07-30: Fixed PR comment permissions with `PR_COMMENT_TOKEN`, fixed CloudFront disabled-cache policy settings, and updated the manual plan/apply artifact flow to carry Lambda ZIP bundles into exact-plan apply.
- 2026-07-30: Split the workflow into dedicated PR-plan and dispatch files, removed the fork PR note path, simplified duplicated workflow steps, and updated the Terraform pin to 1.15.1.
- 2026-07-30: Replaced repeated workflow shell blocks with focused composite actions for repository validation, plan packaging, and saved-plan restoration.
- 2026-07-30: Removed workflow-level `env` blocks and switched the workflows to repository variables for the fixed working directory, backend state settings, and deployment role settings.
- 2026-07-30: Simplified the single-root pipeline further by removing stack/environment workflow inputs, moving to one fixed `TF_STATE_KEY`, shortening artifact names, and reducing destroy confirmation noise.
- 2026-07-30: Used a temporary Bedrock data-source repair workflow to recover a stuck live resource, then removed that one-off workflow after normal dispatch plan/apply validation succeeded.
