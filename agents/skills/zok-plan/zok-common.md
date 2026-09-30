# Shared Zoku rules

All four staged skills must be installed together. This file lives in `zok-plan` so existing skill-directory symlinks expose it. Resolve links relative to the skill directory.

## Start

- Require a `PREFIX-NUMBER` card identifier; ask if missing or malformed.
- Use the prefix as `project` and fetch the full identifier with Zoku MCP `get_card`.
- Read the card's requirements, prompt, status, and summary. Stop on MCP or lookup failure. Never guess a project or create a replacement card.
- Stop on a `done` card unless explicitly asked to continue; `zok-close` always stops.
- Read repository instructions and Git state. Preserve unrelated changes. Explicit user instructions win.

Discover the harness's exposed names for the Zoku MCP operations below.

## Summary

Use this format:

```text
Validation: PENDING
<check results; on PASSED, include Fingerprint: hash>

## Implementation
<changes, decisions, blockers, and exact repository-relative file paths>

## Test instructions
<commands, prerequisites, and expected results>
```

The first line is exactly `Validation: PENDING`, `Validation: PASSED`, `Validation: FAILED`, or `Validation: BLOCKED`.

Zoku MCP `update_card_summary` overwrites the whole field. Test replaces only the leading validation block. Close appends the commit hash. Keep the rest of the existing summary intact; do not rewrite it.

## Fingerprint

From the repository root, use Bash and set the exact card file paths listed under Implementation, including new and deleted files. Test and close use the same list. Do not include unrelated files or broad directories.

```sh
set -o pipefail
set -- 'src/card-file' 'tests/card-test'
{ git rev-parse HEAD && git diff HEAD --binary -- "$@" && git ls-files -o --exclude-standard -z -- "$@" | xargs -0 shasum; } | shasum
```

Save the resulting hash as `Fingerprint: <hash>`. If the command fails, stop. This lightweight check covers HEAD and the card's tracked diff and new file contents, not every filesystem detail.
