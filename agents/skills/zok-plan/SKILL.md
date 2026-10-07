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
2. Grill the card relentlessly until shared understanding. Map decisions as a **design tree**: every decision branches into decisions hanging off it. Work the tree in **rounds**:
   - The **frontier** is every decision whose prerequisites are settled: questions you can ask *now* without guessing unheard answers. Ask the whole frontier in one round, then wait for answers before the next round.
   - Format a round as:
     ```
     ❓ **Q1** - **<question title>**: <body, may include multiple choices>

     ➡️ <your recommended answer>

     ---

     ❓ **Q2** - **<question title>**: <body, may include multiple choices>

     ➡️ <your recommended answer>
     ```
     Prefer the `question` tool when available; fall back to the text format above.
   - A question whose answer depends on another open question belongs to a *later* round, not this one. Each round reshapes the tree: settled decisions push the frontier outward. Recompute and ask the next round.
   - Finding *facts* is your job, never the user's. Look up environment facts (filesystem, CodeGraph, tests, Zoku card) yourself; do not ask the user for anything you can look up. A running exploration is an unsettled prerequisite: only questions downstream of it wait; ask the rest of the frontier now.
   - *Decisions* are the user's: scope, tradeoffs, ambiguous requirements, blockers. Ask rather than inventing requirements. The session is done when the frontier is empty: every branch visited, nothing silently assumed.
3. Draft the implementation prompt in **bounded sections**, not one ever-growing string: goal/acceptance, files and steps, edge cases and validation (commands or manual checks with expected results). Summarize each section before joining them. Keep decisions and requirements, but remove repeated context, transcripts, lengthy fixture contents, speculative alternatives, and explanations that do not change implementation. Use short bullets and repository-relative paths. The final prompt must stand alone for `zok-implement`; do not rely on this conversation or move plan content into the implementation summary.
4. Before calling Zoku MCP `update_card`, measure the **entire final prompt** (including the existing requirements you need to preserve). Target at most 8,500 characters to leave room below a 10,000-character limit; never send a prompt over 9,000 characters. If too long, compact sections in batches and remeasure. Do not split the plan across multiple `update_card` calls: `prompt` is replaced, not appended. If essential requirements still do not fit, stop and ask the user how to narrow scope rather than silently dropping them or saving a partial plan.
5. Save the complete, measured prompt once with Zoku MCP `update_card`; confirm the returned card contains the intended prompt (refetch if the response does not include it). If saving or verification fails, report the blocker; do not claim the plan was saved.
6. Report the card identifier and a brief plan. Stop; the user invokes `zok-implement` next.

Do not edit code, commit, or change card status. Do not overwrite the implementation summary with the plan.
