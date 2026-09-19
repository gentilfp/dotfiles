#!/usr/bin/env bash
#
# jev-merge-check — evaluate how confidently a pull request can be merged,
# using TypeSafe's Jev System One model.
#
# Uses the TypeSafe HTTP API directly (no SDK, no local inference, no fallback):
#   POST https://api.typesafe.ai/v1/systemone
#   model: jev-latest
#   Authorization: Bearer $TYPESAFE_API_KEY
#
# The full CHANGE and CONTEXT are sent together as the TypeSafe `state`:
#   { "change": <CHANGE>, "context": <CONTEXT> }
#
# Inputs (first match wins):
#   1. positionals: jev-merge-check [--raw] "<CHANGE>" ["<CONTEXT>"]
#   2. env:           CHANGE="..." CONTEXT="..." jev-merge-check [--raw]
#   3. stdin JSON:   echo '{"change":"...","context":"..."}' | jev-merge-check [--raw]
#   4. --pr <n>:     fetch title/body/diff for PR <n> via `gh` (repo cwd)
#
# CONTEXT is optional; when absent it is sent as an explicit empty string and
# Jev is told to judge from the change alone.
#
# Output: concise report with the six Jev values, a change-type line, a Flags
# section (only dimensions crossing a concerning threshold), and a
# deterministic verdict: CONFIDENT | REVIEW NEEDED | HIGH RISK.
# With --raw (or RAW=1), the raw API response JSON is printed first.
#
# The verdict is computed deterministically from the returned Jev values by
# the script below — no language model is asked to judge the result, and Jev
# is never asked to generate prose.

set -euo pipefail

API_URL="https://api.typesafe.ai/v1/systemone"
API_MODEL="jev-latest"

# ─────────────────────────────────────────────────────────────────────────────
# Verdict thresholds — edit here. Scores use a 0..4 rubric (5 ordered levels,
# 0 = worst, 4 = best) and may land on fractional values (probability-weighted
# position across levels). Nouls are probabilities 0..1.
# ─────────────────────────────────────────────────────────────────────────────
WORKFLOW_IMPACT_ALERT=3.0     # workflow_impact score < this      → flagged → REVIEW NEEDED (higher score = less disruption)
WORKFLOW_IMPACT_MAX=1.5       # workflow_impact score < this      → HIGH RISK
BREAKING_ALERT=0.30           # breaking_integration noul > this  → flagged → REVIEW NEEDED
BREAKING_MAX=0.70             # breaking_integration noul >= this → HIGH RISK
BLAST_RADIUS_ALERT=2.0        # blast_radius score <= this        → flagged → REVIEW NEEDED (higher score = more contained)
BLAST_RADIUS_MAX=1.0          # blast_radius score <= this        → HIGH RISK
TESTS_COVER_MIN=0.40          # tests_cover_change noul < this    → flagged → REVIEW NEEDED
REVERSIBILITY_MIN=0.40        # reversibility noul < this         → flagged → REVIEW NEEDED
ADDITIVE_NEW_SURFACE=0.60     # additive_change noul >= this      → reported as "new surface" (informational, never a flag)
REVERSIBLE_ESCAPE=0.85        # reversibility noul >= this        → HIGH RISK is capped at REVIEW NEEDED, unless a contract breaks
# ─────────────────────────────────────────────────────────────────────────────

usage() {
  cat <<'EOF'
Usage: jev-merge-check [--raw] "<CHANGE>" ["<CONTEXT>"]
   or: CHANGE="<CHANGE>" CONTEXT="<CONTEXT>" jev-merge-check [--raw]
   or: echo '{"change":"...","context":"..."}' | jev-merge-check [--raw]
   or: jev-merge-check --pr <number> [--raw]      (uses `gh` in the current repo)

Evaluates how confidently a pull request can be merged, using TypeSafe Jev
(POST https://api.typesafe.ai/v1/systemone, model jev-latest).

  CHANGE    the pull request: title, description, and diff.
  CONTEXT   optional — the workflows, consumers, integrations, or invariants
            the change lands in. Omit to judge from the change alone.

Required environment variable:
  TYPESAFE_API_KEY   TypeSafe API key (Bearer token).

Options:
  --pr <number>      Fetch the PR's title, body and diff with `gh` as CHANGE.
  --raw              Also print the raw API response JSON before the report.
  -h, --help         Show this help.

Verdict (deterministic from the Jev values; workflow_impact and blast_radius
are 0..4 scores where HIGHER = SAFER):
  HIGH RISK      if workflow_impact < 1.5  OR  breaking_integration >= 0.70
                 OR blast_radius <= 1.0
  REVIEW NEEDED  else if workflow_impact < 3.0  OR breaking_integration > 0.30
                 OR blast_radius <= 2.0  OR tests_cover_change < 0.40
                 OR reversibility < 0.40
  CONFIDENT      otherwise
EOF
}

# --- flags & help ------------------------------------------------------------
RAW=0
PR_NUMBER=""
POSITIONAL=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --raw | RAW=1) RAW=1 ;;
    --pr)
      shift
      PR_NUMBER="${1:-}"
      if [ -z "$PR_NUMBER" ]; then
        echo "Error: --pr requires a pull request number." >&2
        exit 2
      fi
      ;;
    --pr=*) PR_NUMBER="${1#--pr=}" ;;
    -h | --help) usage; exit 0 ;;
    *) POSITIONAL+=("$1") ;;
  esac
  shift
