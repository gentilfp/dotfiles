#!/usr/bin/env bash
#
# jev-plan-check — evaluate whether an implementation plan is sufficiently
# complete for a given task, using TypeSafe's Jev System One model.
#
# Uses the TypeSafe HTTP API directly (no SDK, no local inference, no fallback):
#   POST https://api.typesafe.ai/v1/systemone
#   model: jev-latest
#   Authorization: Bearer $TYPESAFE_API_KEY
#
# The full TASK and PLAN are sent together as the TypeSafe `state`:
#   { "task": <TASK>, "plan": <PLAN> }
#
# Inputs (first match wins):
#   1. positionals:  jev-plan-check [--raw] "<TASK>" "<PLAN>"
#   2. env:            TASK="..." PLAN="..." jev-plan-check [--raw]
#   3. stdin JSON:    echo '{"task":"...","plan":"..."}' | jev-plan-check [--raw]
#
# Output: concise human-readable report with the six Jev values, a Flags
# section (only dimensions crossing a concerning threshold), and a
# deterministic verdict: READY | NEEDS REVIEW | INCOMPLETE.
# With --raw (or RAW=1), the raw API response JSON is printed first.
#
# The verdict is computed deterministically from the returned Jev values by
# the script below — no language model is asked to judge the result, and Jev
# is never asked to generate prose.

set -euo pipefail

API_URL="https://api.typesafe.ai/v1/systemone"
API_MODEL="jev-latest"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────────────────────────────────────────
# Verdict thresholds — edit here. Scores use a 0..4 rubric (5 ordered levels,
# 0 = worst, 4 = best) and may land on fractional values (probability-weighted
# position across levels). Nouls are probabilities 0..1.
# ─────────────────────────────────────────────────────────────────────────────
COMPLETENESS_MIN=3.0        # completeness score BELOW this  → flagged → NEEDS REVIEW
COMPLETENESS_INCOMPLETE=2.0 # completeness score BELOW this  → INCOMPLETE
MIGRATION_RISK_ALERT=2.0    # migration risk score <= this   → flagged → NEEDS REVIEW (higher score = lower risk)
MIGRATION_RISK_MAX=1.0      # migration risk score <= this   → INCOMPLETE (higher score = lower risk)
EDGE_CASES_ALERT=0.35       # missing_edge_cases noul > this → flagged → NEEDS REVIEW
EDGE_CASES_MAX=0.70         # missing_edge_cases noul >= this→ INCOMPLETE
TESTS_ADEQUATE_MIN=0.40     # tests_adequate noul < this     → flagged → NEEDS REVIEW
ROLLBACK_MIN=0.40           # rollback_covered noul < this   → flagged → NEEDS REVIEW
SCOPE_CREEP_ALERT=0.60      # scope_creep noul > this        → flagged → NEEDS REVIEW
# ─────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: jev-plan-check [--raw] "<TASK>" "<PLAN>"
   or: TASK="<TASK>" PLAN="<PLAN>" jev-plan-check [--raw]
   or: echo '{"task":"<TASK>","plan":"<PLAN>"}' | jev-plan-check [--raw]

Evaluates an implementation PLAN against a TASK using TypeSafe Jev
(POST https://api.typesafe.ai/v1/systemone, model jev-latest).

Required environment variable:
  TYPESAFE_API_KEY   TypeSafe API key (Bearer token).

Options:
  --raw              Also print the raw API response JSON before the report.
  -h, --help         Show this help.

Verdict (deterministic from the Jev values; migration risk score is on a
0..4 scale where HIGHER = LOWER risk):
  INCOMPLETE    if completeness < 2.0  OR  missing_edge_cases >= 0.70
                OR migration_risk <= 1.0
  NEEDS REVIEW  else if completeness < 3.0  OR missing_edge_cases > 0.35
                OR migration_risk <= 2.0  OR tests_adequate < 0.40
                OR rollback_covered < 0.40  OR scope_creep > 0.60
  READY         otherwise
EOF
}

# --- flags & help ------------------------------------------------------------
RAW=0
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --raw | RAW=1) RAW=1 ;;
    -h | --help) usage; exit 0 ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done

