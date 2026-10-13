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
