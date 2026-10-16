---
name: zok-retro
description: Optional. Turn what a finished or difficult Zoku card taught into at most five small updates to the agent setup, applied only with approval.
argument-hint: "<PROJECT-NUMBER> [extra context]"
disable-model-invocation: true
---

# Zoku Retro

Learn from one card. Optional; never blocks delivery.

Read [shared rules](../zok-plan/zok-common.md) and follow Start, but allow a `done` card.

1. Gather what exists: the card fields, any `<PROJECT-NUMBER> diagnosis` page, the commit and its diff, and what the user tells you.
2. Look for lessons that will matter in a future task, such as a missing acceptance criterion, a missed caller, a weak test, a wrong assumption, or a step a skill should have covered. Skip one-off mistakes. Finding nothing is a valid result.
3. Propose at most five updates. For each, name the exact existing file and the change in one or two lines. Prefer editing existing files, such as a `zok-*` skill in `~/dotfiles/agents/skills/` or a repository's agent instructions.
4. Ask which updates to apply. Apply only the approved ones, and keep each edit small.
5. Save the report with Zoku MCP `create_note`: card, date, what happened, lessons, proposed updates, and applied updates.
6. Report what changed. Stop.

Do not commit. No praise or filler.
