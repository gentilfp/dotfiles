# Shared Zoku rules

Skills are installed together. Resolve links relative to the skill directory.

## Start

- Require a `PREFIX-NUMBER` card identifier; ask if missing.
- Use the prefix as `project` and fetch the card with Zoku MCP `get_card`. Stop on failure. Never guess a project or create a new card.
- Stop on a `done` card unless asked to continue.
- Read repository instructions and Git state. Keep unrelated changes untouched.

## Board lifecycle

| Column | API status | Move here when |
|---|---|---|
| Backlog | `backlog` | A card is created, before planning |
| Scoped | `scoped` | `zok-plan` saves a complete plan |
| In Progress | `doing` | Implementation starts or validation fails |
| Review | `review` | Implementation and its checks are ready for `zok-test`; stay here after validation passes |
| Done | `done` | `zok-close` commits and closes after all validation passes |

Use Zoku MCP `update_card` for transitions. Pass `expectedStatus` with the status just read; on a mismatch, reread and stop rather than overwrite another worker's move. Save the summary and status together when handing off. A blocked stage stays in its current column with the blocker recorded; it never advances on an unrun check. Diagnosis and retros do not move cards.

## Card fields

- `description`: the business side. A one-line goal plus acceptance criteria.
- `prompt`: a focused implementation brief with grounded code pointers, ordered changes, boundaries, and concrete verification. Follow `zok-plan` for its structure and sizing.
- `summary`: a short result. First line is `Validation: PENDING`, `PASSED`, or `FAILED`.

Keep fields concise, but do not sacrifice execution-critical detail for brevity. Descriptions and summaries stay short; prompts must be detailed enough for an agent without the planning conversation. No transcripts, no file dumps, no repeated context.

## Pages and notes

- `<PROJECT-NUMBER> diagnosis`: a page from `zok-diagnose`, read by `zok-plan`.
- `Spec: <idea>`: a page from `zok-decompose`.
- Retro reports are notes from `zok-retro`.

Keep this state in Zoku, not in project repositories.

## Working rules

- These are personal projects with few users. Good enough means the happy path works and nothing obvious broke.
- Back every claim with evidence: `file:line`, command output, a test result, or a user decision. "No issue found" is a valid result.
