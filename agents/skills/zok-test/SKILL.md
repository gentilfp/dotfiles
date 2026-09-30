---
name: zok-test
description: Validate one explicitly named Zoku card from its implementation summary and record results. Stop on failures and hand back to zok-implement.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Test

Run in a fresh session from `zok-implement`. Validate; do not fix the implementation.

Read [shared rules](../zok-plan/zok-common.md) and follow Start, Summary, and Fingerprint.
Require a card in `doing` with an implementation summary and exact card file paths. Otherwise return to `zok-implement`.

1. Compare the actual changes with the card's requirements. Capture the fingerprint using only the listed card files.
2. Run the summary's checks and relevant existing tests, including end-to-end checks when needed. Do not introduce a new test framework.
3. Use Zoku MCP `update_card_summary` to replace only the leading validation block, keeping the other sections intact:
   - `Validation: PASSED`: all required checks passed and the card fingerprint is unchanged. Include `Fingerprint: <hash>` and the commands and results.
   - `Validation: FAILED`: record the failure and expected behavior. Stop and return to `zok-implement`.
   - `Validation: BLOCKED`: record checks that could not run or card files that changed during testing. Stop; missing checks are not passes.
4. Report the result. Only PASSED is ready for `zok-close`. After fixes, test again in a fresh session.

Do not commit, push, or change card status. If saving results fails, stop and report the blocker.
