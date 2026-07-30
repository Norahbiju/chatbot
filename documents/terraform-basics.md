---
title: Terraform State, Backends, and Module Design
category: Infrastructure as Code
source_reference: HashiCorp Developer Documentation
---

# Terraform State, Backends, and Module Design

This note summarizes intermediate Terraform concepts based on the official HashiCorp documentation for state, backends, locking, and modules. It focuses on operational behavior rather than just syntax.

## Why Terraform state matters

Terraform state is Terraform's memory of the real objects it manages. It records resource addresses, provider-specific identifiers, dependency relationships, and enough selected attributes for future plans to compare desired configuration with actual infrastructure.

State is important because Terraform is declarative. When you change configuration, Terraform does not search the cloud account blindly and guess ownership. Instead, it consults state to decide which objects belong to the configuration and how changes should be ordered.

## Remote state and operational safety

For collaborative work, local state is usually the wrong choice. A remote backend provides one shared state location so every plan and apply starts from the same source of truth. For an S3 backend, the state is stored in the object path defined by the backend `key`.

Remote state does not remove the need for access control. Anyone who can read the state can often learn sensitive infrastructure details. Anyone who can write the state can break future plans or cause Terraform to forget managed resources.

## State locking with the S3 backend

HashiCorp's documentation explains that Terraform locks state automatically for write operations when the backend supports locking. If locking fails, Terraform stops instead of continuing unsafely.

With the S3 backend, locking is optional and can be enabled with `use_lockfile = true`. This creates a lock object so that two writers do not update the same state concurrently. This matters during `apply`, `destroy`, and other operations that can modify state.

If a run crashes and leaves a stale lock behind, `terraform force-unlock` can remove it, but only after you verify that no other operation is still active. Force-unlocking the wrong lock can create multiple writers and corrupt the workflow.

## Planning, graph ordering, and unknown values

Terraform builds a dependency graph before it applies changes. References between resources create edges in that graph, but explicit `depends_on` is still useful when the dependency is behavioral rather than expressed directly in an argument.

During planning, some values are unknown until apply time. This becomes important when one part of the configuration depends on identifiers created earlier in the same run. A good pattern is to expose those values through outputs and only add explicit dependencies when Terraform cannot infer the correct ordering itself.

## Designing useful modules

Modules are most valuable when they package a stable pattern behind clear inputs and outputs. Good module boundaries reduce repetition, preserve least privilege, and keep resource ownership obvious.

A weak module boundary is one that only wraps a single resource without adding conventions, policies, or reuse. In those cases, the module can make the configuration harder to read without buying much abstraction.

For infrastructure like a Bedrock RAG system, a practical split is often:

- a knowledge-plane module for documents, vectors, ingestion, and Bedrock resources
- an application-plane module for the API, frontend, Lambda query path, and conversation storage

This keeps internal concerns separated while still allowing one root module to plan and apply the whole system together.

## Operational takeaways

- Use a remote backend for team or pipeline-driven infrastructure.
- Turn on backend locking for any shared state.
- Treat `force-unlock` as a recovery tool, not a normal workflow step.
- Prefer modules that enforce a meaningful pattern, not wrappers that hide straightforward resources.
- Review plan artifacts carefully because state correctness and dependency ordering drive every later change.
