#!/usr/bin/env bash
set -euo pipefail

# run-phase.sh — Execute a single SkillOpt pipeline phase
#
# Usage:
#   run-phase.sh --board <board-slug> --phase <phase-name> [--epoch N] [--exec]
#
# Phases: rollout, reflect, propose, validate, merge, slow-meta
#
# By default, each phase validates its prerequisites and prints the
# exact command the user/agent should run. With --exec, the script
# attempts to execute the phase using hermes -z/--oneshot.

SKILLOPT_DIR="${SKILLOPT_DIR:-$HOME/.hermes/SkillOpt}"
HERMES="${HERMES:-hermes}"
ERROR_LOG="${SKILLOPT_DIR}/hermes-oneshot-errors.log"


# Cosine-decayed edit budget computation.
# The first argument is the number of completed epochs; budget decays from
# initial to floor over max_epochs and is clamped at floor.
compute_budget() {
    local completed_epochs="$1"
    local initial="$2"
    local floor="${3:-2}"
    local max_epochs="${4:-4}"
    python3 - "$completed_epochs" "$initial" "$floor" "$max_epochs" << 'PYEOF'
import math, sys
completed = max(0, int(sys.argv[1]))
initial = max(1, int(sys.argv[2]))
floor = max(1, int(sys.argv[3]))
max_epochs = max(1, int(sys.argv[4]))
t = min(completed, max_epochs) / max_epochs
budget = floor + (initial - floor) * (1 + math.cos(math.pi * t)) / 2
print(max(floor, int(budget)))
PYEOF
}


show_usage() {
    sed -n '3,14p' "$0"
    exit 1
}

run_hermes_prompt() {
    # Current Hermes exposes -z/--oneshot for single-prompt noninteractive runs.
    # Use shlex splitting so HERMES may be either a bare executable path or a
    # command with fixed args, e.g. HERMES='hermes --provider openai-codex -m gpt-5.5'.
    local prompt_file
    prompt_file=$(mktemp)
    printf '%s' "$1" > "$prompt_file"

    local status
    set +e
    HERMES_CMD="$HERMES" PROMPT_FILE="$prompt_file" python3 << 'PYEOF'
import os, shlex, subprocess, sys

hermes_cmd = os.environ.get("HERMES_CMD", "hermes")
prompt_file = os.environ["PROMPT_FILE"]
with open(prompt_file, encoding="utf-8") as f:
    prompt = f.read()
cmd = shlex.split(hermes_cmd) + ["-z", prompt]
completed = subprocess.run(cmd, text=True)
sys.exit(completed.returncode)
PYEOF
    status=$?
    set -e
    rm -f "$prompt_file"
    return "$status"
}

decode_task_field() {
    local encoded="$1"
    local field="$2"
    TASK_B64="$encoded" TASK_FIELD="$field" python3 -c '
import base64, json, os
payload = json.loads(base64.b64decode(os.environ["TASK_B64"]))
print(payload.get(os.environ["TASK_FIELD"], ""))
'
}

BOARD_SLUG=""
PHASE=""
EPOCH=""
EXEC=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --board) BOARD_SLUG="$2"; shift 2 ;;
        --phase) PHASE="$2"; shift 2 ;;
        --epoch) EPOCH="$2"; shift 2 ;;
        --exec) EXEC=true; shift ;;
        --help|-h) show_usage ;;
        *) echo "Unknown option: $1"; show_usage ;;
    esac
done

if [[ -z "$BOARD_SLUG" || -z "$PHASE" ]]; then
    echo "ERROR: --board and --phase are required."
    show_usage
fi

SKILL_NAME="${BOARD_SLUG#skillopt-}"
SKILL_NAME="${SKILL_NAME#SkillOpt-}"
STATE_DIR="$SKILLOPT_DIR/$SKILL_NAME"
METADATA_FILE="$STATE_DIR/board-metadata.json"

if [[ ! -f "$METADATA_FILE" ]]; then
    echo "ERROR: State directory not found for board '$BOARD_SLUG'."
    echo "Expected: $METADATA_FILE"
    echo "Run seed-board.sh first."
    exit 1
fi

METADATA=$(cat "$METADATA_FILE")
TARGET=$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['target'])")
EDIT_BUDGET=$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['edit_budget'])")
EPOCH="${EPOCH:-$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['epoch'])")}"
TEST_SUITE="$STATE_DIR/test-suite.json"

if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: Target skill not found at: $TARGET"
    echo "Has it been moved since seed-board.sh was run?"
    exit 1
fi

echo "=== SkillOpt: Phase '$PHASE' for $SKILL_NAME (epoch $EPOCH) ==="
echo ""

# ============================================================
# Phase: rollout
# ============================================================
run_rollout() {
    local rollout_dir="$STATE_DIR/rollouts"
    mkdir -p "$rollout_dir"

    if [[ ! -f "$TEST_SUITE" ]]; then
        echo "ERROR: No test suite found at $TEST_SUITE"
        exit 1
    fi

    local train_tasks
    train_tasks=$(TEST_SUITE="$TEST_SUITE" python3 << 'PYEOF'
import base64, json, os
with open(os.environ["TEST_SUITE"], encoding="utf-8") as f:
    suite = json.load(f)
for i, task in enumerate(suite.get("training", [])):
    payload = {
        "id": task.get("id", f"train-{i + 1}"),
        "instruction": task.get("instruction", "No instruction"),
    }
    print(base64.b64encode(json.dumps(payload).encode()).decode())
PYEOF
)

    if [[ -z "$train_tasks" ]]; then
        echo "ERROR: No training tasks defined in test suite."
        exit 1
    fi

    local task_count
    task_count=$(printf '%s\n' "$train_tasks" | python3 -c "import sys; print(sum(1 for line in sys.stdin if line.strip()))")

    echo "Rollout phase: execute the skill against each training task"
    echo "Training tasks found: $task_count"
    echo ""

    # Check existing rollouts
    local completed=0
    local pending=0
    while IFS= read -r encoded_task; do
        [[ -z "$encoded_task" ]] && continue
        local task_id
        task_id=$(decode_task_field "$encoded_task" id)
        local output_file="$rollout_dir/epoch-$EPOCH-$task_id.json"
        if [[ -f "$output_file" ]]; then
            completed=$((completed + 1))
        else
            pending=$((pending + 1))
        fi
    done <<< "$train_tasks"

    echo "Completed: $completed / Pending: $pending"
    echo ""

    if [[ "$EXEC" == true ]]; then
        # Execute pending rollouts via hermes -z/--oneshot
        while IFS= read -r encoded_task; do
            [[ -z "$encoded_task" ]] && continue
            local task_id
            local task_desc
            task_id=$(decode_task_field "$encoded_task" id)
            task_desc=$(decode_task_field "$encoded_task" instruction)
            local output_file="$rollout_dir/epoch-$EPOCH-$task_id.json"
            [[ -f "$output_file" ]] && continue

            echo "  Executing rollout: $task_id..."

            local prompt="You are running a controlled skill optimization cycle.
Your task is to execute the following skill document against a specific task.

=== SKILL DOCUMENT PATH ===
${TARGET}

Read the skill document from this path before executing the task. Do not modify the skill file during rollout.

=== TASK ===
${task_desc}

Execute the skill against this task. Record:
1. Your full execution trace (what you did, step by step)
2. The outcome (success or failure, with specific criteria)
3. Any failure modes observed
4. A one-paragraph summary of the output

Output ONLY a JSON object with these fields:
- task_description: string
- execution_trace: string
- outcome: \"success\" or \"failure\"
- failure_modes: array of strings
- output_summary: string"

            local result
            result=$(run_hermes_prompt "$prompt" 2>>"$ERROR_LOG" || echo '{"outcome": "failure", "failure_modes": ["execution error"], "output_summary": "hermes -z command failed"}')

            echo "$result" | TASK_ID="$task_id" EPOCH_VAL="$EPOCH" OUTPUT_FILE="$output_file" python3 -c "
import json, os, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    data = {'outcome': 'failure', 'failure_modes': ['parse error'], 'output_summary': 'Could not parse JSON from response', 'raw_response': raw}
data['task_id'] = os.environ['TASK_ID']
data['epoch'] = int(os.environ['EPOCH_VAL'])
output_file = os.environ['OUTPUT_FILE']
open(output_file, 'w').write(json.dumps(data, indent=2))
print(f'    Wrote: {output_file}')
" 2>/dev/null || echo "    Warning: Could not parse rollout output for $task_id"
        done <<< "$train_tasks"

        # Re-count. Enable nullglob so an unmatched pattern expands to an
        # empty array instead of a literal glob string.
        completed=0
        shopt -s nullglob
        rollout_files=("$rollout_dir/epoch-$EPOCH-"*.json)
        completed=${#rollout_files[@]}
        shopt -u nullglob
        echo ""
        echo "Rollout complete: $completed records written."

        # Copy rollouts to unified pyramid and regenerate root files
        local dossiers_dir="$STATE_DIR/03-dossiers"
        mkdir -p "$dossiers_dir"
        shopt -s nullglob
        for rf in "$rollout_dir"/epoch-"$EPOCH"-*.json; do
            local rbase
            rbase=$(basename "$rf")
            local rdest="$dossiers_dir/$(echo "$rbase" | sed "s/^epoch-${EPOCH}-/epoch-${EPOCH}-rollout-/")"
            cp "$rf" "$rdest"
        done
        shopt -u nullglob
        SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)" PYTHONPATH="$SCRIPTS_DIR:$PYTHONPATH" \
            EPOCH="$EPOCH" STATE_DIR="$STATE_DIR" python3 << 'PYEOF'
import os, sys
import pyramid_utils
state_dir = os.environ["STATE_DIR"]
epoch = os.environ["EPOCH"]
pyramid_utils.update_root_pyramid(state_dir, epoch)
PYEOF

        # --- Write per-epoch rollout pyramid ---
        local rollout_pyramid_dir="$STATE_DIR/rollout/epoch-$EPOCH"
        mkdir -p "$rollout_pyramid_dir/01-summary" "$rollout_pyramid_dir/02-analysis" "$rollout_pyramid_dir/03-dossiers"
        EPOCH="$EPOCH" STATE_DIR="$STATE_DIR" ROLLOUT_DIR="$rollout_dir" \
            ROLLOUT_PYRAMID_DIR="$rollout_pyramid_dir" \
            SCRIPTS_DIR="$SCRIPTS_DIR" PYTHONPATH="$SCRIPTS_DIR:$PYTHONPATH" python3 << 'PYEOF'
import json, os, sys
from datetime import datetime, timezone

state_dir = os.environ["STATE_DIR"]
epoch = os.environ["EPOCH"]
rollout_dir = os.environ["ROLLOUT_DIR"]
pyramid_dir = os.environ["ROLLOUT_PYRAMID_DIR"]
sys.path.insert(0, os.environ.get("SCRIPTS_DIR", os.path.join(state_dir, "scripts")))

# Read all rollout records for this epoch
rollout_records = []
import glob
for f in sorted(glob.glob(os.path.join(rollout_dir, f"epoch-{epoch}-*.json"))):
    with open(f) as fh:
        rollout_records.append(json.load(fh))

total = len(rollout_records)
successes = [r for r in rollout_records if r.get("outcome") == "success"]
failures = [r for r in rollout_records if r.get("outcome") == "failure"]
success_count = len(successes)
failure_count = len(failures)
success_rate = round(success_count / total, 4) if total > 0 else 0.0
created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# 00-index.md
index_lines = [
    f"# Rollout — Epoch {epoch}",
    "",
    "## Navigation",
    "",
    f"- [01-summary/findings.md](01-summary/findings.md) — L1: epoch summary",
    f"- [02-analysis/success-patterns.md](02-analysis/success-patterns.md) — L2: patterns that worked",
    f"- [02-analysis/failure-patterns.md](02-analysis/failure-patterns.md) — L2: failure modes",
    "",
    "## Provenance",
    "",
    f"- epoch: {epoch}",
    f"- total_records: {total}",
    f"- success_count: {success_count}",
    f"- failure_count: {failure_count}",
    f"- success_rate: {success_rate}",
    f"- generated_at: {created}",
]
with open(os.path.join(pyramid_dir, "00-index.md"), "w") as f:
    f.write("\n".join(index_lines) + "\n")

# 01-summary/findings.md
summary_lines = [
    "---",
    f"epoch: {epoch}",
    f"task_count: {total}",
    f"success_count: {success_count}",
    f"failure_count: {failure_count}",
    f"success_rate: {success_rate}",
    "---",
    "",
    f"# Rollout — Epoch {epoch} Summary",
    "",
    f"**Tasks:** {total}  ",
    f"**Passed:** {success_count}  ",
    f"**Failed:** {failure_count}  ",
    f"**Pass rate:** {success_rate:.0%}",
    "",
    "## SOURCES (LAYER 2 NAVIGATION)",
    "",
    "02-analysis/success-patterns.md -> Success patterns across rollout tasks",
    "02-analysis/failure-patterns.md -> Failure modes across rollout tasks",
]
with open(os.path.join(pyramid_dir, "01-summary", "findings.md"), "w") as f:
    f.write("\n".join(summary_lines) + "\n")

# 02-analysis/success-patterns.md
suc_lines = [
    f"# Success Patterns — Epoch {epoch}",
    "",
    f"**{success_count} of {total} tasks passed.**",
    "",
]
if success_count > 0:
    for rec in successes:
        tid = rec.get("task_id", "unknown")
        summary = rec.get("output_summary", "") or rec.get("outcome", "")
        trace = rec.get("execution_trace", "")[:200]
        suc_lines.append(f"### Task: {tid}")
        suc_lines.append("")
        suc_lines.append(f"**Summary:** {summary}")
        if trace:
            suc_lines.append(f"**Trace excerpt:** {trace}")
        suc_lines.append("")
        suc_lines.append("**SOURCES (LAYER 3):**")
        suc_lines.append(f"03-dossiers/{tid}.json -> Full rollout record")
        suc_lines.append("")
else:
    suc_lines.append("_No successful tasks in this epoch._")
suc_lines.append("## SOURCES (LAYER 2 NAVIGATION)")
suc_lines.append("01-summary/findings.md -> Epoch summary")
with open(os.path.join(pyramid_dir, "02-analysis", "success-patterns.md"), "w") as f:
    f.write("\n".join(suc_lines) + "\n")

# 02-analysis/failure-patterns.md
fail_lines = [
    f"# Failure Patterns — Epoch {epoch}",
    "",
    f"**{failure_count} of {total} tasks failed.**",
    "",
]
if failure_count > 0:
    # Group by failure mode
    failure_by_mode = {}
    for rec in failures:
        modes = rec.get("failure_modes", ["unknown"])
        mode_key = "; ".join(modes) if isinstance(modes, list) else str(modes)
        failure_by_mode.setdefault(mode_key, []).append(rec)
    for mode, recs in sorted(failure_by_mode.items()):
        fail_lines.append(f"### Pattern: {mode}")
        fail_lines.append("")
        fail_lines.append(f"Affected {len(recs)} task(s):")
        for rec in recs:
            tid = rec.get("task_id", "unknown")
            fail_lines.append(f"- **{tid}** — {rec.get('output_summary', 'No summary')[:120]}")
        fail_lines.append("")
        fail_lines.append("**SOURCES (LAYER 3):**")
        for rec in recs:
            tid = rec.get("task_id", "unknown")
            fail_lines.append(f"03-dossiers/{tid}.json -> {tid} rollout record")
        fail_lines.append("")
else:
    fail_lines.append("_No failures in this epoch._")
fail_lines.append("## SOURCES (LAYER 2 NAVIGATION)")
fail_lines.append("01-summary/findings.md -> Epoch summary")
with open(os.path.join(pyramid_dir, "02-analysis", "failure-patterns.md"), "w") as f:
    f.write("\n".join(fail_lines) + "\n")

# 03-dossiers/ — copy each rollout JSON by task_id
for rec in rollout_records:
    tid = rec.get("task_id", "unknown")
    dst = os.path.join(pyramid_dir, "03-dossiers", f"{tid}.json")
    with open(dst, "w") as f:
        json.dump(rec, f, indent=2)

print(f"  Rollout pyramid written: {pyramid_dir} ({total} records)")
PYEOF

        echo ""
        echo "Rollout pyramid written to: $rollout_pyramid_dir"
    else
        # Print guidance
        echo "To execute rollouts, run with --exec or run the following for each task:"
        while IFS= read -r encoded_task; do
            [[ -z "$encoded_task" ]] && continue
            local task_id
            local task_desc
            task_id=$(decode_task_field "$encoded_task" id)
            task_desc=$(decode_task_field "$encoded_task" instruction)
            local output_file="$rollout_dir/epoch-$EPOCH-$task_id.json"
            if [[ ! -f "$output_file" ]]; then
                echo ""
                echo "  Task: $task_id"
                echo "  $task_desc"
                echo "  Write result to: $output_file"
            fi
        done <<< "$train_tasks"

        echo ""
        echo "After completing all rollouts, run:"
        echo "  $0 --board $BOARD_SLUG --phase reflect --epoch $EPOCH"
        echo ""
        echo "Output: 03-dossiers/epoch-EPOCH-rollout-*.json"
    fi
}

