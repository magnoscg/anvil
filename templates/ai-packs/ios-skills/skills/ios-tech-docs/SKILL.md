---
name: ios-tech-docs
description: Produce evidence-backed iOS engineering documentation from the repository, build settings, tests, and operational workflows without inventing missing behavior.
license: MIT
metadata:
  author: Oscar Canton
  origin: first-party
---

# iOS Technical Documentation

Use this skill to create or update architecture guides, module references, onboarding material, runbooks, ADRs, release notes, or troubleshooting documents for an Apple-platform project.

## Evidence order

Prefer evidence in this order:

1. repository instructions and existing documentation;
2. project and package manifests;
3. production source and public interfaces;
4. tests and fixtures;
5. CI, build, signing, and deployment configuration;
6. commit history when the reason for a decision is not present in the current tree.

Distinguish confirmed behavior from an inference. Mark unresolved questions rather than filling gaps with plausible text.

## Workflow

1. Define the audience and the decision the document must support.
2. Map the relevant targets, modules, entry points, data flow, dependencies, and tests.
3. Verify commands against the current repository.
4. Draft the smallest document that answers the audience's questions.
5. Add links to source paths or symbols that are stable enough to maintain.
6. Review the draft for stale version numbers, secrets, internal URLs, personal data, and unsupported claims.

## Document shapes

- **Architecture guide:** context, boundaries, dependency direction, runtime flow, persistence, failure handling, and trade-offs.
- **ADR:** status, context, decision, alternatives, consequences, and follow-up triggers.
- **Module guide:** responsibility, public surface, dependencies, data ownership, extension points, and tests.
- **Runbook:** symptom, impact, prerequisites, diagnosis, safe remediation, verification, rollback, and escalation.
- **Onboarding:** prerequisites, setup, first build, test commands, common failures, and a small verified first task.
- **Release guide:** version inputs, signing source, build/archive steps, checks, distribution boundaries, rollback, and ownership.

## iOS-specific checks

Confirm deployment targets, Swift language mode, actor isolation, entitlements, privacy usage descriptions, schemes, configurations, signing assumptions, and generated-code boundaries. Never copy credentials, provisioning material, private keys, or production tokens into documentation.

## Quality bar

Every command must be runnable, every diagram must match the prose, and every operational step must name its verification signal. A document is incomplete when it explains the happy path but omits failure ownership or rollback.
