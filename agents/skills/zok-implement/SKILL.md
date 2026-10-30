---
name: zok-implement
description: Implement one explicitly named Zoku card from its acceptance criteria and prompt. Leaves changes uncommitted for zok-test.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Implement

Implement exactly one card. Leave changes uncommitted.

Read [shared rules](../zok-plan/zok-common.md) and follow Start.

1. Require a planned card with acceptance criteria and an implementation prompt; otherwise return to `zok-plan`. Move `scoped` (or an already planned `backlog`) to `doing` with Zoku MCP `update_card` before editing. Resume `doing`; move `review` back to `doing` only for an authorized fix. Follow the shared transition guard and invalidate any previous validation with `Validation: PENDING` when starting changes.
2. Build what the prompt asks, so the acceptance criteria are met. Find the right files yourself. Make the smallest complete change and reuse existing code.
3. If a requirement is unclear, ask before changing code. On a retry, read the summary first and fix the failure it names.
4. Run the relevant existing checks.
5. Save a summary with `update_card`. If implementation is complete and the relevant checks pass, set status to `review` in the same call; otherwise keep `doing` and record the failure or blocker. Use at most five lines:
   - `Validation: PENDING`
   - What changed, in one or two sentences.
   - Checks run and their results.
   - Open issues, if any.
6. Report briefly. Stop.

Do not commit, push, or move the card to `done`.
