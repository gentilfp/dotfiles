---
name: zok-close
description: Commit the validated changes for one explicitly named Zoku card and close it. Invoke manually after zok-test passes.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Close

Invoking this skill authorizes a local commit and card closure, not a push.

Read [shared rules](../zok-plan/zok-common.md) and follow Start, Summary, and Fingerprint.

1. Require a card in `doing` with the exact first summary line `Validation: PASSED`. Otherwise stop: FAILED returns to `zok-implement`; PENDING or BLOCKED returns to `zok-test`.
2. Recompute the fingerprint using the summary's card file paths. If it differs or is missing, stop and require `zok-test` again.
3. Commit only the card's intended changes. Include the card identifier in the message. Preserve unrelated staged changes; ask if file ownership is unclear. If commit hooks change code, require another test pass before closure.
4. Use Zoku MCP `update_card_summary` to append the commit hash without rewriting existing sections. Then move the card to `done` with Zoku MCP `move_card`.
5. Report the card identifier, commit hash, and Git status.

Do not push or open a pull request. If committing or an MCP update fails, stop and report what succeeded. Do not claim closure.