# --- inputs ------------------------------------------------------------------
TASK="${TASK:-}"
PLAN="${PLAN:-}"
if [ "${#POSITIONAL[@]}" -ge 2 ]; then
  TASK="${POSITIONAL[0]}"
  PLAN="${POSITIONAL[1]}"
elif [ -z "$TASK" ] || [ -z "$PLAN" ]; then
  if [ ! -t 0 ]; then
    read -r -d '' stdin_json || true
    if [ -n "$stdin_json" ]; then
      parsed="$(printf '%s' "$stdin_json" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("task","")); print(d.get("plan",""))' 2>/dev/null || true)"
      if [ -n "$parsed" ]; then
        TASK="$(printf '%s\n' "$parsed" | sed -n '1p')"
        PLAN="$(printf '%s\n' "$parsed" | sed -n '2p')"
      fi
    fi
  fi
fi

if [ -z "$TASK" ] || [ -z "$PLAN" ]; then
  echo "Error: TASK and PLAN are required." >&2
  echo >&2
  usage >&2
  exit 2
fi

# --- API key -----------------------------------------------------------------
if [ -z "${TYPESAFE_API_KEY:-}" ]; then
  echo "Error: TYPESAFE_API_KEY is not set." >&2
  echo "jev-plan-check calls $API_URL and requires the TypeSafe API key in the" >&2
  echo "TYPESAFE_API_KEY environment variable, e.g.:" >&2
  echo '  export TYPESAFE_API_KEY="ts_..."' >&2
  echo "No local inference fallback is performed; the check is aborted." >&2
  exit 1
fi

# --- build request body (python keeps JSON escaping safe) ----------------------
payload="$(TASK="$TASK" PLAN="$PLAN" python3 - <<'PY'
import json, os

payload = {
    "state": {"task": os.environ["TASK"], "plan": os.environ["PLAN"]},
    "model": "jev-latest",
    "questions": {
        "completeness": {
            "type": "score",
            "instructions": (
                "How completely does the plan in `state.plan` address the requirements "
                "of the task in `state.task`? Rate coverage of the task's stated "
                "requirements, from omitting whole requirements to fully explicit "
                "coverage of everything required."
            ),
            "criteria": [
                "The plan omits entire major requirements of the task, or is mostly placeholders/TBD.",
                "The plan addresses some requirements but has large gaps: significant required work is missing or underspecified.",
                "The plan covers most requirements with minor gaps or underspecified details.",
                "The plan addresses essentially all stated requirements with concrete, specific steps.",
                "The plan fully and explicitly covers every stated requirement with concrete steps, deliverables, and entry/exit criteria.",
            ],
        },
        "missing_edge_cases": {
            "type": "noul",
            "instructions": (
                "Do important edge cases appear to be missing from the implementation "
                "plan in `state.plan` for the task in `state.task`? Consider: empty/"
                "absent input, error paths, failure modes, invalid states, concurrency, "
                "unusual user input, boundary conditions, and environment-specific "
                "cases relevant to the task."
            ),
            "criteria": {
                "true": "Important edge cases are likely missing from the plan.",
                "false": "No important edge cases appear to be missing; edge cases are covered or not applicable.",
            },
        },
        "migration_risk": {
            "type": "score",
            "instructions": (
                "How much implementation/migration risk does the plan in `state.plan` "
                "introduce for the task in `state.task`? Consider data migrations, "
                "schema changes, backward compatibility, rollout risk, destructive "
                "operations, and behavior changes where applicable."
            ),
            "criteria": [
                "Severe risk: destructive operations without safeguards, breaking changes with no migration path, high data-loss or outage exposure.",
                "Substantial risk: notable schema/data changes or risky rollout steps with limited safeguards.",
                "Moderate risk: some schema or behavior changes, but with identified mitigations and a defined rollout.",
                "Low risk: minor, reversible changes behind a standard, well-understood rollout.",
                "No material risk: no data/schema changes, no behavior changes, trivially reversible.",
            ],
        },
        "tests_adequate": {
            "type": "noul",
            "instructions": (
                "Do the tests proposed in the plan in `state.plan` appear adequate for "
                "the task in `state.task`? Consider coverage of the main behavior, key "
                "edge cases, and (where relevant) migration and rollback verification. "
                "If the plan proposes no tests at all, that is a 'no'."
            ),
            "criteria": {
                "true": "The proposed tests appear adequate for the task.",
                "false": "Tests are missing, absent, or clearly inadequate for the task.",
            },
        },
        "rollback_covered": {
            "type": "noul",
            "instructions": (
                "Is rollback, recovery, or safe failure handling adequately covered in "
                "the plan in `state.plan` when relevant? If rollback is genuinely "
                "irrelevant to the task (for example purely additive code with no "
                "persistent state or external contract), treat it as adequately covered "
                "rather than penalizing the plan."
            ),
            "criteria": {
                "true": "Rollback/recovery is adequately covered, or is genuinely irrelevant to this task.",
                "false": "Rollback/recovery is relevant but not adequately covered in the plan.",
            },
        },
        "scope_creep": {
            "type": "noul",
            "instructions": (
                "Does the plan in `state.plan` appear to introduce work outside the "
                "scope of the original task in `state.task`? Consider unrelated "
                "refactors, gratuitous new features, or substantially expanded "
                "deliverables."
            ),
            "criteria": {
                "true": "The plan appears to introduce work outside the task's scope.",
                "false": "The plan stays within the task's scope.",
            },
        },
    },
}

