# Shared Zoku rules

Skills are installed together. Resolve links relative to the skill directory.

## Start

- Require a `PREFIX-NUMBER` card identifier; ask if missing.
- Use the prefix as `project` and fetch the card with Zoku MCP `get_card`. Stop on failure. Never guess a project or create a new card.
- Stop on a `done` card unless asked to continue.
- Read repository instructions and Git state. Keep unrelated changes untouched.

## Card fields

- `description`: the business side. A one-line goal plus acceptance criteria.
- `prompt`: short instructions for the implementing agent.
- `summary`: a short result. First line is `Validation: PENDING`, `PASSED`, or `FAILED`.

Keep every field short. No transcripts, no file dumps, no repeated context.

## Pages and notes

- `<PROJECT-NUMBER> diagnosis`: a page from `zok-diagnose`, read by `zok-plan`.
- `Spec: <idea>`: a page from `zok-decompose`.
- Retro reports are notes from `zok-retro`.

Keep this state in Zoku, not in project repositories.

## Working rules

- Back every claim with evidence: `file:line`, command output, a test result, or a user decision. "No issue found" is a valid result.
- Work sequentially. Use the cheapest capable model and no subagents unless the work is isolated and mechanical. A helper reports facts; the calling skill decides.
