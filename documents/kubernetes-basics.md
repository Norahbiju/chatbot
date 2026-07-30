---
title: Kubernetes Deployments, Services, and Configuration
category: Containers
source_reference: Kubernetes Documentation
---

# Kubernetes Deployments, Services, and Configuration

This note summarizes intermediate Kubernetes concepts from the official Kubernetes documentation, with emphasis on workload management and configuration patterns that appear often in production systems.

## Deployments are rollout controllers, not just templates

A Deployment manages a desired application state by creating and updating ReplicaSets, which in turn manage Pods. The useful mental model is that a Deployment is a rollout controller: it decides how a new Pod template replaces an older one over time.

Because Deployments manage ReplicaSets for you, you normally should not manipulate those child ReplicaSets directly. The Deployment controller uses them to support rollout history, scale transitions, and rollback behavior.

## Progressive rollout behavior

When the Pod template changes, Kubernetes creates a new ReplicaSet and gradually shifts traffic capacity from the old Pods to the new Pods. This controlled transition is why settings such as readiness checks, replica counts, and rollout deadlines matter operationally.

Intermediate operators often look at these Deployment fields:

- replica count, to define expected steady-state capacity
- strategy settings, to control how quickly old Pods are replaced
- progress deadlines, to detect a rollout that has stalled
- revision history retention, to balance rollback usefulness with object churn

The Deployment status is not only informational. It is also how you determine whether a rollout is progressing, complete, or stuck.

## Services give workloads stable discovery

Pods are disposable, so clients should not depend on Pod IPs. A Service creates a stable virtual endpoint that selects matching Pods even as individual instances are replaced.

This is one of the reasons Kubernetes apps are usually described as several cooperating API objects rather than one giant object. A Deployment handles lifecycle and scale, while a Service handles stable network identity.

## ConfigMaps are for non-secret operational data

The official docs describe ConfigMaps as key-value configuration for other objects. Pods can consume them as environment variables, command arguments, or mounted files.

That flexibility makes ConfigMaps useful, but they are not a general data store. Important limits and rules include:

- ConfigMaps are meant for non-confidential data
- they should stay relatively small
- keys have naming constraints
- they can be made immutable when churn should be prevented

If the data is sensitive, the right baseline object is a Secret, not a ConfigMap.

## Useful design pattern: separate code, config, and access

An intermediate Kubernetes design usually separates concerns this way:

- container image defines executable code
- Deployment defines runtime shape and rollout behavior
- ConfigMap defines non-secret environment-specific settings
- Secret defines confidential values
- Service defines stable network access

That separation lets the same image move across environments while the cluster-specific behavior changes through API objects rather than rebuilt artifacts.

## Operational takeaways

- Treat Deployments as rollout managers, not just "the thing that starts Pods."
- Use Services whenever clients need a stable destination.
- Keep ConfigMaps for non-secret configuration and avoid using them as large data blobs.
- Watch Deployment status during upgrades, because a stalled rollout is often the first visible sign of an application or readiness problem.
- Separate runtime configuration from images so changes can be promoted cleanly across environments.