print(json.dumps(payload))
PY
)"

# --- call the TypeSafe API (retry 429/529 with backoff; never fall back) -------
resp_body="$(mktemp)"
err_file="$(mktemp)"
http_code=""
for attempt in 1 2 3; do
  set +e
  http_code="$(curl -sS -o "$resp_body" -w '%{http_code}' --max-time 120 \
    -X POST "$API_URL" \
    -H "Authorization: Bearer $TYPESAFE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>"$err_file")"
  curl_rc=$?
  set -e
  if [ "$curl_rc" -ne 0 ]; then
    echo "Error: request to TypeSafe API failed: $(tr -d '\n' <"$err_file")" >&2
    rm -f "$resp_body" "$err_file"
    exit 1
  fi
  if [ "$http_code" = "429" ] || [ "$http_code" = "529" ]; then
    if [ "$attempt" -lt 3 ]; then
      sleep "$((2 * 2 ** (attempt - 1)))" # 2s, 4s
      continue
    fi
  fi
  break
done

if [ "$http_code" != "200" ]; then
  echo "TypeSafe API error (HTTP $http_code):" >&2
  sed 's/^/  /' "$resp_body" >&2
  rm -f "$resp_body" "$err_file"
  exit 1
fi

# --- render report (deterministic from the Jev answers) ------------------------
RAW="$RAW" \
COMPLETENESS_MIN="$COMPLETENESS_MIN" COMPLETENESS_INCOMPLETE="$COMPLETENESS_INCOMPLETE" \
MIGRATION_RISK_ALERT="$MIGRATION_RISK_ALERT" MIGRATION_RISK_MAX="$MIGRATION_RISK_MAX" \
EDGE_CASES_ALERT="$EDGE_CASES_ALERT" EDGE_CASES_MAX="$EDGE_CASES_MAX" \
TESTS_ADEQUATE_MIN="$TESTS_ADEQUATE_MIN" ROLLBACK_MIN="$ROLLBACK_MIN" \
SCOPE_CREEP_ALERT="$SCOPE_CREEP_ALERT" \
python3 - "$resp_body" <<'PY'
import json
import os
import sys

body = json.load(open(sys.argv[1]))
answers = body.get("answers", {})
model = body.get("model", "?")
usage = body.get("usage", {})

if os.environ.get("RAW") == "1":
    print(json.dumps(body, indent=2))
    print()

def value(name):
    return answers.get(name, {})

def fnum(x):
    return f"{x:.2f}"

completeness = value("completeness").get("score")
missing_edge = value("missing_edge_cases").get("noul")
migration = value("migration_risk").get("score")
tests_ok = value("tests_adequate").get("noul")
rollback = value("rollback_covered").get("noul")
scope = value("scope_creep").get("noul")

