---
title: GitHub Actions Workflow Design and AWS OIDC
category: CI/CD Security
source_reference: GitHub Actions Documentation
---

# GitHub Actions Workflow Design and AWS OIDC

This note is based on the official GitHub Actions documentation for workflow syntax and OpenID Connect with AWS. It focuses on the patterns that matter when a workflow is trusted to manage infrastructure.

## Workflow structure and job dependencies

GitHub describes a workflow as an automated process made of one or more jobs. Jobs run in parallel unless you connect them with `needs`.

That default matters for infrastructure automation. Validation, planning, apply, and destroy are not just separate jobs for readability; they are separate trust boundaries. `needs` is what turns them into a controlled sequence instead of an accidental race.

## Why exact plan promotion matters

In an infrastructure workflow, it is not enough to "plan in one run and apply later." The safe pattern is to apply the exact plan artifact that reviewers saw, tied to the exact commit and lockfile that produced it.

This protects against several failure modes:

- a branch changes between review and apply
- provider selections drift because the lockfile changed
- someone reruns apply against a fresh plan that was never reviewed

That is why plan metadata, artifact integrity checks, and exact-commit checkout are more than extra ceremony. They are part of the security model.

## OIDC replaces long-lived cloud secrets

GitHub's OIDC support lets workflows request short-lived tokens instead of storing cloud access keys as repository secrets. For AWS, the workflow exchanges the GitHub-issued identity for an IAM role session.

The AWS trust relationship should verify more than the issuer alone. The GitHub documentation specifically highlights conditions such as the repository subject claim so that unrelated repositories or event types cannot assume the role.

Useful trust checks typically include:

- issuer URL for GitHub's token service
- audience expected by AWS STS
- subject conditions for the intended repository and branch or environment

## Permissions should stay narrow inside the workflow too

Even when OIDC is configured correctly, the workflow should not receive broad default permissions. GitHub workflow syntax lets you limit token permissions per workflow or job, which reduces the blast radius if a step is compromised or misused.

The same idea applies to AWS. The OIDC role used by the workflow should be scoped to the Terraform backend, planning reads, and the exact infrastructure resources it is meant to manage.

## Pull request planning is not the same as trusted apply

A pull request plan is useful for review, but it is not always safe to treat every PR as trusted. Forked pull requests are a common example: they may need validation and comment output without receiving cloud credentials.

A mature workflow usually distinguishes among:

- static validation that can run everywhere
- speculative plans for trusted repository branches
- apply operations that are limited to reviewed, manually initiated, default-branch runs

## Operational takeaways

- Use `needs` to encode control flow explicitly between validation, plan, and apply jobs.
- Apply the exact saved plan that was reviewed, not a newly generated one.
- Use OIDC for AWS access instead of long-lived GitHub secrets.
- Restrict the IAM trust policy with repository and branch or environment conditions.
- Keep both GitHub token permissions and AWS role permissions as small as the workflow allows.
