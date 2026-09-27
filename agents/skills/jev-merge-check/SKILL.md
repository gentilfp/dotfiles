---
name: jev-merge-check
description: >
  Evaluate how confidently a pull request can be merged. Sends the change (and
  optional surrounding context) to TypeSafe's Jev System One model
  (POST https://api.typesafe.ai/v1/systemone, model jev-latest, API key from
  TYPESAFE_API_KEY) and returns six structured judgments — workflow impact,
  breaking integration, additive change, blast radius, tests cover change,
  reversibility — plus a deterministic CONFIDENT / REVIEW NEEDED / HIGH RISK
  verdict, a change-type line, and a compact Flags section. No prose
  generation, no second LLM. Use when the user has a PR, branch, or diff and
  wants to know whether merging it is safe: does it affect existing workflows,
  is it new surface, could it break an integration.
---

# jev-merge-check

Judges merge confidence for a change using TypeSafe Jev, a System One model
that returns typed judgments and probabilities — not prose. The verdict is
derived deterministically from the returned values by the bundled script; Jev
is never asked to generate text and no other language model reinterprets the
results.

Sibling skill: `jev-plan-check` does the same for an implementation plan
*before* coding. This one runs on the diff *before* merging.

## Parameters

| Parameter | Meaning |
| --- | --- |
| `CHANGE` | The pull request: title, description, and diff. Required. |
| `CONTEXT` | Optional. The workflows, consumers, integrations, or invariants the change lands in — what an experienced reviewer would already know. Omit to judge from the change alone. |

Both are sent together as the TypeSafe `state`:

```json
{ "state": { "change": "<CHANGE>", "context": "<CONTEXT>" } }
```

`CONTEXT` is what makes "does it affect an existing workflow" answerable with
precision. A diff alone shows what changed; the context tells Jev who depends
on it. Supply it whenever you know the consumers.

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
# form 1: a PR number, fetched with gh from the current repo
…/jev-merge-check/evaluate_merge.sh --pr 1234

# form 2: positional arguments
…/jev-merge-check/evaluate_merge.sh "<CHANGE>" "<CONTEXT>"

# form 3: environment variables
CHANGE="<CHANGE>" CONTEXT="<CONTEXT>" …/jev-merge-check/evaluate_merge.sh

# form 4: stdin JSON
echo '{"change":"<CHANGE>","context":"<CONTEXT>"}' | …/jev-merge-check/evaluate_merge.sh
```

`--pr <n>` runs `gh pr view` + `gh pr diff` and uses the result as `CHANGE`;
pass `CONTEXT` alongside it via the environment variable if you have it.

Add `--raw` (or set `RAW=1`) to also print the raw API response JSON before
the formatted report.

## Evaluated dimensions

| Dimension | Type | Meaning |
| --- | --- | --- |
| `workflow_impact` | score (0–4) | How much the change disturbs workflows that already exist and already work. Higher = existing workflows less disturbed. |
| `breaking_integration` | noul (0–1) | Probability an existing contract breaks: API shapes, DB schema, event payloads, public signatures, config, CLI flags, third-party contracts. |
| `additive_change` | noul (0–1) | Probability the change is essentially new surface rather than a modification of existing behavior. Informational — reported as the change type, never flagged. |
| `blast_radius` | score (0–4) | How far the damage spreads if the change is wrong. Higher = more contained. |
| `tests_cover_change` | noul (0–1) | Probability the changed behavior is actually exercised by tests. |
| `reversibility` | noul (0–1) | Probability a revert after merge safely restores the previous state. |

Each score question carries an explicit 5-level rubric (0 = worst … 4 = best)
as its `criteria`; the API returns the probability-weighted score plus the
`legend`, which the report echoes so values stay interpretable.

## Verdict thresholds

Deterministic — computed by `evaluate_merge.sh` from the Jev values only.
Scores are 0–4 and may be fractional; nouls are 0–1.

**HIGH RISK** — any of:

- `workflow_impact` < 1.5 (lower score = more disruption)
- `breaking_integration` ≥ 0.70
- `blast_radius` ≤ 1.0 (lower score = wider damage)

**REVIEW NEEDED** — otherwise, any of:

- `workflow_impact` < 3.0
- `breaking_integration` > 0.30
- `blast_radius` ≤ 2.0
- `tests_cover_change` < 0.40
- `reversibility` < 0.40

**CONFIDENT** — otherwise.

**Severity cap.** A HIGH RISK verdict is downgraded to REVIEW NEEDED when
`reversibility` ≥ 0.85 **and** `breaking_integration` < 0.70 — a change you can
safely revert is not high risk on severity alone. A broken contract is the
exception and is never capped: consumers observe it before you can revert. When
the cap applies, the report prints the reason under the verdict.

`additive_change` never affects the verdict. It is reported on its own line as
**mostly NEW SURFACE** (≥ 0.60) or **MODIFIES EXISTING behavior** (< 0.60), so
a purely additive PR is visibly distinguished from one that rewires something.

The **Flags** section lists only the dimensions that crossed their concerning
threshold (the REVIEW NEEDED conditions). To tune, edit the threshold block at
the top of `evaluate_merge.sh` (values also documented in `README.md`).

## Error handling

- `TYPESAFE_API_KEY` missing → script exits 1 with a message naming the variable.
- `--pr` without `gh` on PATH, or an unreadable PR → exits 1 with a message.
- HTTP/transport error → script prints the status code and response body
  succinctly and exits 1. `429`/`529` are retried twice with backoff.
- No silent fallback to local inference, ever.

## Agent instructions

1. Gather `CHANGE` — `--pr <n>` when a PR number is given and `gh` works,
   otherwise the diff from `git diff`/`gh pr diff` plus the PR title and body.
2. Gather `CONTEXT` when you can: which consumers, jobs, or integrations touch
   the changed code. A short factual paragraph is enough; do not invent it.
3. Run `evaluate_merge.sh` with those inputs.
4. Report back the formatted output: six values, change type, Flags, Verdict.
5. Do not call another model to rewrite or summarize the verdict — the script
   output is the final answer. Use `--raw` only when the user asks for it.
6. This is a confidence signal, not an approval. It does not replace reading
   the diff, and it never merges anything on its own.
