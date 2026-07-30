---
title: Kubernetes Service Discovery, Ingress, and Network Policy
category: Containers and Networking
source_reference: Kubernetes Documentation
retrieved_at: 2026-07-30
version: v1.34 themes
---

# Kubernetes Service Discovery, Ingress, and Network Policy

This note summarizes intermediate Kubernetes networking concepts based on the official documentation for Services, DNS, Ingress, and NetworkPolicy.

## Services decouple clients from Pod churn

Pods are replaceable and short-lived. A Service exists so clients do not need to track changing Pod IPs.

The useful mental model is that a Service defines:

- a stable name
- a stable virtual access point
- a policy for which backends receive traffic

Most commonly, the backend set is selected by labels. That means application routing in Kubernetes is often driven by label discipline as much as by container code.

## DNS is part of the platform contract

Kubernetes service discovery is not only about IP routing. It also includes DNS records that let workloads address each other by stable names.

That matters operationally because a workload can be written against logical service names instead of runtime-generated Pod addresses. It also means namespace boundaries influence how names resolve and how much qualification a client needs.

## Ingress is an entry policy, not a replacement for Services

Ingress is often misunderstood as "the thing that exposes the app." A better view is that Ingress expresses HTTP routing policy at the cluster edge, while Services still represent the internal network destinations.

That separation is important:

- Services model backend identity
- Ingress models external path and host routing

In practice, you usually expose a Service and then route to it through Ingress or another gateway layer.

## NetworkPolicy limits who can talk to whom

By default, many clusters are more open than teams expect. NetworkPolicy lets you constrain ingress, egress, or both for matching Pods.

The intermediate design lesson is that NetworkPolicy is about traffic relationships, not only about application exposure. It can be used to express patterns such as:

- only frontends may reach backends
- only selected namespaces may reach a database tier
- application Pods may egress only to approved destinations

Its effectiveness also depends on the network plugin supporting the policy behavior you expect.

## Labels and selectors are the hidden control plane

Networking behavior in Kubernetes depends heavily on labels:

- Services use them to find endpoints
- Deployments use them to manage Pods
- NetworkPolicy uses them to define allowed peers

When labels are inconsistent, multiple systems break at once. That is why label conventions are an operational concern, not only a metadata preference.

## Operational takeaways

- Use Services as the stable contract between clients and replaceable Pods.
- Rely on cluster DNS instead of Pod IP awareness in applications.
- Treat Ingress as HTTP entry routing layered on top of Services.
- Use NetworkPolicy to make traffic boundaries explicit.
- Keep label design disciplined because routing and policy depend on it.
