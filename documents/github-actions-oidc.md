---
title: GitHub Actions OIDC
category: CI/CD Security
---

# GitHub Actions OIDC

GitHub Actions can use OpenID Connect to request short-lived cloud credentials. This avoids storing long-lived AWS access keys as repository secrets.

## Trust Policy

An AWS IAM role trust policy should restrict which repository, branch, tag, or environment can assume the role. The policy should validate the GitHub token issuer, audience, and subject claims.

## Terraform Pipelines

A Terraform pipeline should create an exact plan artifact, require review before apply, and use separate state keys for independent stacks. The role used by the pipeline should be scoped to the resources it manages.

## Operational Notes

OIDC improves credential hygiene, but it does not replace least-privilege IAM permissions, protected branches, and careful review of pull requests.
