---
name: zok-plan
description: Scope one explicitly named Zoku card and save an implementation plan in its prompt. Invoke manually with a card identifier such as ZOK-18.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Plan

Work on exactly one card through Zoku MCP. This stage plans; it does not implement.

## Start

Read [shared rules](zok-common.md) and follow its Start section.

## Plan

1. Trace the relevant architecture, code paths, callers, and existing tests. Use CodeGraph when indexed; otherwise use focused search.
2. Identify the smallest complete change, acceptance criteria, and relevant edge cases. Ask about blockers rather than inventing requirements.
3. Use Zoku MCP `update_card` to save a self-contained implementation prompt in the card's `prompt` field. Preserve existing requirements. Include:
   - Goal and acceptance criteria.
   - Relevant files and architecture, with concrete implementation steps.
   - Edge cases and validation commands or manual checks, including expected results.
4. Report the card identifier and a brief plan. Stop; the user invokes `zok-implement` next.

Do not edit code, commit, or change card status. Do not overwrite the implementation summary with the plan.
