---
name: zok-implement
description: Implement one explicitly named Zoku card from its acceptance criteria and prompt. Leaves changes uncommitted for zok-test.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Implement

Implement exactly one card. Leave changes uncommitted.

Read [shared rules](../zok-plan/zok-common.md) and follow Start.

1. Move a backlog card to `doing` with Zoku MCP `update_card`.
2. Build what the prompt asks, so the acceptance criteria are met. Find the right files yourself. Make the smallest complete change and reuse existing code.
3. If a requirement is unclear, ask before changing code. On a retry, read the summary first and fix the failure it names.
4. Run the relevant existing checks.
5. Save a summary with `update_card`. Use at most five lines:
   - `Validation: PENDING`
   - What changed, in one or two sentences.
   - Checks run and their results.
   - Open issues, if any.
6. Report briefly. Stop.

Do not commit, push, or move the card to `done`.
