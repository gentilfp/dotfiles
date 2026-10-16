---
name: zok-risk-check
description: Classify a Zoku card or short task as tiny, normal, or risky and recommend how much rigor the zok workflow needs. Read-only.
argument-hint: "<PROJECT-NUMBER | task description>"
disable-model-invocation: true
---

# Zoku Risk Check

Classify one task. Read-only: do not change code, cards, or plans.

Read [shared rules](../zok-plan/zok-common.md). With a card identifier, follow Start. With a task description, skip Start.

1. Read the task and, when it points at code, the affected files and callers.
2. Check the risk triggers:
   - Authentication, permissions, or data scoping
   - Database migrations or destructive data changes
   - Public API or caller-contract changes
   - Payments, billing, security, or secrets
   - Background jobs, retries, concurrency, or idempotency
   - Changes that touch several callers or request paths
3. Classify:
   - `tiny`: one obvious change, no trigger. Implementing directly from the card is fine; `zok-plan` is optional.
   - `normal`: no trigger. Use the normal flow.
   - `risky`: at least one trigger. Use the normal flow, add an acceptance criterion for each trigger, and suggest `jev-plan-check` before implementing.
4. Report, and stop:

   ```text
   Size: tiny | normal | risky
   Reason: <triggers found, with file:line when relevant>
   Flow: <steps to run>
   ```

The user may override the size. Always state your recommendation.
