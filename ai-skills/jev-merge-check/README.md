# jev-merge-check

Evaluate how confidently a pull request can be merged — does it affect
existing workflows, is it new surface, could it break an integration — using
TypeSafe's Jev System One model directly over HTTP.

Sibling of `jev-plan-check`, which vets an implementation plan before coding.
This one runs on the diff before merging.

## Files

| File | Purpose |
| --- | --- |
| `SKILL.md` | Skill metadata + usage instructions (loaded by pi / Claude Code). |
| `evaluate_merge.sh` | The check itself: builds the API request, calls TypeSafe, renders the report and deterministic verdict. |
| `README.md` | This file. |

## Expected invocation

```bash
# PR number, fetched with gh from the current repo
evaluate_merge.sh --pr 1234

# positional
evaluate_merge.sh "<CHANGE>" "<CONTEXT>"

# environment variables
CHANGE="<CHANGE>" CONTEXT="<CONTEXT>" evaluate_merge.sh

# stdin JSON
echo '{"change":"<CHANGE>","context":"<CONTEXT>"}' | evaluate_merge.sh
```

`evaluate_merge.sh [--raw]` prints the raw API response JSON before the
formatted report.

## Parameters

- `CHANGE` — required. The pull request: title, description, and diff.
- `CONTEXT` — optional. The workflows, consumers, integrations, or invariants
  the change lands in. Omit to judge from the change alone; supply it whenever
  you know the consumers, since it is what makes "does this affect an existing
  workflow" answerable with precision.

Both are sent together as the TypeSafe `state` object:
`{ "change": <CHANGE>, "context": <CONTEXT> }`.

## Required environment variable

- `TYPESAFE_API_KEY` — TypeSafe API key (Bearer token). If missing, the script
  exits 1 with an error naming the variable. There is no fallback to local
  inference.

## Endpoint / model

- `POST https://api.typesafe.ai/v1/systemone`
- `model: jev-latest`

## Evaluated dimensions (Jev questions)

| Dimension | Type | Better when |
| --- | --- | --- |
| workflow_impact | score 0–4 | higher — existing workflows less disturbed |
| breaking_integration | noul 0–1 | lower |
| additive_change | noul 0–1 | informational only (new surface vs. modification) |
| blast_radius | score 0–4 | higher — damage more contained if wrong |
| tests_cover_change | noul 0–1 | higher |
| reversibility | noul 0–1 | higher |

Score questions use a 5-level ordered rubric (0 = worst … 4 = best) sent as
`criteria`; the API returns the probability-weighted score plus the `legend`.

## Verdict thresholds

Scores may be fractional (probability-weighted position across the 5 levels);
nouls are 0–1. **HIGH RISK** (any):

- workflow_impact < 1.5 (higher score = less disruption)
- breaking_integration >= 0.70
- blast_radius <= 1.0 (higher score = more contained)

**REVIEW NEEDED** (otherwise, any):

- workflow_impact < 3.0
- breaking_integration > 0.30
- blast_radius <= 2.0
- tests_cover_change < 0.40
- reversibility < 0.40

**CONFIDENT** — otherwise.

**Severity cap:** HIGH RISK is downgraded to REVIEW NEEDED when
reversibility >= 0.85 and breaking_integration < 0.70 — a safely revertible
change is not high risk on severity alone, but a broken contract is never
capped (consumers see it before a revert lands). The reason is printed under
the verdict when it applies. Tune via `REVERSIBLE_ESCAPE` in the script.

`additive_change` never affects the verdict; it is printed as a change-type
line — *mostly NEW SURFACE* (>= 0.60) or *MODIFIES EXISTING behavior* (< 0.60).

Flags = exactly the REVIEW NEEDED conditions, each printed with the observed
value and the threshold it crossed. To change thresholds, edit the top block
of `evaluate_merge.sh`.

## Error handling

- API key missing → clear error naming `TYPESAFE_API_KEY`, exit 1.
- `--pr` without `gh`, or an unreadable PR → clear error, exit 1.
- HTTP error → status code + response body shown, exit 1 (429/529 retried
  twice with backoff).
- No silent fallback to local model inference.

## Layout

Canonical skill lives in `~/dotfiles/ai-skills/jev-merge-check/`, symlinked
into `~/.claude/skills/jev-merge-check`.
