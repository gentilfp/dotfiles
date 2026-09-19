# jev-plan-check

Evaluate whether an implementation plan is sufficiently complete for a given
task/ticket, using TypeSafe's Jev System One model directly over HTTP.

## Files

| File | Purpose |
| --- | --- |
| `SKILL.md` | Skill metadata + usage instructions (loaded by pi / Claude Code). |
| `evaluate_plan.sh` | The check itself: builds the API request, calls TypeSafe, renders the report and deterministic verdict. |
| `README.md` | This file. |

## Expected invocation

```bash
# positional
evaluate_plan.sh "<TASK>" "<PLAN>"

# environment variables
TASK="<TASK>" PLAN="<PLAN>" evaluate_plan.sh

# stdin JSON
echo '{"task":"<TASK>","plan":"<PLAN>"}' | evaluate_plan.sh
```

`evaluate_plan.sh [--raw]` prints the raw API response JSON before the
formatted report.

## Required parameters

- `TASK` — the original task, ticket, issue, or requirement.
- `PLAN` — the implementation plan to evaluate.

Both are sent together as the TypeSafe `state` object:
`{ "task": <TASK>, "plan": <PLAN> }`.

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
| completeness | score 0–4 | higher |
| missing_edge_cases | noul 0–1 | lower |
| migration_risk | score 0–4 | lower — higher score = lower risk |
| tests_adequate | noul 0–1 | higher |
| rollback_covered | noul 0–1 | higher |
| scope_creep | noul 0–1 | lower |

Score questions use a 5-level ordered rubric (0 = worst … 4 = best) sent as
`criteria`; the API returns the probability-weighted score plus the `legend`.

## Verdict thresholds

Scores may be fractional (probability-weighted position across the 5 levels);
nouls are 0–1. **INCOMPLETE** (any):

- completeness < 2.0
- missing_edge_cases ≥ 0.70
- migration_risk ≤ 1.0 (higher score = lower risk)

**NEEDS REVIEW** (otherwise, any):

- completeness < 3.0
- missing_edge_cases > 0.35
- migration_risk ≤ 2.0 (higher score = lower risk)
- tests_adequate < 0.40
- rollback_covered < 0.40
- scope_creep > 0.60

**READY** — otherwise.

Flags = exactly the NEEDS REVIEW conditions, each printed with the observed
value and the threshold it crossed. To change thresholds, edit the top block
of `evaluate_plan.sh`.

## Error handling

- API key missing → clear error naming `TYPESAFE_API_KEY`, exit 1.
- HTTP error → status code + response body shown, exit 1 (429/529 retried
  twice with backoff).
- No silent fallback to local model inference.

## Layout

Canonical skill lives in `~/.config/agent-skills/jev-plan-check/`. Symlinks:
`~/.pi/agent/skills/jev-plan-check` and `~/.claude/skills/jev-plan-check`
point at the canonical directory.