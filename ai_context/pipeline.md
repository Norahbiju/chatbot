# Pipeline Context

## Purpose
Document the implemented GitHub Actions Terraform CI/CD pipeline for safe validation, planning, exact saved-plan promotion, apply, and destroy of the two Terraform stacks.

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
- `pull_request` for infra, source, frontend, documents, workflow/action, and `.terraform-version` changes.
- `workflow_dispatch` with `action` of `plan`, `apply`, or `destroy`; `stack` of `core` or `application`; optional `source_run_id` and `destroy_confirmation`. The pipeline currently targets `dev` only.

Repository variables:
- Required: `AWS_ROLE_ARN`, `AWS_REGION`, `AWS_ACCOUNT_ID`, `TF_STATE_BUCKET`, `TF_STATE_REGION`, `TF_STATE_PREFIX`, `TF_ALERT_EMAIL`, `TF_MONTHLY_BUDGET_LIMIT_USD`.
- Optional: `AWS_PLAN_ROLE_ARN`. When absent, PR plans fall back to `AWS_ROLE_ARN` and emit a warning that a separate read-oriented plan role is safer.

GitHub Environments:
- Not used in the current solo-operator workflow.
- If approval gates are needed later, add plan/apply/destroy environments at the end after the basic pipeline has run successfully.

State keys:
- `core`: `<TF_STATE_PREFIX>/dev/core/terraform.tfstate`
- `application`: `<TF_STATE_PREFIX>/dev/application/terraform.tfstate`

Artifact names:
- PR speculative: `tfplan-pr-<run-id>-<stack>-<environment>`
- Manual applyable plan: `tfplan-manual-<run-id>-<stack>-<environment>`
- Destroy plan: `tfdestroy-manual-<run-id>-<stack>-<environment>`

Artifacts retain for 3 days.

## Interfaces and dependencies
Composite action responsibilities:
- Set up pinned Terraform.
- Configure Terraform plugin cache.
- Configure AWS credentials through `aws-actions/configure-aws-credentials` and OIDC.
- Verify the assumed AWS account through an explicit `aws sts get-caller-identity` check.
- Run `aws sts get-caller-identity`.
- Generate temporary backend HCL under `RUNNER_TEMP`.
- Run `terraform init` with S3 backend `use_lockfile = true`.
- Run `terraform validate`.

The composite action does not run `terraform plan`, `apply`, `destroy`, `import`, or repository scripts after credentials are configured.

Stack detection:
- Core: `infra/stacks/core`, `src/ingestion_lambda`, `documents`.
- Application: `infra/stacks/application`, `src/query_lambda`, `frontend`.
- Both: shared modules, environments, provider/version/workflow/action changes, unknown Terraform-related changes.
- Documentation-only changes do not trigger AWS-backed plans unless deployment behavior files changed.

Pull requests:
- Fork PRs receive no AWS credentials. They run static validation only and get a skip explanation comment.
- Same-repository PRs run speculative OIDC plans for affected stacks. Metadata marks them `applyable=false` and comments say `SPECULATIVE PLAN - NOT ELIGIBLE FOR APPLY`.
- Application PR plans may fail before core bootstrap because SSM parameters do not exist; the workflow comments the bootstrap blocker and keeps the job failed.

Manual trusted plan:
- Must run from the repository default branch.
- Produces `tfplan`, `tfplan.txt`, `tfplan.sha256`, and `metadata.json`.
- Metadata marks `applyable=true`, `event=workflow_dispatch`, `action=plan`.
- Publishes plan output to the job summary and artifact.

Apply:
- Requires `source_run_id`.
- Verifies the source workflow run belongs to the same repository, same workflow file, was `workflow_dispatch`, completed successfully, and ran from the default branch.
- Downloads `tfplan-manual-<source-run-id>-<stack>-<environment>`.
- Reads metadata, checks out the exact recorded commit, verifies plan and lockfile SHA-256, initializes the same backend, and applies only `terraform apply -input=false -auto-approve tfplan`.
- Uses concurrency group `terraform-dev-<stack>`.

Destroy:
- Requires exact confirmation string `DESTROY <environment> <stack>`.
- Must run from default branch.
- For `core`, initializes application state first and fails if application resources still exist.
- Checks active Bedrock ingestion jobs where Terraform outputs are available.
- Generates a saved destroy plan, uploads it, then a separate job downloads and applies only that saved destroy plan.
- Uses the same stack concurrency group.

Metadata schema version is `1` and includes applyability, event/action, repository, workflow file, run ID, stack, environment, commit SHA, branches, Terraform version, state key, plan SHA-256, lockfile SHA-256, creation time, and expiration time.

## Validation evidence
Local Terraform validation passed on 2026-07-30:
- `terraform fmt -check -recursive`
- `terraform -chdir=infra/stacks/core init -backend=false`
- `terraform -chdir=infra/stacks/core validate`
- `terraform -chdir=infra/stacks/application init -backend=false`
- `terraform -chdir=infra/stacks/application validate`

Security scan found no static AWS credential patterns, no unsafe PR target trigger, and no direct destroy auto-approve command. Exact saved-plan apply commands appear only in protected apply/destroy-apply jobs.

Unavailable on this workstation: Bash, Node.js, actionlint, shellcheck, and a usable Python interpreter beyond the Windows Store alias. Python tests, shell tests, YAML parser validation, actionlint, and shellcheck remain to be run on a developer machine or GitHub-hosted runner.

## Open issues
GitHub-hosted execution is required to validate workflow expressions, OIDC claim behavior, artifact download from source runs, and PR sticky comments. AWS account validation is required for role permissions, state bucket access, S3 lockfile access, Bedrock/S3 Vectors planning, and destroy active-ingestion checks.

## Change log
- 2026-07-28: Initialized pipeline context with required behavior and risks.
- 2026-07-30: Implemented unified Terraform workflow, composite bootstrap action, metadata scripts, PR comments, exact apply, destroy safeguards, and local validation documentation.
- 2026-07-30: Simplified for solo operation by removing GitHub Environment gates and the manual-plan PR comment input/path; workflow now targets `dev` directly.
- 2026-07-30: Removed unsupported `allowed-account-ids` input from `aws-actions/configure-aws-credentials@v4`; account restriction is now enforced by an explicit STS account check.
