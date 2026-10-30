---
name: zok-plan
description: Plan one explicitly named Zoku card. Writes the goal and acceptance criteria in the description and a grounded, execution-ready implementation brief in the prompt. Invoke manually with a card identifier such as ZOK-18.
argument-hint: "<PROJECT-NUMBER> [extra instructions]"
disable-model-invocation: true
---

# Zoku Plan

Plan exactly one card. Planning a backlog card is complete only after its saved plan and `scoped` status (the Scoped column) are verified. Do not implement.

Read [shared rules](zok-common.md) and follow Start.

1. If a Zoku page titled `<PROJECT-NUMBER> diagnosis` exists, read it with `get_page` and use it as context. Then inspect the relevant code, callers, and tests. Use CodeGraph when indexed; otherwise use focused search. Look up facts yourself.
   - Trace the affected flow from its entry point to the behavior being changed. Identify the current behavior, likely edit points, existing helpers or patterns to reuse, and relevant tests.
   - Read repository instructions and check manifests/scripts for the actual validation commands. Record verified paths and symbol names; do not invent files, APIs, commands, or diagnosis conclusions.
   - Investigate only enough to produce a reliable plan. Do not implement or run destructive checks. If a critical fact cannot be verified, resolve it before saving; do not disguise a guess as an instruction.
2. Grill the user until you understand the feature deeply. Map the feature as a design tree: every decision branches into the decisions that depend on it. Work the tree in rounds.
   - The frontier is every open decision whose prerequisites are already settled. Ask the whole frontier in one round. A question that depends on another open question in the same round belongs to a later round.
   - Ask with the native `AskUserQuestion` tool, not plain text. Each question gets 2 to 4 clickable options. Put your recommended answer first and end its label with "(Recommended)". The tool adds a free-text "Other" choice itself, so do not add one. Word each question so picking the recommended option means "yes".
   - `AskUserQuestion` takes at most 4 questions per call. If the frontier is larger, ask the 4 most blocking ones first and the rest in the next call.
   - After each round, recompute the tree. Answers settle some branches and unblock others. Ask the next round.
   - Cover scope and non-goals, users and flows, edge cases and failure modes, data and interfaces, existing behavior that must not change, and how to verify it.
   - Look up facts yourself, never ask the user for them. Read the code, the diagnosis page, and the card first. Ask only about decisions: scope, tradeoffs, unclear requirements.
   - Stop when the frontier is empty and nothing is silently assumed. Then give a short summary of what you understood and ask the user to confirm it with one more `AskUserQuestion` (confirm, or tell me what is wrong). Do not go to step 3 before they confirm.
   - Skip this step only when the card is already fully clear. Say so in one line.
3. Draft both card fields using the contract below. Write for a capable but literal implementing agent that has the repository and card, but none of this conversation. Carry forward the decisions and diagnosis findings it needs; do not make it rediscover the design.
4. Apply the handoff check below. Repair missing details before saving. If this reveals an unresolved user decision, return to step 2 rather than choosing silently.
5. Save `description` and `prompt` together with Zoku MCP `update_card`. For a `backlog` card, explicitly include `status: "scoped"` and `expectedStatus: "backlog"` in that same call; saving the text alone does not complete planning. Preserve an existing `scoped`, `doing`, or `review` status when replanning. Follow the shared transition guard and preserve unrelated fields. Then use `get_card` to verify both saved fields and the expected status. If the card is still in `backlog` or the save/read fails, report planning as incomplete with the exact blocker; do not claim success.
6. Report the card identifier, verified column/status, and acceptance criteria briefly. Stop.

## Card field contract

### Description: outcome and acceptance

Write the goal as one plain line, then usually 2 to 5 observable acceptance criteria as bullets. No user-story phrasing. Include important failure cases and behavior that must remain unchanged. Do not omit a distinct requirement just to meet the bullet count. Criteria describe results, not vague activities such as "add tests" or "improve error handling".

### Prompt: execution-ready brief

Use the following headings in order. Fill them with concrete instructions, not template placeholders. A tiny change may need only one bullet per heading; omit an inapplicable heading rather than inventing work. Always include implementation steps and verification.

**Context and decisions**
- State the current behavior, the desired change, and the relevant confirmed decisions. Include the reason for a non-obvious choice when it prevents a plausible wrong implementation.
- Summarize any diagnosis finding needed to make the change. A page link is supporting evidence, not a substitute for the finding.

**Code map**
- Name the verified repository-relative paths and symbols to inspect or change, with each one's role. Include the closest existing implementation or test pattern to reuse.
- Distinguish existing paths from proposed new files. Use stable symbol names; add `file:line` evidence when useful, but do not rely on line numbers alone.

**Implementation steps**
- Give a numbered sequence in dependency order. Each step names the location, the concrete change, and the expected behavior. "Update the backend" is not a step.
- Specify relevant inputs, outputs, interface/data changes, and error or empty-state behavior. State applicable compatibility constraints. Include migrations, configuration, or wiring only when the feature needs them.
- Reuse named existing helpers and patterns. Follow KISS and DRY: smallest complete change, no speculative abstractions, dependencies, or unrelated cleanup. Leave routine coding details to the implementer; do not prescribe every line.

**Boundaries and edge cases**
- State explicit non-goals and existing behavior to preserve. Record the agreed behavior for relevant invalid input, missing data, failures, or repeated actions; do not list irrelevant edge cases as extra scope.
- Make firm requirements distinguishable from suggested edit points. If the code differs from the plan, verify the current code; ask before changing scope or a confirmed decision.

**Verification**
- Name the test file or suite to extend, the concrete scenarios to cover, and expected results. Map each acceptance criterion to a test or a specific manual check; cover the happy path and relevant failure/regression cases.
- Give exact repository-supported commands and the working directory when not the root. Distinguish commands to run from checks already run by the planner. Never claim an unrun check passed.
- When automated coverage is unavailable, give reproducible manual steps and expected outcomes. Name any known environment prerequisite or validation limitation explicitly.

**Completion**
- Remind the implementer to follow `zok-implement`: leave changes uncommitted, run the listed checks, and record results and unresolved issues in the card summary. Move to `review` when ready for testing, never to `done`.

Aim for roughly 5,000–7,500 characters for a typical prompt, not a hard cap or a minimum. A small fix can be shorter; a complex card can be longer when every detail helps execution. Remove repetition, transcripts, code dumps, and speculative detail before removing requirements, code anchors, or checks. Do not restore a 10k-character boilerplate or split one card into several without user approval.

## Handoff check

Before saving, read the draft as a fresh implementing agent and check:

- Can I locate the starting point and reuse pattern without repeating the planner's investigation?
- Does each step tell me what changes and how it should behave, rather than merely naming a topic?
- Are all confirmed decisions and acceptance criteria covered, including important failure cases and preserved behavior?
- Can I verify every criterion with a named scenario, expected result, and runnable command or manual procedure?
- Are paths, symbols, and commands grounded in inspection, proposed additions labeled, and unknowns explicit?
- Could two literal agents produce materially different user-visible behavior while both following this prompt? If yes, resolve the ambiguity.

A brief such as "add validation, handle errors, and test" fails this check. Prefer instructions like "In `<verified path>` / `<symbol>`, reject blank input before calling `<existing helper>`; show `<agreed message>` and leave stored data unchanged. Extend `<verified test path>` with blank-input and valid-input cases; run `<verified command>`." Replace every placeholder with inspected facts or confirmed decisions; never save the example itself.

Do not edit code or commit. Only move `backlog` to `scoped`; do not reset cards already further along.
