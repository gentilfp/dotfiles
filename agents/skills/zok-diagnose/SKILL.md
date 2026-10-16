---
name: zok-diagnose
description: Investigate a bug on an explicitly named Zoku card whose root cause is unknown, and save a diagnosis page for zok-plan. Does not fix.
argument-hint: "<PROJECT-NUMBER> [logs, steps, or extra context]"
disable-model-invocation: true
---

# Zoku Diagnose

Find the cause of one bug. Do not fix it.

Read [shared rules](../zok-plan/zok-common.md) and follow Start.

1. Read the card and any logs, traces, or steps given.
2. Reproduce the failure locally when possible, then reduce it to the smallest reliable reproduction.
3. Write down each hypothesis. Confirm or disprove it with code, a test, logs, command output, or a small experiment. A hypothesis is not evidence.
4. Stop when more investigation no longer changes your confidence.
5. Save a page with Zoku MCP `create_page`, titled `<PROJECT-NUMBER> diagnosis`. Keep it short:
   - Symptom
   - Reproduction, or exactly what is missing to reproduce it
   - Confirmed facts, each with evidence (`file:line`, command, or output)
   - Disproved hypotheses
   - Root cause, or the best-supported hypothesis and what would confirm it
   - Affected callers or paths
   - Open questions
6. Report the root cause in one or two lines. Next step: `zok-plan` on the same card.

Do not edit code, change the card, commit, or choose the fix. Remove any temporary instrumentation you added.
