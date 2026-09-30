---
name: zok-implement
description: Implement one explicitly named Zoku card and save a summary for testing without closing it. Invoke manually with a card identifier such as ZOK-18.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Implement

Work on exactly one card through Zoku MCP. Leave the result uncommitted and open for `zok-test`.

## Start

Read [shared rules](../zok-plan/zok-common.md) and follow Start and Summary.
Move a backlog card to `doing` with Zoku MCP `move_card`; keep it `doing` throughout implementation.

## Implement and Hand Off

1. Follow the card's prompt, trace the actual code paths, and make the smallest complete change. If requirements are unclear, ask before changing code.
2. On a retry, read the summary's failed validation and fix the cause. Run relevant automated checks and record their actual results.
3. Use Zoku MCP `update_card_summary` to save a substantive handoff:
   - First line exactly `Validation: PENDING`, followed by checks already run and their results. Independent validation by `zok-test` is still required; remove any previous pass fingerprint.
   - `## Implementation`: changes, exact repository-relative card file paths (including new and deleted files), important decisions, and blockers.
   - `## Test instructions`: exact commands and manual steps, prerequisites, and expected behavior, including end-to-end checks when relevant.
   Preserve any other existing summary sections when refreshing the handoff.
4. Report the changes and blockers, then stop. The user invokes `zok-test` in a fresh session next.

Save the summary even when implementation is blocked or incomplete, clearly stating that testing cannot proceed. Every implementation change resets validation to PENDING; an earlier pass is no longer valid.

Do not commit, push, open a pull request, or move the card to `done`. If saving the summary fails, report the blocker; the handoff is not complete.