done

# --- inputs ------------------------------------------------------------------
CHANGE="${CHANGE:-}"
CONTEXT="${CONTEXT:-}"

if [ -n "$PR_NUMBER" ]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: --pr requires the GitHub CLI (gh) on PATH." >&2
    exit 1
  fi
  pr_meta="$(gh pr view "$PR_NUMBER" --json title,body \
    --template '{{.title}}{{"\n\n"}}{{.body}}' 2>/dev/null || true)"
  pr_diff="$(gh pr diff "$PR_NUMBER" 2>/dev/null || true)"
  if [ -z "$pr_meta" ] && [ -z "$pr_diff" ]; then
    echo "Error: could not read PR #$PR_NUMBER with gh (wrong repo, or not authenticated?)." >&2
    exit 1
  fi
  CHANGE="$pr_meta

--- diff ---
$pr_diff"
elif [ "${#POSITIONAL[@]}" -ge 1 ]; then
  CHANGE="${POSITIONAL[0]}"
  if [ "${#POSITIONAL[@]}" -ge 2 ]; then
    CONTEXT="${POSITIONAL[1]}"
  fi
elif [ -z "$CHANGE" ]; then
  if [ ! -t 0 ]; then
    stdin_json="$(cat)"
    if [ -n "$stdin_json" ]; then
      # base64 each field on its own line: command substitution strips NULs,
      # and change/context may contain arbitrary newlines and quotes.
      if ! parsed="$(printf '%s' "$stdin_json" | python3 -c 'import base64, json, sys
try:
    d = json.loads(sys.stdin.read())
except json.JSONDecodeError as e:
    sys.exit("stdin is not valid JSON: %s" % e)
if not isinstance(d, dict):
    sys.exit("stdin JSON must be an object with a \"change\" key")
for key in ("change", "context"):
    raw = str(d.get(key, "")).encode()
    print(base64.b64encode(raw).decode())')"; then
        echo "Error: could not read CHANGE/CONTEXT from stdin." >&2
        exit 2
      fi
      CHANGE="$(printf '%s\n' "$parsed" | sed -n '1p' | base64 --decode)"
      CONTEXT="$(printf '%s\n' "$parsed" | sed -n '2p' | base64 --decode)"
    fi
  fi
fi

if [ -z "$CHANGE" ]; then
  echo "Error: CHANGE is required." >&2
  echo >&2
  usage >&2
  exit 2
fi

# --- API key -----------------------------------------------------------------
if [ -z "${TYPESAFE_API_KEY:-}" ]; then
  echo "Error: TYPESAFE_API_KEY is not set." >&2
  echo "jev-merge-check calls $API_URL and requires the TypeSafe API key in the" >&2
  echo "TYPESAFE_API_KEY environment variable, e.g.:" >&2
  echo '  export TYPESAFE_API_KEY="ts_..."' >&2
  echo "No local inference fallback is performed; the check is aborted." >&2
  exit 1
fi

# --- build request body (python keeps JSON escaping safe) ----------------------
payload="$(CHANGE="$CHANGE" CONTEXT="$CONTEXT" API_MODEL="$API_MODEL" python3 - <<'PY'
import json, os

