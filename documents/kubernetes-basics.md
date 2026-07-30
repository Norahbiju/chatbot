---
title: Kubernetes Basics
category: Containers
---

# Kubernetes Basics

Kubernetes schedules containerized workloads across a cluster of nodes. A workload usually starts with a Deployment, which manages replicas of Pods and performs rolling updates.

## Pods and Services

A Pod is the smallest schedulable unit and can contain one or more tightly coupled containers. A Service gives a stable network endpoint for matching Pods even as individual Pods are replaced.

## Config and Secrets

ConfigMaps hold non-sensitive configuration. Secrets hold sensitive values, though production systems should still use encryption, access controls, and careful rotation practices.

## Fit for This Project

Kubernetes is powerful for long-running container platforms, but this chatbot uses AWS serverless services to minimize idle cost and operational overhead.