# thresholds (mirrored from the bash block at the top of evaluate_plan.sh)
C_MIN = float(os.environ.get("COMPLETENESS_MIN", "3.0"))
C_BAD = float(os.environ.get("COMPLETENESS_INCOMPLETE", "2.0"))
M_ALERT = float(os.environ.get("MIGRATION_RISK_ALERT", "2.0"))  # score <= this → flagged (higher score = lower risk)
M_BAD = float(os.environ.get("MIGRATION_RISK_MAX", "1.0"))     # score <= this → INCOMPLETE
E_ALERT = float(os.environ.get("EDGE_CASES_ALERT", "0.35"))
E_BAD = float(os.environ.get("EDGE_CASES_MAX", "0.70"))
T_MIN = float(os.environ.get("TESTS_ADEQUATE_MIN", "0.40"))
R_MIN = float(os.environ.get("ROLLBACK_MIN", "0.40"))
S_ALERT = float(os.environ.get("SCOPE_CREEP_ALERT", "0.60"))

sc = value("completeness")
mr = value("migration_risk")
legend_completeness = sc.get("legend", {})
legend_migration = mr.get("legend", {})

print("Plan check — TypeSafe Jev (%s)" % model)
print("=" * 60)
print(f"completeness          {fnum(completeness)} / 4.00   (higher is better)")
print(f"missing edge cases    {fnum(missing_edge)}        (probability edge cases are missing; lower is better)")
print(f"migration risk        {fnum(migration)} / 4.00   (lower is better)")
print(f"tests adequate        {fnum(tests_ok)}        (probability tests are adequate; higher is better)")
print(f"rollback covered      {fnum(rollback)}        (probability rollback/recovery is covered; higher is better)")
print(f"scope creep           {fnum(scope)}        (probability of out-of-scope work; lower is better)")
print()
print("Score legends (levels, 0 = worst .. 4 = best):")
if legend_completeness:
    print("  completeness: " + " | ".join(f"[{k}] {v}" for k, v in sorted(legend_completeness.items(), key=lambda kv: int(kv[0]))))
if legend_migration:
    print("  migration:    " + " | ".join(f"[{k}] {v}" for k, v in sorted(legend_migration.items(), key=lambda kv: int(kv[0]))))
print()

# flags — only dimensions crossing a concerning threshold
flags = []
if completeness < C_MIN:
    flags.append(f"completeness {fnum(completeness)}/4.00 below {C_MIN:.2f} min")
if missing_edge > E_ALERT:
    flags.append(f"missing_edge_cases {fnum(missing_edge)} above {E_ALERT:.2f} alert")
if migration <= M_ALERT:
    flags.append(f"migration_risk {fnum(migration)}/4.00 at/below {M_ALERT:.2f} alert (lower score = higher risk)")
if tests_ok < T_MIN:
    flags.append(f"tests_adequate {fnum(tests_ok)} below {T_MIN:.2f} min")
if rollback < R_MIN:
    flags.append(f"rollback_covered {fnum(rollback)} below {R_MIN:.2f} min")
if scope > S_ALERT:
    flags.append(f"scope_creep {fnum(scope)} above {S_ALERT:.2f} alert")

print("Flags:")
if flags:
    for f in flags:
        print(f"  - {f}")
else:
    print("  - none")
print()

# deterministic verdict derived only from the Jev values above
if completeness < C_BAD or missing_edge >= E_BAD or migration <= M_BAD:
    verdict = "INCOMPLETE"
elif (completeness < C_MIN or missing_edge > E_ALERT or migration <= M_ALERT
      or tests_ok < T_MIN or rollback < R_MIN or scope > S_ALERT):
    verdict = "NEEDS REVIEW"
else:
    verdict = "READY"

print("Verdict:", verdict)
print("-" * 60)
print(f"tokens: {usage.get('input_tokens','?')} in / {usage.get('output_tokens','?')} out")
PY

rm -f "$resp_body" "$err_file"
exit 0