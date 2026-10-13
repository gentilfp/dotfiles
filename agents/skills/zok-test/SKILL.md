---
name: zok-test
description: Validate one explicitly named Zoku card against its acceptance criteria and record a short result.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Test

Validate in a fresh session. Do not fix the implementation.

Read [shared rules](../zok-plan/zok-common.md) and follow Start. Require a card in `doing` with a summary; otherwise return to `zok-implement`.

1. Read the acceptance criteria and look at the uncommitted changes.
2. Check each criterion. Run existing tests and any end-to-end check the criteria need. Do not add a test framework.
3. Replace the summary's `Validation:` line and results with `update_card`. Keep it to one line per criterion:
   - `Validation: PASSED` when every criterion holds.
   - `Validation: FAILED` with what failed and what was expected. Return to `zok-implement`.
   - Mark any criterion you could not check. Do not count it as passed.
   Keep the implementer's change description. Leave out file lists, command logs, and environment details.
4. Report the result. Stop.

Do not commit, push, or change status.