# ============================================================
# Phase: reflect
# ============================================================
run_reflect() {
    local rollout_dir="$STATE_DIR/rollouts"
    local reflect_dir="$STATE_DIR/reflections"
    mkdir -p "$reflect_dir"

    local rollout_files=()
    # Check unified pyramid first, fall back to old directory
    local rollout_source="$STATE_DIR/03-dossiers"
    shopt -s nullglob
    rollout_files=("$rollout_source"/epoch-"$EPOCH"-rollout-*.json)
    if [[ ${#rollout_files[@]} -eq 0 ]]; then
        rollout_source="$STATE_DIR/rollouts"
        rollout_files=("$rollout_source"/epoch-"$EPOCH"-*.json)
    fi
    shopt -u nullglob
    if [[ ${#rollout_files[@]} -eq 0 ]]; then
        echo "ERROR: No rollout records found for epoch $EPOCH."
        echo "Run rollout phase first."
        exit 1
    fi

    local count
    count=${#rollout_files[@]}
    echo "Reflecting on $count rollout records..."
    echo ""

    if [[ "$EXEC" == true ]]; then
        # Aggregate rollouts into a reflection prompt
        local rollout_glob
        if [[ "$rollout_source" == "$STATE_DIR/03-dossiers" ]]; then
            rollout_glob="$rollout_source/epoch-$EPOCH-rollout-*.json"
        else
            rollout_glob="$rollout_source/epoch-$EPOCH-*.json"
        fi
        local rollouts_json
        ROLLOUT_GLOB="$rollout_glob" python3 -c "
import json, glob, os
records = []
for f in sorted(glob.glob(os.environ['ROLLOUT_GLOB'])):
    records.append(json.load(open(f)))
print(json.dumps(records, indent=2))
")

        local prompt="You are analyzing the results of a skill optimization rollout phase.
$count training tasks were executed using the current skill document.
Here are the execution records:

${rollouts_json}

Analyze these records and produce a structured reflection:
1. Identify systematic failure patterns (what went wrong, across multiple tasks)
2. Categorize patterns by frequency and severity
3. For each pattern, suggest what kind of change to the skill would address it

Output ONLY a JSON object following this schema:
{
    \"epoch\": $EPOCH,
    \"rollout_count\": $count,
    \"success_count\": integer,
    \"failure_count\": integer,
    \"failure_patterns\": [
        {
            \"pattern\": \"description of the pattern\",
            \"frequency\": \"X of Y tasks\",
            \"severity\": \"high|medium|low\",
            \"tasks_affected\": [\"task-id-1\", ...],
            \"suggested_fix_type\": \"add|replace|delete\",
            \"suggested_location\": \"section name or 'general'\"
        }
    ],
    \"summary\": \"one-paragraph overview of findings\"
}"

        local result
        result=$(run_hermes_prompt "$prompt" 2>>"$ERROR_LOG" || echo '{"error": "execution failed"}')

        echo "$result" | python3 -c "
import json, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    data = {'epoch': $EPOCH, 'error': 'parse failure', 'raw': raw}
open('$reflect_dir/epoch-$EPOCH.json', 'w').write(json.dumps(data, indent=2))
print(f'  Reflection written: $reflect_dir/epoch-$EPOCH.json')
"
        # Copy reflection to unified pyramid and regenerate root files
        cp "$reflect_dir/epoch-$EPOCH.json" "$STATE_DIR/03-dossiers/epoch-$EPOCH-reflection.json"
        SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)" PYTHONPATH="$SCRIPTS_DIR:$PYTHONPATH" \
            EPOCH="$EPOCH" STATE_DIR="$STATE_DIR" python3 << 'PYEOF'
import os, sys; import pyramid_utils
pyramid_utils.update_root_pyramid(os.environ["STATE_DIR"], os.environ["EPOCH"])
PYEOF
    else
        echo "To generate a reflection, run with --exec or:"
        echo "  $HERMES -z \"Review the rollout records in \$SKILLOPT_DIR/$SKILL_NAME/rollouts/ and produce a structured reflection\""
        echo ""
        echo "Input files: $rollout_dir/epoch-$EPOCH-*.json"
        echo "Output: $reflect_dir/epoch-$EPOCH.json"
        echo "See references/artifact-formats.md for the reflection JSON schema."
        echo ""
        echo "After writing the reflection, run:"
        echo "  $0 --board $BOARD_SLUG --phase propose --epoch $EPOCH"
    fi
}

# ============================================================
# Phase: propose
# ============================================================
run_propose() {
    local reflect_dir="$STATE_DIR/reflections"
    local proposal_dir="$STATE_DIR/proposals"
    mkdir -p "$proposal_dir"

    # Check unified pyramid first for reflection, fall back to old directory
    local reflect_file="$STATE_DIR/03-dossiers/epoch-$EPOCH-reflection.json"
    if [[ ! -f "$reflect_file" ]]; then
        reflect_file="$reflect_dir/epoch-$EPOCH.json"
    fi
    if [[ ! -f "$reflect_file" ]]; then
        echo "ERROR: No reflection document found for epoch $EPOCH."
        echo "Run reflect phase first."
        exit 1
    fi

    echo "Proposing up to $EDIT_BUDGET edits based on reflection..."
    echo ""

    if [[ "$EXEC" == true ]]; then
        local reflection
        reflection=$(cat "$reflect_file")

        local prompt="You are proposing edits to improve a skill document based on rollout analysis.

=== CURRENT SKILL DOCUMENT PATH ===
${TARGET}

Read the current skill document from this path before proposing edits. Proposals must still use exact old_text snippets from the file so merge can apply them safely.

=== REFLECTION (failure patterns to address) ===
${reflection}

=== CONSTRAINT ===
You may propose at most $EDIT_BUDGET edits. Each edit must be a small, targeted change.
Propose fewer edits if the reflection identifies few patterns.

Output ONLY a JSON object following this schema:
{
    \"epoch\": $EPOCH,
    \"budget\": $EDIT_BUDGET,
    \"proposals\": [
        {
            \"id\": \"edit-1\",
            \"type\": \"add\" | \"replace\" | \"delete\",
            \"location\": \"section name or line reference\",
            \"old_text\": \"existing text (null if add)\",
            \"new_text\": \"replacement text (null if delete)\",
            \"rationale\": \"which failure pattern this addresses\"
        }
    ]
}"

        local result
        result=$(run_hermes_prompt "$prompt" 2>>"$ERROR_LOG" || echo '{"error": "execution failed"}')

        echo "$result" | python3 -c "
import json, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    data = {'epoch': $EPOCH, 'error': 'parse failure', 'raw': raw}
open('$proposal_dir/epoch-$EPOCH.json', 'w').write(json.dumps(data, indent=2))
proposals = data.get('proposals', [])
print(f'  Proposals written: $proposal_dir/epoch-$EPOCH.json ({len(proposals)} edits)')
"
        # Copy proposals to unified pyramid and regenerate root files
        cp "$proposal_dir/epoch-$EPOCH.json" "$STATE_DIR/03-dossiers/epoch-$EPOCH-proposals.json"
        SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)" PYTHONPATH="$SCRIPTS_DIR:$PYTHONPATH" \
            EPOCH="$EPOCH" STATE_DIR="$STATE_DIR" python3 << 'PYEOF'
import os, sys; import pyramid_utils
pyramid_utils.update_root_pyramid(os.environ["STATE_DIR"], os.environ["EPOCH"])
PYEOF

        # --- Write per-epoch proposal pyramid ---
        local proposal_pyramid_dir="$STATE_DIR/proposal/epoch-$EPOCH"
        mkdir -p "$proposal_pyramid_dir/01-summary" "$proposal_pyramid_dir/02-analysis" "$proposal_pyramid_dir/03-dossiers"
        EPOCH="$EPOCH" PROPOSAL_FILE="$proposal_dir/epoch-$EPOCH.json" \
            PROPOSAL_PYRAMID_DIR="$proposal_pyramid_dir" \
            EDIT_BUDGET="$EDIT_BUDGET" python3 << 'PYEOF'
import json, os
from datetime import datetime, timezone

epoch = os.environ["EPOCH"]
proposal_file = os.environ["PROPOSAL_FILE"]
pyramid_dir = os.environ["PROPOSAL_PYRAMID_DIR"]
edit_budget = int(os.environ.get("EDIT_BUDGET", "4"))

with open(proposal_file) as f:
    data = json.load(f)

proposals = data.get("proposals", [])
edit_count = len(proposals)
focus_areas = sorted(set(
    p.get("location", "").split(",")[0].strip()
    for p in proposals if p.get("location")
))
created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

# Extract edit budget from proposals data if available
budget = data.get("budget", edit_budget)

# 00-index.md
index_lines = [
    f"# Proposals — Epoch {epoch}",
    "",
    "## Navigation",
    "",
    f"- [01-summary/findings.md](01-summary/findings.md) — L1: proposal summary",
    f"- [02-analysis/per-edit-rationale.md](02-analysis/per-edit-rationale.md) — L2: per-edit rationale",
    "",
    "## Provenance",
    "",
    f"- epoch: {epoch}",
    f"- edit_budget: {budget}",
    f"- edit_count: {edit_count}",
    f"- focus_areas: {', '.join(focus_areas) if focus_areas else 'none'}",
    f"- generated_at: {created}",
]
with open(os.path.join(pyramid_dir, "00-index.md"), "w") as f:
    f.write("\n".join(index_lines) + "\n")

# 01-summary/findings.md
summary_lines = [
    "---",
    f"epoch: {epoch}",
    f"edit_budget: {budget}",
    f"edit_count: {edit_count}",
    f"focus_areas: [{', '.join(focus_areas) if focus_areas else 'none'}]",
    "---",
    "",
    f"# Proposals — Epoch {epoch} Summary",
    "",
    f"**Edit budget:** {budget}  ",
    f"**Edits proposed:** {edit_count}  ",
    f"**Focus areas:** {', '.join(focus_areas) if focus_areas else 'none'}",
    "",
    "## SOURCES (LAYER 2 NAVIGATION)",
    "",
    "02-analysis/per-edit-rationale.md -> Rationale for each proposed edit",
]
with open(os.path.join(pyramid_dir, "01-summary", "findings.md"), "w") as f:
    f.write("\n".join(summary_lines) + "\n")

# 02-analysis/per-edit-rationale.md
edit_lines = [
    f"# Per-Edit Rationale — Epoch {epoch}",
    "",
    f"**{edit_count} edits proposed** (budget: {budget}).",
    "",
]
if edit_count > 0:
    for i, prop in enumerate(proposals):
        eid = prop.get("id", f"edit-{i+1}")
        etype = prop.get("type", "replace")
        loc = prop.get("location", "unknown")
        rationale = prop.get("rationale", "No rationale provided.")
        old_text = prop.get("old_text", "")
        new_text = prop.get("new_text", "")

        # Risk assessment
        risk = "low"
        if etype == "replace" and new_text and len(new_text) > 500:
            risk = "high"
        elif etype == "replace" and new_text and len(new_text) > 200:
            risk = "medium"
        elif etype == "delete" and old_text and len(old_text) > 100:
            risk = "medium"

        edit_lines.append(f"### {eid} ({etype})")
        edit_lines.append("")
        edit_lines.append(f"**Location:** {loc}")
        edit_lines.append(f"**Risk:** {risk}")
        edit_lines.append(f"**Rationale:** {rationale}")
        edit_lines.append("")
        edit_lines.append("**SOURCES (LAYER 3):**")
        edit_lines.append(f"03-dossiers/{eid}.json -> Full proposal record")
        edit_lines.append("")
else:
    edit_lines.append("_No edits proposed in this epoch._")
edit_lines.append("## SOURCES (LAYER 2 NAVIGATION)")
edit_lines.append("01-summary/findings.md -> Epoch summary")
with open(os.path.join(pyramid_dir, "02-analysis", "per-edit-rationale.md"), "w") as f:
    f.write("\n".join(edit_lines) + "\n")

# 03-dossiers/ — one JSON per edit
for i, prop in enumerate(proposals):
    eid = prop.get("id", f"edit-{i+1}")
    dst = os.path.join(pyramid_dir, "03-dossiers", f"{eid}.json")
    with open(dst, "w") as f:
        json.dump(prop, f, indent=2)

print(f"  Proposal pyramid written: {pyramid_dir} ({edit_count} edits)")
PYEOF

        echo ""
        echo "Proposal pyramid written to: $proposal_pyramid_dir"
    else
        echo "To generate proposals, run with --exec or manually craft up to $EDIT_BUDGET edits."
        echo ""
        echo "Input: $reflect_dir/epoch-$EPOCH.json"
        echo "Output: $proposal_dir/epoch-$EPOCH.json"
        echo "See references/artifact-formats.md for the proposal JSON schema."
        echo ""
        echo "After writing proposals, run:"
        echo "  $0 --board $BOARD_SLUG --phase validate --epoch $EPOCH"
    fi
}

# ============================================================
# Phase: validate
# ============================================================
run_validate() {
    local proposal_dir="$STATE_DIR/proposals"
    local validation_dir="$STATE_DIR/validation-results"
    mkdir -p "$validation_dir"

    if [[ ! -f "$proposal_dir/epoch-$EPOCH.json" ]]; then
        echo "ERROR: No proposals found for epoch $EPOCH."
        echo "Run propose phase first."
        exit 1
    fi

    if [[ ! -f "$TEST_SUITE" ]]; then
        echo "ERROR: No test suite found at $TEST_SUITE"
        exit 1
    fi

    echo "Validating each proposed edit against held-out validation tasks..."
    echo ""

    if [[ "$EXEC" == true ]]; then
        local proposal_file="$proposal_dir/epoch-$EPOCH.json"

        # For each proposal, apply it to an in-memory copy of the skill,
        # run held-out validation tasks, and compare against stored baseline.
        EPOCH="$EPOCH" \
        TARGET_PATH="$TARGET" \
        PROPOSAL_FILE="$proposal_file" \
        TEST_SUITE="$TEST_SUITE" \
        VAL_DIR="$validation_dir" \
        HERMES="$HERMES" \
        python3 << 'PYEOF'
import json, os, shlex, shutil, subprocess, sys, tempfile, time
from datetime import datetime, timezone

DEFAULT_METRIC_WEIGHTS = {
    "pass_rate": 0.55,
    "quality_score": 0.30,
    "speed_score": 0.10,
    "token_efficiency": 0.05,
}
REQUIRED_METRIC_FIELDS = {
    "pass_rate",
    "avg_quality_score",
    "avg_duration_seconds",
    "total_token_estimate",
    "speed_score",
    "token_efficiency",
    "weighted_score",
}
VALIDATION_CONTEXT = "skill_workspace_v1"

epoch = os.environ["EPOCH"]
target = os.environ["TARGET_PATH"]
proposal_file = os.environ["PROPOSAL_FILE"]
test_suite = os.environ["TEST_SUITE"]
val_dir = os.environ["VAL_DIR"]
hermes = os.environ.get("HERMES", "hermes")
state_dir = os.path.dirname(val_dir)
baseline_dir = os.path.join(state_dir, "baseline", f"epoch-{epoch}")
baseline_index = os.path.join(baseline_dir, "00-index.md")
baseline_summary = os.path.join(baseline_dir, "01-summary", "findings.md")
baseline_analysis = os.path.join(baseline_dir, "02-analysis", "per-task-evaluation.md")
baseline_dossiers = os.path.join(baseline_dir, "03-dossiers")
metadata_file = os.path.join(state_dir, "board-metadata.json")

def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)

def write_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def as_bool(value):
    if isinstance(value, bool):
        return value
    if isinstance(value, str):
        return value.strip().lower() in {"true", "pass", "passed", "yes", "1"}
    return bool(value)

def safe_float(value, default=0.0):
    try:
        if value is None:
            return default
        return float(value)
    except (TypeError, ValueError):
        return default

def clamp01(value, default=0.0):
    return max(0.0, min(1.0, safe_float(value, default)))

def estimate_tokens(text):
    # Cheap heuristic used when Hermes/API usage metadata is unavailable.
    # Four chars/token is the standard rough English-token estimate.
    return max(0, int((len(text or "") + 3) // 4))


def normalize_metric_weights(*sources):
    weights = dict(DEFAULT_METRIC_WEIGHTS)
    aliases = {
        "pass": "pass_rate",
        "pass_fail": "pass_rate",
        "pass/fail": "pass_rate",
        "quality": "quality_score",
        "output_quality": "quality_score",
        "speed": "speed_score",
        "latency": "speed_score",
        "duration": "speed_score",
        "tokens": "token_efficiency",
        "token_utilization": "token_efficiency",
        "token_usage": "token_efficiency",
    }
    for source in sources:
        if not isinstance(source, dict):
            continue
        for key, value in source.items():
            canonical = aliases.get(str(key), str(key))
            if canonical in weights:
                weights[canonical] = max(0.0, safe_float(value, weights[canonical]))
    total = sum(weights.values())
    if total <= 0:
        return dict(DEFAULT_METRIC_WEIGHTS)
    return {key: round(value / total, 4) for key, value in weights.items()}

def load_metric_weights(suite):
    metadata_weights = {}
    if os.path.exists(metadata_file):
        try:
            metadata_weights = load_json(metadata_file).get("metric_weights", {})
        except Exception:
            metadata_weights = {}
    # Board metadata overrides test-suite defaults when both are present.
    return normalize_metric_weights(suite.get("metric_weights", {}), metadata_weights)

def extract_token_usage(verdict):
    if not isinstance(verdict, dict):
        return None
    for key in ("total_tokens", "token_estimate", "tokens_used"):
        if key in verdict:
            value = safe_float(verdict.get(key), None)
            if value is not None:
                return int(max(0, value))
    usage = verdict.get("token_usage")
    if isinstance(usage, dict):
        for key in ("total_tokens", "total", "tokens_used"):
            if key in usage:
                value = safe_float(usage.get(key), None)
                if value is not None:
                    return int(max(0, value))
        input_tokens = safe_float(usage.get("input_tokens"), 0.0)
        output_tokens = safe_float(usage.get("output_tokens"), 0.0)
        if input_tokens or output_tokens:
            return int(max(0, input_tokens + output_tokens))
    return None

def normalize_verdict(verdict, prompt, skill_text, stdout="", stderr="", duration_seconds=0.0):
    if not isinstance(verdict, dict):
        verdict = {}
    passed = as_bool(verdict.get("pass", False))
    quality_raw = verdict.get("quality_score", verdict.get("quality", verdict.get("score")))
    quality_score = clamp01(quality_raw, 1.0 if passed else 0.0)
    api_tokens = extract_token_usage(verdict)
    if api_tokens is None:
        token_estimate = (
            estimate_tokens(prompt)
            + estimate_tokens(skill_text)
            + estimate_tokens(stdout)
            + estimate_tokens(stderr)
        )
        token_source = "heuristic_chars_per_4_including_skill_text"
    else:
        token_estimate = api_tokens
        token_source = "reported_by_evaluator"
    return {
        "pass": passed,
        "quality_score": round(quality_score, 4),
        "reason": str(verdict.get("reason", "")),
        "duration_seconds": round(max(0.0, duration_seconds), 3),
        "token_estimate": int(max(0, token_estimate)),
        "token_source": token_source,
    }

SUPPORT_FILE_ALLOWLIST = {"README.md", "AGENTS.md", "LICENSE"}
SUPPORT_DIR_ALLOWLIST = {"references", "scripts", "templates", "assets"}


def skill_workspace_ignore(dirpath, names):
    ignored = {
        ".git",
        ".hg",
        ".svn",
        ".mypy_cache",
        ".pytest_cache",
        ".ruff_cache",
        "__pycache__",
        "node_modules",
        ".venv",
        "venv",
        "dist",
        "build",
    }
    skipped = {name for name in names if name in ignored or name.endswith(".pyc")}
    for name in names:
        if os.path.islink(os.path.join(dirpath, name)):
            skipped.add(name)
    return skipped


def copy_allowed_support_files(source_dir, candidate_dir):
    """Copy only declared support surfaces; never follow symlinks."""
    os.makedirs(candidate_dir, exist_ok=True)
    for name in sorted(SUPPORT_FILE_ALLOWLIST):
        src = os.path.join(source_dir, name)
        dst = os.path.join(candidate_dir, name)
        if os.path.isfile(src) and not os.path.islink(src):
            shutil.copy2(src, dst)
    for name in sorted(SUPPORT_DIR_ALLOWLIST):
        src = os.path.join(source_dir, name)
        dst = os.path.join(candidate_dir, name)
        if os.path.isdir(src) and not os.path.islink(src):
            shutil.copytree(src, dst, ignore=skill_workspace_ignore)


def create_candidate_workspace(skill_text, prefix):
    """Create a safe support-file workspace and overlay candidate SKILL.md text."""
    source_dir = os.path.dirname(os.path.abspath(target))
    workspace = tempfile.TemporaryDirectory(prefix=prefix)
    skill_dir_name = os.path.basename(source_dir.rstrip(os.sep)) or "skill"
    candidate_dir = os.path.join(workspace.name, skill_dir_name)
    copy_allowed_support_files(source_dir, candidate_dir)
    skill_filename = os.path.basename(os.path.abspath(target)) or "SKILL.md"
    skill_path = os.path.join(candidate_dir, skill_filename)
    with open(skill_path, "w", encoding="utf-8") as f:
        f.write(skill_text)
    return workspace, candidate_dir, skill_path


def run_validation_task(skill_text, task):
    task_inst = task.get("instruction", "")
    workspace = None
    prompt = ""
    started = time.monotonic()
    try:
        workspace, skill_dir, skill_path = create_candidate_workspace(
            skill_text,
            prefix="skillopt-validation-workspace-",
        )

        prompt = f"""Evaluate this candidate skill workspace against the following task.

=== CANDIDATE SKILL WORKSPACE ===
{skill_dir}

=== CANDIDATE SKILL DOCUMENT PATH ===
{skill_path}

Read the skill document first. If the task depends on linked or sibling support files, inspect files inside the candidate workspace only, including README.md, AGENTS.md, references/, scripts/, templates/, and assets/ when present. Do not inspect or modify the original installed skill outside this workspace. Do not modify files.

=== TASK ===
{task_inst}

Does this candidate skill successfully handle this task? Respond with ONLY a JSON object:
{{
  "pass": true/false,
  "quality_score": 0.0-1.0,
  "reason": "brief explanation"
}}

Scoring guidance:
- pass is the coarse success/failure gate for the task.
- quality_score captures output quality within the same pass/fail bucket: completeness, specificity, correctness details, format polish, and task-specific quality criteria.
- speed and token utilization are measured by the SkillOpt runner; do not guess them."""

        cmd = shlex.split(hermes) + ["-z", prompt]
        result = subprocess.run(
            cmd,
            capture_output=True, text=True, timeout=120
        )
        duration = time.monotonic() - started
    except Exception as exc:
        duration = time.monotonic() - started
        return normalize_verdict(
            {"pass": False, "quality_score": 0.0, "reason": f"execution error: {exc.__class__.__name__}"},
            prompt,
            skill_text,
            duration_seconds=duration,
        )
    finally:
        if workspace:
            workspace.cleanup()

    if result.returncode != 0:
        return normalize_verdict(
            {
                "pass": False,
                "quality_score": 0.0,
                "reason": f"hermes -z failed with exit {result.returncode}",
            },
            prompt,
            skill_text,
            stdout=result.stdout or "",
            stderr=result.stderr or "",
            duration_seconds=duration,
        ) | {"stderr": (result.stderr or "")[-500:]}

    try:
        verdict = json.loads((result.stdout or "").strip())
    except json.JSONDecodeError:
        return normalize_verdict(
            {"pass": False, "quality_score": 0.0, "reason": "parse error"},
            prompt,
            skill_text,
            stdout=result.stdout or "",
            stderr=result.stderr or "",
            duration_seconds=duration,
        ) | {"raw": (result.stdout or "")[-500:]}
    if not isinstance(verdict, dict):
        verdict = {"pass": False, "quality_score": 0.0, "reason": "JSON response was not an object"}

    return normalize_verdict(
        verdict,
        prompt,
        skill_text,
        stdout=result.stdout or "",
        stderr=result.stderr or "",
        duration_seconds=duration,
    )

def result_from_detail(detail):
    if not isinstance(detail, dict):
        return {"pass": as_bool(detail), "quality_score": 1.0 if as_bool(detail) else 0.0}
    for key in ("result", "post_edit_result", "baseline_result"):
        value = detail.get(key)
        if isinstance(value, dict):
            return value
        if value is not None:
            return {"pass": as_bool(value), "quality_score": 1.0 if as_bool(value) else 0.0}
    if "baseline" in detail:
        passed = as_bool(detail.get("baseline"))
        return {"pass": passed, "quality_score": 1.0 if passed else 0.0}
    return {"pass": False, "quality_score": 0.0}

def detail_is_pass(detail):
    return as_bool(result_from_detail(detail).get("pass", False))

def quality_from_result(result):
    passed = as_bool(result.get("pass", False)) if isinstance(result, dict) else as_bool(result)
    if not isinstance(result, dict):
        return 1.0 if passed else 0.0
    return clamp01(result.get("quality_score", result.get("quality", result.get("score"))), 1.0 if passed else 0.0)

def metrics_from_details(details, weights):
    total = len(details)
    if not total:
        return {
            "pass_rate": 0.0,
            "tasks_passed": 0,
            "tasks_failed": 0,
            "avg_quality_score": 0.0,
            "avg_duration_seconds": 0.0,
            "total_duration_seconds": 0.0,
            "avg_token_estimate": 0,
            "total_token_estimate": 0,
            "speed_score": 0.0,
            "token_efficiency": 0.0,
            "weighted_score": 0.0,
        }
    results = [result_from_detail(detail) for detail in details]
    passed = sum(1 for result in results if as_bool(result.get("pass", False)))
    quality_scores = [quality_from_result(result) for result in results]
    durations = [max(0.0, safe_float(result.get("duration_seconds"), 0.0)) for result in results]
    token_estimates = [max(0, int(safe_float(result.get("token_estimate"), 0.0))) for result in results]

    pass_rate = passed / total
    avg_quality = sum(quality_scores) / total
    total_duration = sum(durations)
    avg_duration = total_duration / total
    total_tokens = sum(token_estimates)
    avg_tokens = total_tokens / total
    speed_score = 1.0 / (1.0 + avg_duration)
    token_efficiency = 1.0 / (1.0 + (avg_tokens / 1000.0))
    weighted_score = (
        weights.get("pass_rate", 0.0) * pass_rate
        + weights.get("quality_score", 0.0) * avg_quality
        + weights.get("speed_score", 0.0) * speed_score
        + weights.get("token_efficiency", 0.0) * token_efficiency
    )
    return {
        "pass_rate": round(pass_rate, 4),
        "tasks_passed": passed,
        "tasks_failed": total - passed,
        "avg_quality_score": round(avg_quality, 4),
        "avg_duration_seconds": round(avg_duration, 3),
        "total_duration_seconds": round(total_duration, 3),
        "avg_token_estimate": int(round(avg_tokens)),
        "total_token_estimate": int(total_tokens),
        "speed_score": round(speed_score, 4),
        "token_efficiency": round(token_efficiency, 4),
        "weighted_score": round(weighted_score, 4),
    }

def baseline_has_required_metrics(metrics):
    return isinstance(metrics, dict) and REQUIRED_METRIC_FIELDS.issubset(metrics.keys())

def load_or_create_baseline(skill_content, val_tasks):
    # Check for existing baseline in unified pyramid (03-dossiers) first,
    # then fall back to old-format pyramid (baseline/epoch-N/00-index.md)
    dossiers_dir = os.path.join(state_dir, "03-dossiers")
    dossier_path = os.path.join(dossiers_dir, f"epoch-{epoch}-baseline.json")
    cached = None
    if os.path.exists(dossier_path):
        cached = load_json(dossier_path)
    elif os.path.exists(baseline_index):
        # Old-format baseline pyramid — read from 01-summary YAML frontmatter
        try:
            summary_text = open(baseline_summary).read()
            meta = json.loads(summary_text.split("---", 2)[1])
            metrics = {k: meta[k] for k in ("pass_rate", "avg_quality_score", "avg_duration_seconds",
                                             "avg_token_estimate", "speed_score", "token_efficiency",
                                             "weighted_score", "tasks_passed", "tasks_failed",
                                             "total_duration_seconds", "total_token_estimate")}
            details = []
            if os.path.isdir(baseline_dossiers):
                for fname in sorted(os.listdir(baseline_dossiers)):
                    if fname.endswith(".json"):
                        details.append(load_json(os.path.join(baseline_dossiers, fname)))
            cached = {
                "epoch": int(epoch), "target": target,
                "validation_context": meta.get("validation_context", ""),
                "validation_tasks_run": meta.get("total_tasks", 0),
                "metric_weights": meta.get("metric_weights", {}),
                "baseline_metrics": metrics, "validation_detail": details,
                "created_at": meta.get("created_at", ""),
            }
        except:
            cached = None

    if cached:
        metrics = cached.get("baseline_metrics") or {}
        ctx = cached.get("validation_context", "")
        if ctx != VALIDATION_CONTEXT:
            print("  Existing baseline uses old validation context; recomputing baseline.")
        elif baseline_has_required_metrics(metrics):
            print(f"  Baseline loaded (pass: {float(metrics.get('pass_rate', 0.0)):.0%}, "
                  f"quality: {float(metrics.get('avg_quality_score', 0.0)):.2f}, "
                  f"score: {float(metrics.get('weighted_score', 0.0)):.2f})")
            return cached, metrics
        else:
            print("  Existing baseline lacks multi-objective metrics; recomputing baseline.")

    # --- Cache miss / recompute ---
    details = []
    for task in val_tasks:
        task_id = task.get("id", "unknown")
        verdict = run_validation_task(skill_content, task)
        details.append({"task_id": task_id, "result": verdict})

    metrics = metrics_from_details(details, metric_weights)
    created_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    baseline_json = {
        "epoch": int(epoch), "target": target,
        "validation_context": VALIDATION_CONTEXT,
        "validation_tasks_run": len(val_tasks),
        "metric_weights": metric_weights,
        "baseline_metrics": metrics,
        "validation_detail": details,
        "created_at": created_at,
    }

    # Write to unified pyramid dossiers
    os.makedirs(dossiers_dir, exist_ok=True)
    write_json(dossier_path, baseline_json)
    pyramid_utils.update_root_pyramid(state_dir, epoch)

    print(f"  Baseline written: {dossier_path} "
          f"(pass: {float(metrics.get('pass_rate', 0.0)):.0%}, "
          f"quality: {float(metrics.get('avg_quality_score', 0.0)):.2f}, "
          f"score: {float(metrics.get('weighted_score', 0.0)):.2f})")
    return baseline_json, metrics

def apply_edit(skill_content, edit):
    edit_type = edit.get("type", "replace")
    old_text = edit.get("old_text") or ""
    new_text = edit.get("new_text") or ""

    if edit_type == "replace":
        if not old_text:
            return skill_content, "replace edit missing old_text"
        if old_text not in skill_content:
            return skill_content, "replace edit old_text not found"
        return skill_content.replace(old_text, new_text, 1), None
    if edit_type == "add":
        if not new_text:
            return skill_content, "add edit missing new_text"
        return skill_content + "\n" + new_text, None
    if edit_type == "delete":
        if not old_text:
            return skill_content, "delete edit missing old_text"
        if old_text not in skill_content:
            return skill_content, "delete edit old_text not found"
        return skill_content.replace(old_text, "", 1), None
    return skill_content, f"unknown edit type: {edit_type}"


# Load shared pyramid utilities
_scripts_dir = os.path.join(os.path.dirname(os.path.dirname(val_dir)), "scripts")
sys.path.insert(0, _scripts_dir)
import pyramid_utils


proposals = load_json(proposal_file)
with open(target, encoding="utf-8") as f:
    skill_content = f.read()
suite = load_json(test_suite)
metric_weights = load_metric_weights(suite)
val_tasks = suite.get("validation", [])
if not val_tasks:
    raise SystemExit("ERROR: No validation tasks defined; cannot validate proposed edits.")

edits = proposals.get("proposals", [])
if not edits:
    print("  Result: 0 accepted, 0 rejected")
    sys.exit(0)

print(
    "  Metric weights: "
    f"pass={metric_weights['pass_rate']:.2f}, "
    f"quality={metric_weights['quality_score']:.2f}, "
    f"speed={metric_weights['speed_score']:.2f}, "
    f"tokens={metric_weights['token_efficiency']:.2f}"
)
baseline_record, baseline_metrics = load_or_create_baseline(skill_content, val_tasks)
baseline_pass_rate = float(baseline_metrics.get("pass_rate", 0.0))
baseline_score = float(baseline_metrics.get("weighted_score", baseline_pass_rate))
baseline_by_task = {
    detail.get("task_id", "unknown"): detail.get("result", {"pass": detail_is_pass(detail)})
    for detail in baseline_record.get("validation_detail", [])
}

results = []
for i, edit in enumerate(edits):
    edit_id = edit.get("id", f"edit-{i+1}")
    edit_type = edit.get("type", "replace")
    edited_skill, apply_error = apply_edit(skill_content, edit)

    val_details = []
    if apply_error:
        post_metrics = metrics_from_details([
            {"result": {"pass": False, "quality_score": 0.0, "duration_seconds": 0.0, "token_estimate": 0}}
            for _ in val_tasks
        ], metric_weights)
        verdict = "rejected"
        acceptance_reason = f"apply_error: {apply_error}"
        val_details.append({"task_id": "apply-edit", "post_edit": "fail", "post_edit_result": {"pass": False, "quality_score": 0.0, "reason": apply_error}})
    else:
        for task in val_tasks:
            task_id = task.get("id", "unknown")
            post_verdict = run_validation_task(edited_skill, task)
            baseline_verdict = baseline_by_task.get(task_id)
            baseline_pass = as_bool(baseline_verdict.get("pass", False)) if isinstance(baseline_verdict, dict) else None
            val_details.append({
                "task_id": task_id,
                "baseline": "pass" if baseline_pass else "fail" if baseline_pass is not None else "unknown",
                "post_edit": "pass" if as_bool(post_verdict.get("pass", False)) else "fail",
                "baseline_result": baseline_verdict,
                "post_edit_result": post_verdict
            })
        post_metrics = metrics_from_details([{"result": d["post_edit_result"]} for d in val_details], metric_weights)
        post_pass_rate = float(post_metrics.get("pass_rate", 0.0))
        post_score = float(post_metrics.get("weighted_score", post_pass_rate))
        if post_pass_rate < baseline_pass_rate:
            verdict = "rejected"
            acceptance_reason = "pass_rate_regression"
        elif post_score >= baseline_score:
            verdict = "accepted"
            acceptance_reason = "weighted_score_non_regression"
        else:
            verdict = "rejected"
            acceptance_reason = "weighted_score_regression"

    pass_delta = float(post_metrics.get("pass_rate", 0.0)) - baseline_pass_rate
    score_delta = float(post_metrics.get("weighted_score", 0.0)) - baseline_score
    quality_delta = float(post_metrics.get("avg_quality_score", 0.0)) - float(baseline_metrics.get("avg_quality_score", 0.0))
    duration_delta = float(post_metrics.get("avg_duration_seconds", 0.0)) - float(baseline_metrics.get("avg_duration_seconds", 0.0))
    token_delta = int(post_metrics.get("avg_token_estimate", 0)) - int(baseline_metrics.get("avg_token_estimate", 0))
    result_record = {
        "epoch": epoch,
        "proposal_id": edit_id,
        "edit_type": edit_type,
        "validation_tasks_run": len(val_tasks),
        "metric_weights": metric_weights,
        "baseline_metrics": baseline_metrics,
        "post_edit_metrics": post_metrics,
        "verdict": verdict,
        "acceptance_reason": acceptance_reason,
        "delta": f"{pass_delta:+.2f} pass rate",
        "score_delta": f"{score_delta:+.4f} weighted score",
        "quality_delta": f"{quality_delta:+.4f} quality score",
        "duration_delta_seconds": round(duration_delta, 3),
        "token_delta_estimate": token_delta,
        "validation_detail": val_details
    }

    out_file = os.path.join(val_dir, f"epoch-{epoch}-{edit_id}.json")
    write_json(out_file, result_record)
    print(
        f"  {edit_id}: {verdict} ({acceptance_reason}; "
        f"pass {baseline_pass_rate:.0%}->{float(post_metrics.get('pass_rate', 0.0)):.0%}, "
        f"quality {float(baseline_metrics.get('avg_quality_score', 0.0)):.2f}->{float(post_metrics.get('avg_quality_score', 0.0)):.2f}, "
        f"score {baseline_score:.2f}->{float(post_metrics.get('weighted_score', 0.0)):.2f}, "
        f"avg_seconds {float(baseline_metrics.get('avg_duration_seconds', 0.0)):.3f}->{float(post_metrics.get('avg_duration_seconds', 0.0)):.3f}, "
        f"avg_tokens {int(baseline_metrics.get('avg_token_estimate', 0))}->{int(post_metrics.get('avg_token_estimate', 0))})"
    )
    results.append(result_record)

accepted = sum(1 for r in results if r["verdict"] == "accepted")
rejected = sum(1 for r in results if r["verdict"] == "rejected")
print(f"  Result: {accepted} accepted, {rejected} rejected")

if rejected > 0:
    buffer_file = os.path.join(os.path.dirname(val_dir), "rejected-buffer.json")
    buffer = []
    if os.path.exists(buffer_file):
        buffer = load_json(buffer_file)

    def rejection_key(result):
        return (
            str(result.get("epoch", "")),
            str(result.get("proposal_id", "")),
            str(result.get("edit_type", "")),
            str(result.get("acceptance_reason", result.get("merge_error", ""))),
        )

    existing_keys = {rejection_key(item) for item in buffer if isinstance(item, dict)}
    new_rejections = []
    for result in results:
        if result["verdict"] != "rejected":
            continue
        key = rejection_key(result)
        if key in existing_keys:
            continue
        buffer.append(result)
        existing_keys.add(key)
        new_rejections.append(result)
    write_json(buffer_file, buffer)
    print(f"  Rejected edits appended to: {buffer_file} ({len(new_rejections)} new)")

# --- Write validation dossiers to unified pyramid ---
dossiers_dir_val = os.path.join(state_dir, "03-dossiers")
os.makedirs(dossiers_dir_val, exist_ok=True)
for r in results:
    src = os.path.join(val_dir, f"epoch-{epoch}-{r['proposal_id']}.json")
    dst = os.path.join(dossiers_dir_val, f"epoch-{epoch}-validation-{r['proposal_id']}.json")
    if os.path.exists(src):
        import shutil
        shutil.copy2(src, dst)
pyramid_utils.update_root_pyramid(state_dir, epoch)
print(f"  Validation dossiers written to 03-dossiers/ ({len(results)} edits)")
PYEOF
    else
        echo "To run validation, use --exec or:"
        echo "  1. Create a copy of the target skill"
        echo "  2. Apply each proposed edit to the copy"
        echo "  3. Run the validation tasks from $TEST_SUITE against each edited copy"
        echo "  4. Compare results against baseline"
        echo ""
        echo "Input: $proposal_dir/epoch-$EPOCH.json"
        echo "Output: $validation_dir/ -> 03-dossiers/epoch-EPOCH-validation-*.json"
        echo "See references/artifact-formats.md for validation result schema."
        echo ""
        echo "After validation, run:"
        echo "  $0 --board $BOARD_SLUG --phase merge --epoch $EPOCH"
    fi
}

# ============================================================
# Phase: merge
# ============================================================
run_merge() {
    local validation_dir="$STATE_DIR/validation-results"
    local snapshots_dir="$STATE_DIR/snapshots"

    local accepted_files=()
    shopt -s nullglob
    accepted_files=("$validation_dir"/epoch-"$EPOCH"-*.json)
    shopt -u nullglob
    if [[ ${#accepted_files[@]} -eq 0 ]]; then
        echo "ERROR: No validation results found for epoch $EPOCH."
        echo "Run validate phase first."
        exit 1
    fi

    if [[ "$EXEC" == true ]]; then
        EPOCH="$EPOCH" \
        TARGET_PATH="$TARGET" \
        VAL_DIR="$validation_dir" \
        SNAPSHOTS_DIR="$snapshots_dir" \
        STATE_DIR="$STATE_DIR" \
        TEST_SUITE="$TEST_SUITE" \
        HERMES="$HERMES" \
        python3 << 'PYEOF'
import glob, json, os, shlex, shutil, subprocess, tempfile, time
from datetime import datetime, timezone

epoch = os.environ["EPOCH"]
target = os.environ["TARGET_PATH"]
val_dir = os.environ["VAL_DIR"]
snapshots_dir = os.environ["SNAPSHOTS_DIR"]
state_dir = os.environ["STATE_DIR"]
test_suite_path = os.environ.get("TEST_SUITE", "")
hermes = os.environ.get("HERMES", "hermes")
VALIDATION_CONTEXT = "skill_workspace_v1"
DEFAULT_METRIC_WEIGHTS = {
    "pass_rate": 0.55,
    "quality_score": 0.30,
    "speed_score": 0.10,
    "token_efficiency": 0.05,
}

for name, value in {
    "TARGET_PATH": target,
    "VAL_DIR": val_dir,
    "SNAPSHOTS_DIR": snapshots_dir,
    "STATE_DIR": state_dir,
}.items():
    if not value:
        raise SystemExit(f"ERROR: Missing required environment value: {name}")

def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)

def write_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

def append_rejected(result):
    buffer_file = os.path.join(state_dir, "rejected-buffer.json")
    buffer = load_json(buffer_file) if os.path.exists(buffer_file) else []

    def rejection_key(item):
        return (
            str(item.get("epoch", "")),
            str(item.get("proposal_id", "")),
            str(item.get("edit_type", "")),
            str(item.get("acceptance_reason", item.get("merge_error", ""))),
        )

    key = rejection_key(result)
    if any(isinstance(item, dict) and rejection_key(item) == key for item in buffer):
        return False
    buffer.append(result)
    write_json(buffer_file, buffer)
    return True

def apply_edit(skill, proposal):
    edit_type = proposal.get("type", "replace")
    old_text = proposal.get("old_text") or ""
    new_text = proposal.get("new_text") or ""
    if edit_type == "replace":
        if not old_text or old_text not in skill:
            return skill, "replace old_text missing or not found"
        return skill.replace(old_text, new_text, 1), None
    if edit_type == "add":
        if not new_text:
            return skill, "add new_text missing"
        return skill + "\n" + new_text, None
    if edit_type == "delete":
        if not old_text or old_text not in skill:
            return skill, "delete old_text missing or not found"
        return skill.replace(old_text, "", 1), None
    return skill, f"unknown edit type: {edit_type}"

# ── Post-merge cumulative validation helpers ──────────────────────

SUPPORT_FILE_ALLOWLIST = {"README.md", "AGENTS.md", "LICENSE"}
SUPPORT_DIR_ALLOWLIST = {"references", "scripts", "templates", "assets"}


def skill_workspace_ignore(dirpath, names):
    ignored = {
        ".git",
        ".hg",
        ".svn",
        ".mypy_cache",
        ".pytest_cache",
        ".ruff_cache",
        "__pycache__",
        "node_modules",
        ".venv",
        "venv",
        "dist",
        "build",
    }
    skipped = {name for name in names if name in ignored or name.endswith(".pyc")}
    for name in names:
        if os.path.islink(os.path.join(dirpath, name)):
            skipped.add(name)
    return skipped


def copy_allowed_support_files(source_dir, candidate_dir):
    """Copy only declared support surfaces; never follow symlinks."""
    os.makedirs(candidate_dir, exist_ok=True)
    for name in sorted(SUPPORT_FILE_ALLOWLIST):
        src = os.path.join(source_dir, name)
        dst = os.path.join(candidate_dir, name)
        if os.path.isfile(src) and not os.path.islink(src):
            shutil.copy2(src, dst)
    for name in sorted(SUPPORT_DIR_ALLOWLIST):
        src = os.path.join(source_dir, name)
        dst = os.path.join(candidate_dir, name)
        if os.path.isdir(src) and not os.path.islink(src):
            shutil.copytree(src, dst, ignore=skill_workspace_ignore)


def create_candidate_workspace(skill_text, prefix):
    """Create a safe support-file workspace and overlay candidate SKILL.md text."""
    source_dir = os.path.dirname(os.path.abspath(target))
    workspace = tempfile.TemporaryDirectory(prefix=prefix)
    skill_dir_name = os.path.basename(source_dir.rstrip(os.sep)) or "skill"
    candidate_dir = os.path.join(workspace.name, skill_dir_name)
    copy_allowed_support_files(source_dir, candidate_dir)
    skill_filename = os.path.basename(os.path.abspath(target)) or "SKILL.md"
    skill_path = os.path.join(candidate_dir, skill_filename)
    with open(skill_path, "w", encoding="utf-8") as f:
        f.write(skill_text)
    return workspace, candidate_dir, skill_path


def run_post_merge_task(merged_skill, task):
    """Run a single validation task against a support-file-aware merged skill workspace."""
    task_inst = task.get("instruction", "")
    workspace = None
    prompt = ""
    started = time.monotonic()
    try:
        workspace, skill_dir, skill_path = create_candidate_workspace(
            merged_skill,
            prefix="skillopt-postmerge-workspace-",
        )
        prompt = f"""Evaluate this merged skill workspace against the following task.

=== SKILL WORKSPACE ===
{skill_dir}

=== SKILL DOCUMENT PATH ===
{skill_path}

Read the skill document first. If the task depends on linked or sibling support files, inspect files inside this workspace only, including README.md, AGENTS.md, references/, scripts/, templates/, and assets/ when present. Do not inspect or modify the original installed skill outside this workspace. Do not modify files.

=== TASK ===
{task_inst}

Does this skill successfully handle this task? Respond with ONLY a JSON object:
{{"pass": true/false, "quality_score": 0.0-1.0, "reason": "brief explanation"}}"""
        cmd = shlex.split(hermes) + ["-z", prompt]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        duration = time.monotonic() - started
        if result.returncode != 0:
            return {"pass": False, "quality_score": 0.0, "duration_seconds": duration,
                    "token_estimate": int((len(prompt) + len(merged_skill) + len(result.stdout or "") + len(result.stderr or "") + 3) // 4),
                    "reason": f"hermes -z failed with exit {result.returncode}"}
        try:
            verdict = json.loads((result.stdout or "").strip())
        except json.JSONDecodeError:
            return {"pass": False, "quality_score": 0.0, "duration_seconds": duration,
                    "token_estimate": int((len(prompt) + len(merged_skill) + len(result.stdout or "") + 3) // 4),
                    "reason": "parse error"}
        return {
            "pass": bool(verdict.get("pass", False)),
            "quality_score": max(0.0, min(1.0, float(verdict.get("quality_score", verdict.get("quality", 0))))),
            "duration_seconds": duration,
            "token_estimate": int((len(prompt) + len(merged_skill) + len(result.stdout or "") + len(result.stderr or "") + 3) // 4),
            "reason": str(verdict.get("reason", "")),
        }
    except Exception as exc:
        return {"pass": False, "quality_score": 0.0, "duration_seconds": time.monotonic() - started,
                "token_estimate": int((len(prompt) + len(merged_skill) + 3) // 4),
                "reason": f"execution error: {exc}"}
    finally:
        if workspace:
            workspace.cleanup()


def post_merge_metrics_from_details(details, weights):
    """Compute the same baseline metric schema used by validate-phase baselines."""
    total = len(details)
    if not total:
        return {
            "pass_rate": 0.0,
            "tasks_passed": 0,
            "tasks_failed": 0,
            "avg_quality_score": 0.0,
            "avg_duration_seconds": 0.0,
            "total_duration_seconds": 0.0,
            "avg_token_estimate": 0,
            "total_token_estimate": 0,
            "speed_score": 0.0,
            "token_efficiency": 0.0,
            "weighted_score": 0.0,
        }
    passed = sum(1 for d in details if d.get("pass", False))
    pass_rate = passed / total
    avg_quality = sum(float(d.get("quality_score", 0.0)) for d in details) / total
    durations = [max(0.0, float(d.get("duration_seconds", 0.0))) for d in details]
    tokens = [max(0, int(float(d.get("token_estimate", 0)))) for d in details]
    total_duration = sum(durations)
    avg_duration = total_duration / total
    total_tokens = sum(tokens)
    avg_tokens = total_tokens / total
    speed_score = 1.0 / (1.0 + avg_duration)
    token_efficiency = 1.0 / (1.0 + (avg_tokens / 1000.0))
    weighted_score = (
        weights.get("pass_rate", 0.0) * pass_rate
        + weights.get("quality_score", 0.0) * avg_quality
        + weights.get("speed_score", 0.0) * speed_score
        + weights.get("token_efficiency", 0.0) * token_efficiency
    )
    return {
        "pass_rate": round(pass_rate, 4),
        "tasks_passed": passed,
        "tasks_failed": total - passed,
        "avg_quality_score": round(avg_quality, 4),
        "avg_duration_seconds": round(avg_duration, 3),
        "total_duration_seconds": round(total_duration, 3),
        "avg_token_estimate": int(round(avg_tokens)),
        "total_token_estimate": int(total_tokens),
        "speed_score": round(speed_score, 4),
        "token_efficiency": round(token_efficiency, 4),
        "weighted_score": round(weighted_score, 4),
    }


with open(target, encoding="utf-8") as f:
    skill = f.read()

os.makedirs(snapshots_dir, exist_ok=True)
timestamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
snapshot = os.path.join(snapshots_dir, f"pre-merge-epoch-{epoch}-{timestamp}.md")
with open(snapshot, "w", encoding="utf-8") as f:
    f.write(skill)

proposal_file = os.path.join(state_dir, "proposals", f"epoch-{epoch}.json")
proposals = load_json(proposal_file)
proposals_by_id = {p.get("id"): p for p in proposals.get("proposals", [])}

accepted = 0
rejected = 0

# Try reading from unified pyramid dossiers first, fall back to flat glob
dossiers_dir_m = os.path.join(state_dir, "03-dossiers")
result_files = sorted(glob.glob(os.path.join(dossiers_dir_m, f"epoch-{epoch}-validation-*.json")))
if not result_files:
    # Old-format: flat validation-results/ directory
    result_files = sorted(glob.glob(os.path.join(val_dir, f"epoch-{epoch}-*.json")))

for result_file in result_files:
    result = load_json(result_file)
    if result.get("verdict") != "accepted":
        rejected += 1
        append_rejected(result)
        continue

    proposal_id = result.get("proposal_id", "")
    proposal = proposals_by_id.get(proposal_id)
    if not proposal:
        rejected += 1
        result["verdict"] = "rejected"
        result["merge_error"] = "accepted validation result has no matching proposal"
        append_rejected(result)
        print(f"  Skipped: {proposal_id} (missing proposal)")
        continue

    skill, apply_error = apply_edit(skill, proposal)
    if apply_error:
        rejected += 1
        result["verdict"] = "rejected"
        result["merge_error"] = apply_error
        append_rejected(result)
        print(f"  Skipped: {proposal_id} ({apply_error})")
        continue

    accepted += 1
    print(f"  Applied: {proposal_id} ({proposal.get('type', 'replace')})")

with open(target, "w", encoding="utf-8") as f:
    f.write(skill)

print(f"  Merged: {accepted} edits, {rejected} rejected")
print(f"  Snapshot saved: {snapshot}")

# ── Post-merge cumulative validation ─────────────────────────────
merge_reverted = False
if test_suite_path and os.path.exists(test_suite_path):
    try:
        suite = load_json(test_suite_path)
        val_tasks = suite.get("validation", [])
    except Exception:
        val_tasks = []
    if val_tasks:
        # Derive artifact-pyramid baseline paths (same layout as validate phase)
        _baseline_dir = os.path.join(os.path.dirname(val_dir), "baseline", f"epoch-{epoch}")
        _baseline_index = os.path.join(_baseline_dir, "00-index.md")
        _baseline_summary = os.path.join(_baseline_dir, "01-summary", "findings.md")
        _baseline_dossiers = os.path.join(_baseline_dir, "03-dossiers")
        _baseline_json = os.path.join(_baseline_dir, "baseline.json")
        if os.path.exists(_baseline_index) or os.path.exists(_baseline_json):
            try:
                _source = _baseline_json if os.path.exists(_baseline_json) else _baseline_index
                if _source == _baseline_json:
                    baseline = load_json(_baseline_json)
                else:
                    summary_text = open(_baseline_summary).read()
                    meta = json.loads(summary_text.split("---", 2)[1])
                    # Load per-task details from L3 dossiers
                    details = []
                    if os.path.isdir(_baseline_dossiers):
                        for fname in sorted(os.listdir(_baseline_dossiers)):
                            if fname.endswith(".json"):
                                details.append(load_json(os.path.join(_baseline_dossiers, fname)))
                    baseline = {
                        "epoch": int(epoch),
                        "target": target,
                        "validation_context": meta.get("validation_context", ""),
                        "validation_tasks_run": meta.get("total_tasks", 0),
                        "metric_weights": meta.get("metric_weights", {}),
                        "baseline_metrics": {k: meta[k] for k in ("pass_rate", "avg_quality_score",
                                             "weighted_score", "tasks_passed", "tasks_failed")},
                        "validation_detail": details,
                        "created_at": meta.get("created_at", ""),
                    }
                bm = baseline.get("baseline_metrics") or {}
                weights = baseline.get("metric_weights", DEFAULT_METRIC_WEIGHTS)
                bpr = float(bm.get("pass_rate", 0.0))
                bsc = float(bm.get("weighted_score", bpr))
            except Exception:
                bpr, bsc = None, None

            if bpr is not None:
                with open(target, encoding="utf-8") as f:
                    merged_skill = f.read()

                details = []
                detail_records = []
                for task in val_tasks:
                    task_id = task.get("id", "unknown")
                    verdict = run_post_merge_task(merged_skill, task)
                    details.append(verdict)
                    detail_records.append({"task_id": task_id, "result": verdict})

                pm = post_merge_metrics_from_details(details, weights)
                mpr = pm["pass_rate"]
                msc = pm["weighted_score"]

                if mpr < bpr or msc < bsc:
                    merge_reverted = True
                    with open(snapshot, encoding="utf-8") as sf:
                        with open(target, "w", encoding="utf-8") as tf:
                            tf.write(sf.read())
                    print(f"  ⚠ POST-MERGE VALIDATION FAILED: pass {bpr:.0%}→{mpr:.0%}, "
                          f"score {bsc:.2f}→{msc:.2f}")
                    print(f"  Reverted to snapshot: {snapshot}")
                    diag = {"epoch": epoch, "pass_rate": round(mpr, 4),
                            "weighted_score": round(msc, 4),
                            "baseline_pass_rate": round(bpr, 4),
                            "baseline_score": round(bsc, 4),
                            "reverted": True, "snapshot": snapshot}
                    diag_file = os.path.join(state_dir, "failed-merges.json")
                    diag_buffer = load_json(diag_file) if os.path.exists(diag_file) else []
                    diag_buffer.append(diag)
                    write_json(diag_file, diag_buffer)
                else:
                    next_epoch = int(epoch) + 1
                    refreshed_baseline_json = {
                        "epoch": next_epoch,
                        "target": target,
                        "validation_context": VALIDATION_CONTEXT,
                        "validation_tasks_run": len(val_tasks),
                        "metric_weights": weights,
                        "baseline_metrics": pm,
                        "validation_detail": detail_records,
                        "created_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "refreshed_from_epoch": int(epoch),
                        "source": "post_merge_refresh",
                    }
                    # Write refreshed baseline as artifact pyramid
                    _next_baseline_dir = os.path.join(os.path.dirname(val_dir), "baseline", f"epoch-{next_epoch}")
                    os.makedirs(os.path.join(_next_baseline_dir, "01-summary"), exist_ok=True)
                    os.makedirs(os.path.join(_next_baseline_dir, "02-analysis"), exist_ok=True)
                    os.makedirs(os.path.join(_next_baseline_dir, "03-dossiers"), exist_ok=True)
                    _new_summary = os.path.join(_next_baseline_dir, "01-summary", "findings.md")
                    _new_analysis = os.path.join(_next_baseline_dir, "02-analysis", "per-task-evaluation.md")
                    _new_dossiers = os.path.join(_next_baseline_dir, "03-dossiers")
                    _new_index = os.path.join(_next_baseline_dir, "00-index.md")
                    _created = refreshed_baseline_json["created_at"]
                    with open(_new_summary, "w", encoding="utf-8") as f:
                        f.write(f"""---
epoch: {next_epoch}
pass_rate: {pm['pass_rate']}
tasks_passed: {pm['tasks_passed']}
tasks_failed: {pm['tasks_failed']}
total_tasks: {len(val_tasks)}
avg_quality_score: {pm['avg_quality_score']}
avg_duration_seconds: {pm['avg_duration_seconds']}
total_duration_seconds: {pm['total_duration_seconds']}
avg_token_estimate: {pm['avg_token_estimate']}
total_token_estimate: {pm['total_token_estimate']}
speed_score: {pm['speed_score']}
token_efficiency: {pm['token_efficiency']}
weighted_score: {pm['weighted_score']}
validation_context: {VALIDATION_CONTEXT}
metric_weights: {json.dumps(weights)}
target: {target}
created_at: {_created}
source: post_merge_refresh
---

# Baseline Validation — Epoch {next_epoch} (Post-Merge Refresh)

**Baseline pass rate:** {pm['tasks_passed']}/{len(val_tasks)} ({float(pm['pass_rate']):.0%})
**Weighted score:** {float(pm['weighted_score']):.4f}

Post-merge cumulative validation passed. Baseline refreshed.

## SOURCES (LAYER 2 NAVIGATION)
02-analysis/per-task-evaluation.md
 -> Per-task post-merge validation results
""")
                    with open(_new_analysis, "w", encoding="utf-8") as f:
                        lines = [f"# Per-Task Post-Merge Validation — Epoch {next_epoch}\n"]
                        for d in detail_records:
                            tid = d.get("task_id", "unknown")
                            r = d.get("result", {})
                            st = "PASS" if r.get("pass", False) else "FAIL"
                            lines.append(f"## Task: {tid}")
                            lines.append(f"**Status:** {st} | **Quality:** {r.get('quality_score', 0.0)}")
                            lines.append(f"**Reason:** {r.get('reason', '')}\n")
                        for d in detail_records:
                            tid = d.get("task_id", "unknown")
                            lines.append(f"03-dossiers/task-{tid}.json")
                            lines.append(f" -> Raw output for task {tid}\n")
                        f.write("\n".join(lines))
                    for d in detail_records:
                        d_path = os.path.join(_new_dossiers, f"task-{d['task_id']}.json")
                        write_json(d_path, d)
                    with open(_new_index, "w", encoding="utf-8") as f:
                        f.write(f"""# Baseline Validation Cache — Epoch {next_epoch} (Post-Merge Refresh)

Refreshed baseline after epoch {epoch} merge.

## Navigation

- [01-summary/findings.md](01-summary/findings.md) — L1: post-merge baseline metrics
- [02-analysis/per-task-evaluation.md](02-analysis/per-task-evaluation.md) — L2: per-task validation results
- [03-dossiers/](03-dossiers/) — L3: raw validation output per task

## Provenance

- **epoch:** {next_epoch}
- **refreshed_from_epoch:** {epoch}
- **source:** post_merge_refresh
- **generated_at:** {_created}
""")
                    # Also write JSON snapshot for tool compatibility
                    write_json(os.path.join(_next_baseline_dir, "baseline.json"), refreshed_baseline_json)
                    print(f"  ✓ Post-merge validation passed: pass {bpr:.0%}→{mpr:.0%}, "
                          f"score {bsc:.2f}→{msc:.2f}")
                    print(f"  Baseline refreshed: {_new_index} "
                          f"(pass: {mpr:.0%}, quality: {pm['avg_quality_score']:.2f}, "
                          f"score: {msc:.2f})")

meta_file = os.path.join(state_dir, "board-metadata.json")
meta = load_json(meta_file)
if merge_reverted:
    meta.setdefault("validation_metric_history", []).append({
        "epoch": int(epoch),
        "merge_reverted": True,
        "pass_rate": round(mpr, 4),
        "weighted_score": round(msc, 4),
    })
    write_json(meta_file, meta)
    with open(os.path.join(state_dir, ".merge-reverted"), "w") as f:
        f.write(f"epoch={epoch}\n")
    print(f"  ⚠ Merge reverted — epoch not advanced.")
else:
    meta["epoch"] = int(epoch) + 1
    meta["last_merged_at"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    write_json(meta_file, meta)
    print(f"  Epoch incremented to: {int(epoch) + 1}")
PYEOF

        if [[ -f "$STATE_DIR/.merge-reverted" ]]; then
            rm -f "$STATE_DIR/.merge-reverted"
            echo "  Review $STATE_DIR/failed-merges.json before retrying."
            echo "  Next: run the merge phase again after addressing failures."
        else
            local next_epoch=$((EPOCH + 1))

            local initial_budget
            initial_budget=$(python3 - "$STATE_DIR/board-metadata.json" << 'PYEOF'
import json, sys
meta = json.load(open(sys.argv[1]))
initial = meta.get('initial_edit_budget', meta.get('edit_budget', 4))
print(int(initial))
PYEOF
)
            local budget_floor
            budget_floor=$(python3 - "$STATE_DIR/board-metadata.json" << 'PYEOF'
import json, sys
meta = json.load(open(sys.argv[1]))
print(int(meta.get('budget_floor', 2)))
PYEOF
)
            local max_epochs
            max_epochs=$(python3 - "$STATE_DIR/board-metadata.json" << 'PYEOF'
import json, sys
meta = json.load(open(sys.argv[1]))
print(int(meta.get('max_epochs', 4)))
PYEOF
)
            local new_budget
            new_budget=$(compute_budget "$EPOCH" "$initial_budget" "$budget_floor" "$max_epochs")

            local plateau
            plateau=$(NEW_BUDGET="$new_budget" python3 - "$STATE_DIR/board-metadata.json" "$validation_dir" "$EPOCH" << 'PYEOF'
import glob, json, os, sys

meta_file, validation_dir, epoch_s = sys.argv[1:4]
epoch = int(epoch_s)
new_budget = int(os.environ['NEW_BUDGET'])

with open(meta_file, encoding='utf-8') as f:
    meta = json.load(f)

results = []
for path in sorted(glob.glob(os.path.join(validation_dir, f"epoch-{epoch}-*.json"))):
    try:
        with open(path, encoding='utf-8') as f:
            results.append(json.load(f))
    except Exception:
        continue

accepted = sum(1 for r in results if r.get('verdict') == 'accepted')
rejected = sum(1 for r in results if r.get('verdict') != 'accepted')

def metric_value(metrics, key, default=0.0):
    try:
        return float((metrics or {}).get(key, default))
    except (TypeError, ValueError):
        return default

best = None
for r in results:
    post = r.get('post_edit_metrics') or {}
    candidate = {
        'weighted_score': metric_value(post, 'weighted_score', metric_value(post, 'pass_rate', 0.0)),
        'pass_rate': metric_value(post, 'pass_rate', 0.0),
        'avg_quality_score': metric_value(post, 'avg_quality_score', 0.0),
        'accepted': accepted,
        'rejected': rejected,
    }
    if best is None or (candidate['weighted_score'], candidate['pass_rate']) > (best['weighted_score'], best['pass_rate']):
        best = candidate

if best is None:
    best = {'weighted_score': 0.0, 'pass_rate': 0.0, 'avg_quality_score': 0.0, 'accepted': accepted, 'rejected': rejected}

entry = {
    'epoch': epoch,
    'weighted_score': round(best['weighted_score'], 4),
    'pass_rate': round(best['pass_rate'], 4),
    'avg_quality_score': round(best['avg_quality_score'], 4),
    'accepted': accepted,
    'rejected': rejected,
}

history = meta.setdefault('validation_metric_history', [])
history = [h for h in history if int(h.get('epoch', -1)) != epoch]
history.append(entry)
history.sort(key=lambda h: int(h.get('epoch', 0)))
meta['validation_metric_history'] = history

pass_history = meta.setdefault('pass_rate_history', [])
pass_history = [h for h in pass_history if int(h.get('epoch', -1)) != epoch]
pass_history.append({'epoch': epoch, 'pass_rate': entry['pass_rate'], 'accepted': accepted, 'rejected': rejected})
pass_history.sort(key=lambda h: int(h.get('epoch', 0)))
meta['pass_rate_history'] = pass_history

meta.setdefault('initial_edit_budget', int(meta.get('edit_budget', new_budget)))
meta.setdefault('budget_floor', 2)
meta.setdefault('max_epochs', 4)
meta['edit_budget'] = new_budget

with open(meta_file, 'w', encoding='utf-8') as f:
    json.dump(meta, f, indent=2, ensure_ascii=False)

recent = history[-3:]
if len(recent) >= 3:
    scores = [float(h.get('weighted_score', h.get('pass_rate', 0.0))) for h in recent]
    passes = [float(h.get('pass_rate', 0.0)) for h in recent]
    no_score_gain = scores[-1] <= scores[-2] <= scores[-3]
    no_pass_gain = passes[-1] <= passes[-2] <= passes[-3]
    print('true' if (no_score_gain and no_pass_gain) else 'false')
else:
    print('false')
PYEOF
)

            echo "  Budget for epoch $next_epoch: $new_budget edits"
            if [[ "$EPOCH" -ge "$max_epochs" ]]; then
                echo ""
                echo "Epoch $EPOCH reached max epoch threshold ($max_epochs). Triggering slow-meta phase."
                echo "Next: $0 --board $BOARD_SLUG --phase slow-meta --epoch $EPOCH"
            elif [[ "$plateau" == "true" ]]; then
                echo ""
                echo "Validation metrics plateaued across the last 3 epochs. Triggering slow-meta phase."
                echo "Next: $0 --board $BOARD_SLUG --phase slow-meta --epoch $EPOCH"
            else
                echo ""
                echo "Next: $0 --board $BOARD_SLUG --phase rollout --epoch $next_epoch"
            fi
    fi
    else
        echo "To merge, run with --exec or:"
        echo "  1. Apply each accepted edit from $validation_dir to $TARGET"
        echo "  2. Snapshot the current skill first"
        echo "  3. Increment the epoch counter in board-metadata.json"
        echo ""
        echo "Input: $validation_dir/epoch-$EPOCH-*.json"
        echo "Target: $TARGET"
        echo ""
        if [[ "$EPOCH" -ge 4 ]]; then
            echo "After merge, run slow-meta:"
            echo "  $0 --board $BOARD_SLUG --phase slow-meta --epoch $EPOCH"
        else
            echo "After merge, continue to next epoch:"
            echo "  $0 --board $BOARD_SLUG --phase rollout --epoch $((EPOCH + 1))"
        fi
    fi
}

# ============================================================
# Phase: slow-meta
# ============================================================
run_slow_meta() {
    local reflect_dir="$STATE_DIR/reflections"
    local buffer_file="$STATE_DIR/rejected-buffer.json"

    if [[ ! -f "$buffer_file" ]]; then
        echo "No rejected-edit buffer found. Creating empty buffer."
        echo "[]" > "$buffer_file"
    fi

    local rejected_count
    rejected_count=$(python3 -c "import json; print(len(json.load(open('$buffer_file'))))")
    echo "Examining rejected-edit buffer ($rejected_count rejected edits across all epochs)..."
    echo ""

    if [[ "$EXEC" == true ]]; then
        local buffer_content
        buffer_content=$(cat "$buffer_file")

        local prompt="You are analyzing the rejected-edit buffer from a SkillOpt optimization run.
These are edits that failed the validation gate — they were proposed but did not improve task performance.

=== REJECTED EDITS (full buffer) ===
${buffer_content}

Analyze these rejections and produce a meta-reflection:
1. What patterns emerge across all rejected edits?
2. Are certain types of edits (add/replace/delete) systematically failing?
3. Are failures concentrated in specific skill sections?
4. Is there an optimizer strategy adjustment you can recommend?
5. Should the optimization continue or is it at a plateau?

Output ONLY a JSON object following this schema:
{
    \"epoch\": $EPOCH,
    \"rejected_edits_reviewed\": $rejected_count,
    \"patterns_identified\": [
        {
            \"pattern\": \"description\",
            \"affected_proposals\": [\"epoch-1/edit-1\", \"epoch-2/edit-2\"],
            \"recommendation\": \"what to do differently\"
        }
    ],
    \"optimizer_strategy_adjustment\": \"specific guidance for future proposals\",
    \"recommendation\": \"continue|archive\"
}"

        local result
        result=$(run_hermes_prompt "$prompt" 2>>"$ERROR_LOG" || echo '{"error": "execution failed"}')

        echo "$result" | python3 -c "
import json, sys
raw = sys.stdin.read()
try:
    data = json.loads(raw)
except Exception:
    data = {'epoch': $EPOCH, 'error': 'parse failure', 'raw': raw}
open('$reflect_dir/slow-meta-epoch-$EPOCH.json', 'w').write(json.dumps(data, indent=2))
rec = data.get('recommendation', 'unknown')
print(f'  Meta-reflection written: $reflect_dir/slow-meta-epoch-$EPOCH.json')
print(f'  Recommendation: {rec}')
"
        # Copy slow-meta to unified pyramid and regenerate root files
        cp "$reflect_dir/slow-meta-epoch-$EPOCH.json" "$STATE_DIR/03-dossiers/epoch-$EPOCH-slowmeta.json"
        SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)" PYTHONPATH="$SCRIPTS_DIR:$PYTHONPATH" \
            EPOCH="$EPOCH" STATE_DIR="$STATE_DIR" python3 << 'PYEOF'
import os, sys; import pyramid_utils
pyramid_utils.update_root_pyramid(os.environ["STATE_DIR"], os.environ["EPOCH"])
PYEOF
    else
        echo "To run slow-meta, use --exec or:"
        echo "  Review the rejected-edit buffer at $buffer_file"
        echo "  Identify patterns across failures"
        echo "  Produce a meta-reflection document"
        echo ""
        echo "Output: $reflect_dir/slow-meta-epoch-$EPOCH.json"
        echo "See references/artifact-formats.md for the meta-reflection JSON schema."
        echo ""
        echo "After slow-meta, decide whether to:"
        echo "  - Continue to epoch $((EPOCH + 1)): $0 --board $BOARD_SLUG --phase rollout --epoch $((EPOCH + 1))"
        echo "  - Archive: $0 --board $BOARD_SLUG --phase archive"
    fi
}

# ============================================================
# Dispatch
# ============================================================

case "$PHASE" in
    rollout)   run_rollout ;;
    reflect)   run_reflect ;;
    propose)   run_propose ;;
    validate)  run_validate ;;
    merge)     run_merge ;;
    slow-meta) run_slow_meta ;;
    *)
        echo "ERROR: Unknown phase: $PHASE"
        echo "Valid phases: rollout, reflect, propose, validate, merge, slow-meta"
        exit 1
        ;;
esac
