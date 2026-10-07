---
name: zok-orchestrate
description: Orchestrate one explicitly named Zoku card through zok-implement, zok-test, and zok-close by spawning separate BB threads on configurable models. The orchestrator never edits code. Invoke manually with a card identifier such as ZOK-74.
argument-hint: "<PROJECT-NUMBER> [role=provider:model[:effort] ...] [from=implement|test] [permission=auto]"
disable-model-invocation: true
---

# Zoku Orchestrate

You are a manager, not a worker. Delegate every stage to a BB thread, read the result from the card, and decide the next step. Never edit code, run the tests, commit, or move the card yourself. Never push.

This skill needs BB (`bb` CLI) and Zoku MCP. Read the `bb-cli` skill and `references/thread-creation.md` and `references/thread-operation.md` in it before the first spawn.

## Input

- Require a `PREFIX-NUMBER` card identifier. Ask if it is missing.
- Optional `role=provider:model[:effort]`, where role is `implement`, `test`, `close`, or `fix`. Repeat a role to add more candidates, in order.
- Optional `from=implement|test` to force the starting stage, and `permission=accept-edits|auto|full` for workers.
- Example: `ZOK-74 implement=acp-opencode:opencode/muse-spark-1.3-contributor-free test=pi:opencode-go/deepseek-v4.1-flash:high`

## Models

Each role has a candidate chain: the models the user sent, in order, then the defaults below. Use the first candidate that works. A candidate is skipped when its model id is missing from `bb provider models <provider> --json` or when the spawn fails. Say which candidate you used and why you skipped others.

| Role | Default provider | Default model | Effort |
|------|------------------|---------------|--------|
| implement | `acp-opencode` | `opencode/muse-spark-1.3-contributor-free` | provider default |
| test | `pi` | `opencode-go/deepseek-v4.1-flash` | provider default |
| close | `acp-opencode` | `opencode/muse-spark-1.3-contributor-free` | provider default |
| fix | `pi` | `opencode-go/deepseek-v4.1-flash` | provider default |

Update the table when the defaults change. Pass `--reasoning-level` only when an effort is set and the model lists it as supported.

## Start

1. Read the shared rules in `../zok-plan/zok-common.md`. Fetch the card with Zoku MCP `get_card` (project is the prefix). Stop on failure or on a `done` card.
2. Run `bb status --json` for the project id and environment id. The workers must run on this thread's own project checkout: pass `--environment "$BB_ENVIRONMENT_ID"`. Do not create worktrees. If this project does not hold the card's code, stop and tell the user to start the orchestrator from the right project.
3. Choose the start stage from the summary's first line, unless `from=` is given:
   - No summary, or no implementation: `implement`.
   - `Validation: PENDING` with an Implementation section: `test`.
   - `Validation: FAILED`: `implement` (retry).
   - `Validation: BLOCKED`: stop and ask the user.
   - `Validation: PASSED`: `close`.
4. **Confirm with the user before the first spawn.** Show the card title, the start stage, the resolved model chain per role, the permission mode, and the loop limits. Wait for a clear yes. Do not spawn before that.

## State

Keep these in your head and repeat the line after every transition: `stage`, `fix_rounds` (starts at 0), `implementer_thread`, `threads` (id, role, model, outcome), and token use from `bb thread context <id> --json` after each worker. Append the same lines to `$TMPDIR/zok-orchestrate-<card>.log`.

## Spawn a worker

1. Write the prompt to a file, for example `$TMPDIR/zok-<card>-<role>.md`. Keep it minimal: the slash command and the card id, plus the previous result only when the role needs it. Do not re-explain the card.
2. Spawn:

```sh
bb thread spawn --json --project <project-id> --environment "$BB_ENVIRONMENT_ID" \
  --provider <provider> --model <model> --permission-mode <mode> --parent-self \
  --title "<card> <role>" --prompt-file <path>
```

3. Run `bb thread wait <thread-id> --timeout 40m --json`. On timeout or a failed status, read `bb thread log <id>` and `bb thread show <id> --json`, then use `bb thread retry <id>` once, then try the next candidate.
4. Stop the worker with `bb thread stop <id>` when it is done, except the implementer thread, which you keep for fix rounds.
5. Never trust the worker's chat output as the verdict. Re-read the card with Zoku MCP `get_card` and use the first line of its summary.

Run one worker at a time. They all share one checkout.

## Loop

Prompts are `/zok-<role> <card>`. A fresh thread runs each test, as `zok-test` requires.

1. **implement**: spawn the implement role. Keep its thread as `implementer_thread`. When the card summary shows an Implementation section, go to step 2. If the implementer reports a blocker or missing requirements, stop and ask the user.
2. **test**: spawn a new thread for the test role. Read the verdict:
   - `PASSED`: go to step 3.
   - `FAILED`: go to step 4.
   - `BLOCKED`: stop and report to the user. A blocked check is not a pass and not a code failure.
3. **close**: spawn a new thread for the close role with `/zok-close <card>`. After it ends, read the card. Done means status `done` and a commit hash in the summary. Report the card, the commit hash, and Git status. If close rejects the fingerprint, go back to step 2. The task is complete only here.
4. **fix loop**: add 1 to `fix_rounds`.
   - While `fix_rounds` is 2 or less: send the failure to the same implementer thread with `bb thread tell <implementer_thread> --message-file <path>` (use `bb thread wait` afterward). The message is: `/zok-implement <card>` plus the failed validation text copied from the summary. Then go to step 2.
   - After the implementer has had 2 rounds and the test still fails: spawn the `fix` role in a new thread with `/zok-implement <card>` plus the full failure history. Then go to step 2 once more. If that test fails too, stop and report to the user with the three failures.

## Rules

- Escalate the model only through the chain above, never silently.
- Never skip a stage because a worker says it passed. Only the card's `Validation:` line counts.
- Do not archive or delete threads. The user may want to read them.
- Report each transition in one or two lines: what ran, on which model, the verdict, and the next step. Finish with the final state and one clear next step.
