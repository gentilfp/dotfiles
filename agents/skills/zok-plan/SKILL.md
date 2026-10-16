---
name: zok-plan
description: Plan one explicitly named Zoku card. Writes the goal and acceptance criteria in the description and short instructions in the prompt. Invoke manually with a card identifier such as ZOK-18.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Plan

Plan exactly one card. Do not implement.

Read [shared rules](zok-common.md) and follow Start.

1. If a Zoku page titled `<PROJECT-NUMBER> diagnosis` exists, read it with `get_page` and use it as context. Then look at the relevant code and tests. Use CodeGraph when indexed; otherwise use focused search. Look up facts yourself.
2. Ask the user only about decisions: scope, tradeoffs, unclear requirements. Ask all independent questions in one round, each with your recommended answer. Skip this step when nothing is unclear.
3. Save with Zoku MCP `update_card`, once:
   - `description`: the goal as one plain line, then acceptance criteria as bullets. Include edge cases worth checking (for example, invalid input). No user-story phrasing.
   - `prompt`: instructions for the implementer. Describe what to build, such as "add a method that fetches X". Name a file only when it matters. Follow KISS and DRY: reuse existing code, no speculative extras. Aim for under 1,500 characters.
4. Confirm the saved fields, then report the card identifier and the acceptance criteria. Stop.

Do not edit code, commit, or change status.
