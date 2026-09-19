---
name: jev-plan-check
description: >
  Evaluate whether an implementation plan is sufficiently complete for a given
  task/ticket. Sends the task and plan to TypeSafe's Jev System One model
  (POST https://api.typesafe.ai/v1/systemone, model jev-latest, API key from
  TYPESAFE_API_KEY) and returns six structured judgments — completeness score,
  missing edge cases, migration risk, tests adequate, rollback covered, scope
  creep — plus a deterministic READY / NEEDS REVIEW / INCOMPLETE verdict and a
  compact Flags section. No prose generation, no second LLM. Use when the user
  provides a TASK (ticket/issue/requirement) and an implementation PLAN to
  vet before coding or merging.
---

# jev-plan-check

Evaluates an implementation plan against a task using TypeSafe Jev, a System
One model that returns typed judgments and probabilities — not prose. The
verdict is derived deterministically from the returned values by the bundled
script; Jev is never asked to generate text and no other language model
reinterprets the results.

## Parameters

| Parameter | Meaning |
| --- | --- |
| `TASK` | The original task, ticket, issue, or requirement. |
| `PLAN` | The implementation plan to evaluate. |

The full `TASK` and `PLAN` are sent together as the TypeSafe `state`:

```json
{ "state": { "task": "<TASK>", "plan": "<PLAN>" } }
```

## Required environment variable

| Variable | Purpose |
| --- | --- |
| `TYPESAFE_API_KEY` | TypeSafe API key, sent as `Authorization: Bearer <key>`. If missing, the check fails with a clear error — there is no local-model fallback. |

## Endpoint and model

- `POST https://api.typesafe.ai/v1/systemone`
- model: `jev-latest`

## Invocation

Run the bundled script from this skill directory. Any of these forms work
(first match wins):

```bash
# form 1: positional arguments
…/jev-plan-check/evaluate_plan.sh "<TASK>" "<PLAN>"

# form 2: environment variables
TASK="<TASK>" PLAN="<PLAN>" …/jev-plan-check/evaluate_plan.sh

# form 3: stdin JSON
echo '{"task":"<TASK>","plan":"<PLAN>"}' | …/jev-plan-check/evaluate_plan.sh
```

Add `--raw` (or set `RAW=1`) to also print the raw API response JSON before
the formatted report.

## Evaluated dimensions

| Dimension | Type | Meaning |
| --- | --- | --- |
| `completeness` | score (0–4) | How completely the plan addresses the task's requirements. |
| `missing_edge_cases` | noul (0–1) | Probability important edge cases are missing from the plan. |
| `migration_risk` | score (0–4) | Implementation/migration risk: data migrations, schema changes, compatibility, rollout, destructive operations, behavior changes. Higher score = lower risk. |
| `tests_adequate` | noul (0–1) | Probability the proposed tests are adequate. |
| `rollback_covered` | noul (0–1) | Probability rollback/recovery/safe-failure is adequately covered when relevant (irrelevant rollback counts as covered). |
| `scope_creep` | noul (0–1) | Probability the plan introduces work outside the task's scope. |

Each score question carries an explicit 5-level rubric (0 = worst … 4 = best)
as its `criteria`; the API returns the probability-weighted score plus the
`legend`, which the report echoes so values stay interpretable.

## Verdict thresholds

Deterministic — computed by `evaluate_plan.sh` from the Jev values only.
Scores are 0–4 and may be fractional; nouls are 0–1.

**INCOMPLETE** — any of:

- `completeness` < 2.0
- `missing_edge_cases` ≥ 0.70
- `migration_risk` ≤ 1.0 (lower score = higher risk)

**NEEDS REVIEW** — otherwise, any of:

- `completeness` < 3.0
- `missing_edge_cases` > 0.35
- `migration_risk` ≤ 2.0 (lower score = higher risk)
- `tests_adequate` < 0.40
- `rollback_covered` < 0.40
- `scope_creep` > 0.60

**READY** — otherwise.

The **Flags** section lists only the dimensions that crossed their concerning
threshold (the NEEDS REVIEW conditions). To tune, edit the threshold block at
the top of `evaluate_plan.sh` (values also documented in `README.md`).

## Error handling

- `TYPESAFE_API_KEY` missing → script exits 1 with a message naming the variable.
- HTTP/transport error → script prints the status code and response body
  succinctly and exits 1. `429`/`529` are retried twice with backoff.
- No silent fallback to local inference, ever.

## Agent instructions

1. Run `evaluate_plan.sh` with the user's TASK and PLAN (pick inputs from the
   forms above; prefer positional args or env vars for long text).
2. Report back the formatted output: six values, Flags, and Verdict.
3. Do not call another model to rewrite or summarize the verdict — the script
   output is the final answer. Use `--raw` only when the user asks for it.