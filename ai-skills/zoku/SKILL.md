---
name: zoku
description: Work on one explicitly named Zoku card through the Zoku MCP workflow. Invoke manually with a card identifier such as ZOK-18 or ABC-12.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Card Workflow

Use Zoku MCP as the task tracker. Work on exactly one card supplied by the user.

## Input

Require a card identifier in `PREFIX-NUMBER` form, such as `ABC-12`.

- Derive the Zoku project prefix from the text before the hyphen (`ZOK`, `ABC`).
- Pass that prefix as `project` to every Zoku MCP card operation.
- Pass the full identifier as `card_id` when fetching the card.
- If the identifier is missing or malformed, ask for it before changing code or Zoku.
- Never infer a different project from the repository name or create a replacement card when lookup fails.

## Start

1. Use `zoku_get_card` to fetch the card from its prefix project.
2. Read its title, description, prompt, status, and existing summary before editing code.
3. Read repository instructions and inspect current Git state. Preserve unrelated changes.
4. If the card is in backlog, move it to `doing` with `zoku_move_card`. If already `doing`, continue. If already `done`, report that and stop unless the user explicitly asks to reopen or continue it.
5. Treat card content plus any invocation text after the identifier as requirements. Explicit user instructions win on conflict.

If Zoku MCP is unavailable, authentication fails, or the card cannot be found, stop and report the exact blocker. Do not silently work from guessed task details.

## Work

- Trace the relevant code path, then make the smallest complete change that satisfies the card.
- Follow repository instructions and existing architecture.
- Run available automated checks that cover the change.
- Do not commit, push, open a pull request, or move the card to `done` during implementation.
- Do not mark blocked or failed work as done. Leave the card in `doing` and explain the blocker.

## Review Handoff

When implementation and automated checks finish, stop for user review. Report:

- What was added, changed, or removed.
- Automated checks run and their results.
- Exact manual test steps, including expected behavior.
- Any remaining risk or check that could not be run.

Keep changes uncommitted. Wait for explicit user approval or requested revisions.

## Revisions

If the user requests changes, keep the card in `doing`, make them, rerun relevant checks, and provide updated test instructions. Do not close the card based on implementation completion alone.

## Approval and Closure

Only after the user explicitly approves the reviewed result:

1. Run any final check requested by the user.
2. Use `zoku_update_card_summary` with a substantive summary of implementation, important decisions, and validation performed.
3. Move the card to `done` with `zoku_move_card`.
4. Report the closed card identifier and current Git status.

Do not commit unless the user explicitly asks for a commit. If asked, commit only intended files and include the card identifier in the commit message.
