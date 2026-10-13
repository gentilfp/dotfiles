---
name: zok-close
description: Quick final check, commit, and close for one explicitly named Zoku card after zok-test passes. Does not push.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Close

Invoking this skill authorizes a local commit and closing the card. It does not authorize a push.

Read [shared rules](../zok-plan/zok-common.md) and follow Start.

1. Require a card in `doing` with `Validation: PASSED` on the first summary line. Otherwise stop and name the skill to run next.
2. Do a quick check: look at `git status` and the diff, and run the project's fast tests if there are any. Stop on anything unexpected or failing.
3. Commit only this card's changes, with the card identifier in the message. Ask if file ownership is unclear.
4. With one `update_card` call, add the commit hash to the summary and set the status to `done`.
5. Report the identifier and commit hash.

Do not push or open a pull request. If a step fails, stop and say what succeeded.