payload = {
    "state": {"change": os.environ["CHANGE"], "context": os.environ.get("CONTEXT", "")},
    "model": os.environ["API_MODEL"],
    "questions": {
        "workflow_impact": {
            "type": "score",
            "instructions": (
                "How much does the change in `state.change` disturb workflows that "
                "already exist and already work? `state.context` describes the system "
                "the change lands in; if it is empty, judge from the change alone. "
                "Consider altered behavior on existing code paths, changed defaults or "
                "configuration, modified shared utilities, and anything an existing "
                "user or caller would notice. Higher = existing workflows are left "
                "untouched."
            ),
            "criteria": [
                "Severe: rewrites or removes behavior that existing workflows depend on, with no compatibility path.",
                "Substantial: changes behavior on several existing paths, or alters widely used shared code or defaults.",
                "Moderate: changes behavior on a few existing paths, in ways existing callers could notice.",
                "Slight: touches existing code but preserves its observable behavior (refactor, internal cleanup, guarded change).",
                "None: existing workflows are untouched — the change is isolated or purely additive.",
            ],
        },
        "breaking_integration": {
            "type": "noul",
            "instructions": (
                "Could the change in `state.change` break an integration or contract "
                "that something outside it relies on? Consider API request/response "
                "shapes, database schemas and stored data shapes, event or message "
                "payloads, public function and module signatures, configuration and "
                "environment variables, CLI flags, and third-party service contracts. "
                "`state.context` names known consumers when available."
            ),
            "criteria": {
                "true": "The change plausibly breaks an existing contract or integration.",
                "false": "No existing contract or integration is broken; changes are compatible or internal only.",
            },
        },
        "additive_change": {
            "type": "noul",
            "instructions": (
                "Is the change in `state.change` essentially new surface rather than a "
                "modification of existing behavior? New files, new endpoints, new "
                "feature behind a flag, or code nothing existing calls yet counts as "
                "new surface. Rewiring, editing, or deleting existing behavior does not."
            ),
            "criteria": {
                "true": "The change is essentially new, isolated surface.",
                "false": "The change modifies, rewires, or removes existing behavior.",
            },
        },
        "blast_radius": {
            "type": "score",
            "instructions": (
                "If the change in `state.change` is wrong, how far does the damage "
                "spread? Consider how many components, users, or tenants are exposed, "
                "whether persistent data is written or migrated, whether failure is "
                "silent, and whether the affected path is on a critical flow such as "
                "authentication, billing, or data integrity. Higher = more contained."
            ),
            "criteria": [
                "Unbounded: a defect corrupts persistent data, or breaks a critical flow for all users, possibly silently.",
                "Wide: a defect affects many users or several components, or writes bad persistent data that is hard to undo.",
                "Moderate: a defect affects one significant component or a subset of users, and is noticeable.",
                "Narrow: a defect affects one non-critical path, is loud, and is easy to correct.",
                "Contained: a defect affects nothing in production — dead code, docs, tests, or a flag that is off.",
            ],
        },
        "tests_cover_change": {
            "type": "noul",
            "instructions": (
                "Does the change in `state.change` come with tests that actually "
                "exercise the behavior it changes? Consider whether new or updated "
                "tests cover the modified paths and their failure modes. A change to "
                "behavior with no accompanying test is a 'no'; a change that needs no "
                "test (documentation, comments, formatting) counts as covered."
            ),
            "criteria": {
                "true": "The changed behavior is covered by tests, or genuinely needs none.",
                "false": "The changed behavior is not covered by tests that exercise it.",
            },
        },
        "reversibility": {
            "type": "noul",
            "instructions": (
                "Can this change be safely reverted after merging? A plain code revert "
                "counts as reversible. Irreversible or costly-to-reverse work includes "
                "destructive or one-way data migrations, dropped columns, published "
                "package releases, external side effects already sent, and changes "
                "whose revert would itself break data written while it was live."
            ),
            "criteria": {
                "true": "Reverting the merge restores the previous state safely.",
                "false": "Reverting is unsafe, incomplete, or would leave broken state behind.",
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
WORKFLOW_IMPACT_ALERT="$WORKFLOW_IMPACT_ALERT" WORKFLOW_IMPACT_MAX="$WORKFLOW_IMPACT_MAX" \
BREAKING_ALERT="$BREAKING_ALERT" BREAKING_MAX="$BREAKING_MAX" \
BLAST_RADIUS_ALERT="$BLAST_RADIUS_ALERT" BLAST_RADIUS_MAX="$BLAST_RADIUS_MAX" \
TESTS_COVER_MIN="$TESTS_COVER_MIN" REVERSIBILITY_MIN="$REVERSIBILITY_MIN" \
ADDITIVE_NEW_SURFACE="$ADDITIVE_NEW_SURFACE" REVERSIBLE_ESCAPE="$REVERSIBLE_ESCAPE" \
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

workflow = value("workflow_impact").get("score")
breaking = value("breaking_integration").get("noul")
additive = value("additive_change").get("noul")
blast = value("blast_radius").get("score")
tests = value("tests_cover_change").get("noul")
revert = value("reversibility").get("noul")

# thresholds (mirrored from the bash block at the top of evaluate_merge.sh)
W_ALERT = float(os.environ.get("WORKFLOW_IMPACT_ALERT", "3.0"))  # score < this → flagged (higher score = safer)
W_BAD = float(os.environ.get("WORKFLOW_IMPACT_MAX", "1.5"))      # score < this → HIGH RISK
B_ALERT = float(os.environ.get("BREAKING_ALERT", "0.30"))
B_BAD = float(os.environ.get("BREAKING_MAX", "0.70"))
R_ALERT = float(os.environ.get("BLAST_RADIUS_ALERT", "2.0"))     # score <= this → flagged (higher score = safer)
R_BAD = float(os.environ.get("BLAST_RADIUS_MAX", "1.0"))         # score <= this → HIGH RISK
T_MIN = float(os.environ.get("TESTS_COVER_MIN", "0.40"))
V_MIN = float(os.environ.get("REVERSIBILITY_MIN", "0.40"))
A_NEW = float(os.environ.get("ADDITIVE_NEW_SURFACE", "0.60"))
V_ESCAPE = float(os.environ.get("REVERSIBLE_ESCAPE", "0.85"))

legend_workflow = value("workflow_impact").get("legend", {})
legend_blast = value("blast_radius").get("legend", {})

print("Merge check — TypeSafe Jev (%s)" % model)
print("=" * 60)
print(f"workflow impact       {fnum(workflow)} / 4.00   (higher = existing workflows less disturbed)")
print(f"breaking integration  {fnum(breaking)}        (probability an existing contract breaks; lower is better)")
print(f"additive change       {fnum(additive)}        (probability the change is new surface, not a modification)")
print(f"blast radius          {fnum(blast)} / 4.00   (higher = damage more contained if wrong)")
print(f"tests cover change    {fnum(tests)}        (probability the changed behavior is tested; higher is better)")
print(f"reversibility         {fnum(revert)}        (probability a revert is safe; higher is better)")
print()
print("Score legends (levels, 0 = worst .. 4 = best):")
if legend_workflow:
    print("  workflow impact: " + " | ".join(f"[{k}] {v}" for k, v in sorted(legend_workflow.items(), key=lambda kv: int(kv[0]))))
if legend_blast:
    print("  blast radius:    " + " | ".join(f"[{k}] {v}" for k, v in sorted(legend_blast.items(), key=lambda kv: int(kv[0]))))
print()

# change type — informational, never a flag
if additive >= A_NEW:
    print(f"Change type: mostly NEW SURFACE (additive {fnum(additive)} >= {A_NEW:.2f})")
else:
    print(f"Change type: MODIFIES EXISTING behavior (additive {fnum(additive)} < {A_NEW:.2f})")
print()

# flags — only dimensions crossing a concerning threshold
flags = []
if workflow < W_ALERT:
    flags.append(f"workflow_impact {fnum(workflow)}/4.00 below {W_ALERT:.2f} alert (lower score = more disruption)")
if breaking > B_ALERT:
    flags.append(f"breaking_integration {fnum(breaking)} above {B_ALERT:.2f} alert")
if blast <= R_ALERT:
    flags.append(f"blast_radius {fnum(blast)}/4.00 at/below {R_ALERT:.2f} alert (lower score = wider damage)")
if tests < T_MIN:
    flags.append(f"tests_cover_change {fnum(tests)} below {T_MIN:.2f} min")
if revert < V_MIN:
    flags.append(f"reversibility {fnum(revert)} below {V_MIN:.2f} min")

print("Flags:")
if flags:
    for f in flags:
        print(f"  - {f}")
else:
    print("  - none")
print()

# deterministic verdict derived only from the Jev values above
note = ""
if workflow < W_BAD or breaking >= B_BAD or blast <= R_BAD:
    verdict = "HIGH RISK"
    # A change you can safely revert is not high risk on severity alone. A
    # broken contract is the exception: consumers see it before you can revert.
    if revert >= V_ESCAPE and breaking < B_BAD:
        verdict = "REVIEW NEEDED"
        note = (f"severity capped: reversibility {fnum(revert)} >= {V_ESCAPE:.2f} "
                f"and no contract break (breaking_integration {fnum(breaking)} < {B_BAD:.2f})")
elif (workflow < W_ALERT or breaking > B_ALERT or blast <= R_ALERT
      or tests < T_MIN or revert < V_MIN):
    verdict = "REVIEW NEEDED"
else:
    verdict = "CONFIDENT"

print("Verdict:", verdict)
if note:
    print("  (" + note + ")")
print("-" * 60)
print(f"tokens: {usage.get('input_tokens','?')} in / {usage.get('output_tokens','?')} out")
PY

rm -f "$resp_body" "$err_file"
exit 0
