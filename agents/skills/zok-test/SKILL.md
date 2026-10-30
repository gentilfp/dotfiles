---
name: zok-test
description: Check that one explicitly named Zoku card works for a user, focused on the happy path, and record a short result.
argument-hint: "<PROJECT-NUMBER> [scenarios or extra instructions]"
disable-model-invocation: true
---

# Zoku Test

Check the change the way a user would. Do not fix the implementation.

Read [shared rules](../zok-plan/zok-common.md) and follow Start. Require a card in `review` with an implementation summary; otherwise return to `zok-implement`.

1. Read the acceptance criteria, the summary, and the uncommitted changes.
2. Use the scenarios you were given. If none, test the happy path only.
3. Do not rerun specs, lint, or builds the implementer already reported as passing. Run them only if they were not reported or the code changed since.
4. Run the app and use it. This step is required. Reading code or rerunning specs does not count.
   - Web app: start the dev server and drive the browser through each scenario.
   - Mobile app: run it in the simulator and tap through each scenario.
   - CLI or desktop app: run it with real input.
   - Library or no runnable surface: write the smallest script that calls it.
   Take a screenshot when a scenario changes what the user sees. Report the screenshot paths. If the app will not start, report `BLOCKED` with the error.
5. Replace the summary's `Validation:` line with `update_card`, one line per scenario, saying how you checked it:
   - `Validation: PASSED` when every required scenario works; keep status `review` for `zok-close`.
   - `Validation: FAILED` with what failed and what was expected. Move to `doing` in the same call and return to `zok-implement`.
   - For `BLOCKED` or remaining batches, use `Validation: PENDING` and keep `review`. Mark any scenario you could not check. Do not count it as passed. Preserve earlier batch results; only mark PASSED when all required batches pass on the current changes.
   Keep the implementer's change description. Leave out command logs and environment details.
6. Report `PASS`, `FAIL`, or `BLOCKED` and stop.
7. Tests ALWAYS run locally, never access a remote or production environment. Unless told and confirmed by the user!

Do not commit or push. Only change status from `review` to `doing` on validation failure. Do not add a test framework.
