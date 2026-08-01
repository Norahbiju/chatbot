---
title: GitHub Actions Contexts, Security Boundaries, and Runners
category: CI/CD Security and Runtime
source_reference: GitHub Actions Documentation
retrieved_at: 2026-07-30
---

# GitHub Actions Contexts, Security Boundaries, and Runners

This note summarizes intermediate GitHub Actions concepts from the official documentation for contexts, variables, secrets, OIDC, caching, and runner types.

## Contexts are evaluated before or during runtime depending on where you use them

GitHub Actions contexts are structured values such as `github`, `needs`, `vars`, `runner`, `matrix`, and `inputs`.

The important operational detail is that some of this information can be used before a job is sent to a runner. That is why job-level `if` conditions can stop work before compute is allocated.

This makes contexts useful for:

- default branch checks
- event-type gating
- reusable workflow input control
- metadata-driven naming and routing

## Repository variables and environment variables are not the same thing

The official docs distinguish among:

- workflow YAML `env`
- repository, organization, or environment `vars`
- encrypted `secrets`
- runner-provided default environment variables

An intermediate design usually keeps stable non-secret configuration in repository variables, because that reduces repeated `env` blocks and makes workflows easier to audit.

Secrets should be reserved for genuinely sensitive values. Identifiers such as Terraform state bucket names, regions, or workflow paths normally belong in variables, not secrets.

## Contexts and variables solve different problems

The easiest reliable distinction is:

- **contexts** provide structured runtime or pre-runtime metadata that GitHub Actions exposes about the workflow run
- **variables** provide user-managed values that workflows can reference for configuration

Examples of contexts include `github`, `needs`, `runner`, `matrix`, and `inputs`. Those objects describe what is happening in the run and can often be used in expressions before a job starts.

Examples of variables include repository, organization, or environment `vars`, plus workflow-defined `env` values. Those are mainly for supplying configuration values rather than for describing workflow state.

In practice:

- use a **context** when you need information about the event, job graph, runner, or workflow metadata
- use a **variable** when you need a stable configurable value such as a region, directory path, or state bucket name

That is why contexts are better thought of as metadata surfaces, while variables are better thought of as configuration surfaces.

## OIDC is a trust boundary, not just a convenience feature

OIDC replaces long-lived cloud credentials with short-lived identity federation. The workflow requests an identity token and exchanges it with the cloud provider for a temporary session.

The important part is not only using OIDC, but constraining trust correctly. The cloud role should validate claims such as:

- issuer
- audience
- repository
- branch or environment
- optionally workflow or reusable-workflow metadata

Without these conditions, OIDC is still federated, but not tightly scoped.

## Secrets and untrusted workflow contexts need careful handling

The official documentation is careful about workflows that can execute user-controlled content. Pull requests, especially from less-trusted sources, can combine repository code changes with automation logic changes.

That is why mature designs split:

- validation that can run broadly
- credentialed operations that run only in trusted contexts

The same principle applies to `pull_request_target`. It can be useful, but it must be handled carefully because it runs with a different trust model than ordinary `pull_request`.

## Runner choice affects isolation, networking, and cost

GitHub-hosted runners are convenient and disposable. Self-hosted runners trade that convenience for more control over network access, installed tools, and runtime locality.

For infrastructure automation, runner choice affects:

- whether the job can reach private resources
- whether extra hardening is required
- who patches the runtime
- whether logs and workspace cleanup need more scrutiny

## Caching helps speed, but it also affects reproducibility

Dependency caching improves run time, but it should not be mistaken for artifact promotion.

Cache content is an optimization. It is not the reviewed output of a trusted workflow. That distinction matters in infrastructure systems, where the exact reviewed plan artifact should be promoted to apply rather than recreated from cache.

## Operational takeaways

- Use contexts deliberately because they affect control flow before runtime.
- Prefer repository variables for stable non-secret workflow configuration.
- Keep secrets only for sensitive values that truly require encryption.
- Treat OIDC trust conditions as part of the security model, not optional polish.
- Choose runners based on trust, networking, and lifecycle requirements.
- Treat caching as acceleration, not as a substitute for exact artifact promotion.
hi