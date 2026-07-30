---
title: Terraform Basics
category: Infrastructure as Code
---

# Terraform Basics

Terraform describes cloud infrastructure in configuration files and compares that desired state with the real infrastructure during planning. The plan shows proposed additions, changes, and deletions before any apply operation.

## State

Terraform state records the resource addresses, provider identifiers, and selected attributes that Terraform needs to manage infrastructure over time. Remote state helps teams share one authoritative view of managed resources.

## State Locking

State locking prevents two Terraform runs from modifying the same state at the same time. Without locking, concurrent applies can overwrite each other's view of infrastructure and produce drift or broken dependencies.

## Modules

Modules package related resources behind inputs and outputs. They are most useful when they reduce repetition or enforce a shared pattern across multiple stacks.
