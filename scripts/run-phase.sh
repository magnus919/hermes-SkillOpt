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
# attempts to execute the phase using hermes oneshot.

SKILLOPT_DIR="${SKILLOPT_DIR:-$HOME/.hermes/SkillOpt}"
HERMES="${HERMES:-hermes}"

show_usage() {
    sed -n '3,14p' "$0"
    exit 1
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

SKILL_NAME="${BOARD_SLUG#SkillOpt-}"
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
    train_tasks=$(python3 -c "
import json
suite = json.load(open('$TEST_SUITE'))
for t in suite.get('training', []):
    print(f\"{t.get('id', 'unknown')}|{t.get('instruction', 'No instruction')}\")
")

    if [[ -z "$train_tasks" ]]; then
        echo "ERROR: No training tasks defined in test suite."
        exit 1
    fi

    echo "Rollout phase: execute the skill against each training task"
    echo "Training tasks found: $(echo "$train_tasks" | wc -l | tr -d ' ')"
    echo ""

    # Check existing rollouts
    local completed=0
    local pending=0
    while IFS='|' read -r task_id task_desc; do
        [[ -z "$task_id" ]] && continue
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
        # Execute pending rollouts via hermes oneshot
        while IFS='|' read -r task_id task_desc; do
            [[ -z "$task_id" ]] && continue
            local output_file="$rollout_dir/epoch-$EPOCH-$task_id.json"
            [[ -f "$output_file" ]] && continue

            echo "  Executing rollout: $task_id..."
            local skill_content
            skill_content=$(cat "$TARGET")

            local prompt="You are running a controlled skill optimization cycle.
Your task is to execute the following skill document against a specific task.

=== SKILL DOCUMENT ===
${skill_content}

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
            result=$("$HERMES" oneshot -z -m "$prompt" 2>/dev/null || echo '{"outcome": "failure", "failure_modes": ["execution error"], "output_summary": "oneshot command failed"}')

            # Try to extract JSON from the response
            echo "$result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
except:
    data = {'outcome': 'failure', 'failure_modes': ['parse error'], 'output_summary': 'Could not parse JSON from response', 'raw_response': sys.stdin.read()}
data['task_id'] = '$task_id'
data['epoch'] = $EPOCH
open('$output_file', 'w').write(json.dumps(data, indent=2))
print(f'    Wrote: $output_file')
" 2>/dev/null || echo "    Warning: Could not parse rollout output for $task_id"
        done

        # Re-count
        completed=0
        for f in "$rollout_dir/epoch-$EPOCH-"*.json; do
            [[ -f "$f" ]] && completed=$((completed + 1))
        done
        echo ""
        echo "Rollout complete: $completed records written."
    else
        # Print guidance
        echo "To execute rollouts, run with --exec or run the following for each task:"
        while IFS='|' read -r task_id task_desc; do
            [[ -z "$task_id" ]] && continue
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
    fi
}

# ============================================================
# Phase: reflect
# ============================================================
run_reflect() {
    local rollout_dir="$STATE_DIR/rollouts"
    local reflect_dir="$STATE_DIR/reflections"
    mkdir -p "$reflect_dir"

    local rollout_files
    rollout_files=$(ls "$rollout_dir"/epoch-"$EPOCH"-*.json 2>/dev/null || true)
    if [[ -z "$rollout_files" ]]; then
        echo "ERROR: No rollout records found for epoch $EPOCH."
        echo "Run rollout phase first."
        exit 1
    fi

    local count
    count=$(echo "$rollout_files" | wc -l | tr -d ' ')
    echo "Reflecting on $count rollout records..."
    echo ""

    if [[ "$EXEC" == true ]]; then
        # Aggregate rollouts into a reflection prompt
        local rollouts_json
        rollouts_json=$(python3 -c "
import json, glob
records = []
for f in sorted(glob.glob('$rollout_dir/epoch-$EPOCH-*.json')):
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
        result=$("$HERMES" oneshot -z -m "$prompt" 2>/dev/null || echo '{"error": "execution failed"}')

        echo "$result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
except:
    data = {'epoch': $EPOCH, 'error': 'parse failure', 'raw': sys.stdin.read()}
open('$reflect_dir/epoch-$EPOCH.json', 'w').write(json.dumps(data, indent=2))
print(f'  Reflection written: $reflect_dir/epoch-$EPOCH.json')
" 2>/dev/null || echo "  Warning: Could not parse reflection output"
    else
        echo "To generate a reflection, run with --exec or:"
        echo "  $HERMES oneshot -z -m \"Review the rollout records in \$SKILLOPT_DIR/$SKILL_NAME/rollouts/ and produce a structured reflection\""
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

    if [[ ! -f "$reflect_dir/epoch-$EPOCH.json" ]]; then
        echo "ERROR: No reflection document found for epoch $EPOCH."
        echo "Run reflect phase first."
        exit 1
    fi

    echo "Proposing up to $EDIT_BUDGET edits based on reflection..."
    echo ""

    if [[ "$EXEC" == true ]]; then
        local reflection
        reflection=$(cat "$reflect_dir/epoch-$EPOCH.json")
        local skill_content
        skill_content=$(cat "$TARGET")

        local prompt="You are proposing edits to improve a skill document based on rollout analysis.

=== CURRENT SKILL DOCUMENT ===
${skill_content}

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
        result=$("$HERMES" oneshot -z -m "$prompt" 2>/dev/null || echo '{"error": "execution failed"}')

        echo "$result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
except:
    data = {'epoch': $EPOCH, 'error': 'parse failure'}
open('$proposal_dir/epoch-$EPOCH.json', 'w').write(json.dumps(data, indent=2))
proposals = data.get('proposals', [])
print(f'  Proposals written: $proposal_dir/epoch-$EPOCH.json ({len(proposals)} edits)')
" 2>/dev/null || echo "  Warning: Could not parse proposal output"
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
        local proposals
        proposals=$(cat "$proposal_dir/epoch-$EPOCH.json")
        local skill_content
        skill_content=$(cat "$TARGET")
        local val_tasks
        val_tasks=$(python3 -c "
import json
suite = json.load(open('$TEST_SUITE'))
print(json.dumps(suite.get('validation', []), indent=2))
")

        # For each proposal, apply and test
        python3 << 'PYEOF'
import json, os, subprocess, sys

proposals = json.loads(os.environ.get('PROPOSALS_JSON', '{}'))
skill_content = os.environ.get('SKILL_CONTENT', '')
val_tasks = json.loads(os.environ.get('VAL_TASKS_JSON', '[]'))
epoch = os.environ.get('EPOCH', '1')
target = os.environ.get('TARGET_PATH', '')
val_dir = os.environ.get('VAL_DIR', '')

edits = proposals.get('proposals', [])
results = []

for i, edit in enumerate(edits):
    edit_id = edit.get('id', f'edit-{i+1}')
    edit_type = edit.get('type', 'replace')
    location = edit.get('location', '')
    old_text = edit.get('old_text', '')
    new_text = edit.get('new_text', '')

    # Apply edit to a copy of the skill
    edited_skill = skill_content
    if edit_type == 'replace' and old_text:
        edited_skill = skill_content.replace(old_text, new_text, 1)
    elif edit_type == 'add' and new_text:
        edited_skill = skill_content + '\n' + new_text
    elif edit_type == 'delete' and old_text:
        edited_skill = skill_content.replace(old_text, '', 1)

    # Run each validation task against the edited skill
    val_passed = 0
    val_failed = 0
    val_details = []

    for task in val_tasks:
        task_id = task.get('id', 'unknown')
        task_inst = task.get('instruction', '')

        prompt = f"""Evaluate this skill document against the following task.

=== EDITED SKILL DOCUMENT ===
{edited_skill}

=== TASK ===
{task_inst}

Does this skill successfully handle this task? Respond with ONLY a JSON object:
{{"pass": true/false, "reason": "brief explanation"}}"""

        try:
            result = subprocess.run(
                ['hermes', 'oneshot', '-z', '-m', prompt],
                capture_output=True, text=True, timeout=120
            )
            try:
                verdict = json.loads(result.stdout.strip())
            except:
                verdict = {"pass": False, "reason": "parse error"}

            if verdict.get("pass", False):
                val_passed += 1
            else:
                val_failed += 1
            val_details.append({"task_id": task_id, "result": verdict})
        except:
            val_failed += 1
            val_details.append({"task_id": task_id, "result": {"pass": False, "reason": "execution error"}})

    total = len(val_tasks)
    pass_rate = val_passed / total if total > 0 else 0

    result_record = {
        "epoch": epoch,
        "proposal_id": edit_id,
        "edit_type": edit_type,
        "validation_tasks_run": total,
        "baseline_metrics": {"pass_rate": 0.0},
        "post_edit_metrics": {"pass_rate": round(pass_rate, 2)},
        "verdict": "accepted" if pass_rate >= 0.5 else "rejected",
        "validation_detail": val_details
    }

    out_file = os.path.join(val_dir, f"epoch-{epoch}-{edit_id}.json")
    with open(out_file, 'w') as f:
        json.dump(result_record, f, indent=2)

    print(f"  {edit_id}: {result_record['verdict']} (pass rate: {pass_rate:.0%})")
    results.append(result_record)

# Summary
accepted = sum(1 for r in results if r['verdict'] == 'accepted')
rejected = sum(1 for r in results if r['verdict'] == 'rejected')
print(f"  Result: {accepted} accepted, {rejected} rejected")

# Update rejected buffer if any
if rejected > 0:
    buffer_file = os.path.join(os.path.dirname(val_dir), 'rejected-buffer.json')
    buffer = []
    if os.path.exists(buffer_file):
        with open(buffer_file) as f:
            buffer = json.load(f)
    for r in results:
        if r['verdict'] == 'rejected':
            buffer.append(r)
    with open(buffer_file, 'w') as f:
        json.dump(buffer, f, indent=2)
    print(f"  Rejected edits appended to: {buffer_file}")
PYEOF
    else:
        echo "To run validation, use --exec or:"
        echo "  1. Create a copy of the target skill"
        echo "  2. Apply each proposed edit to the copy"
        echo "  3. Run the validation tasks from $TEST_SUITE against each edited copy"
        echo "  4. Compare results against baseline"
        echo ""
        echo "Input: $proposal_dir/epoch-$EPOCH.json"
        echo "Output: $validation_dir/epoch-$EPOCH-*.json"
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

    local accepted_files
    accepted_files=$(ls "$validation_dir"/epoch-"$EPOCH"-*.json 2>/dev/null || true)
    if [[ -z "$accepted_files" ]]; then
        echo "ERROR: No validation results found for epoch $EPOCH."
        echo "Run validate phase first."
        exit 1
    fi

    if [[ "$EXEC" == true ]]; then
        python3 << 'PYEOF'
import json, os, glob

epoch = os.environ.get('EPOCH', '1')
target = os.environ.get('TARGET_PATH', '')
val_dir = os.environ.get('VAL_DIR', '')
snapshots_dir = os.environ.get('SNAPSHOTS_DIR', '')
state_dir = os.environ.get('STATE_DIR', '')

# Read current skill
with open(target) as f:
    skill = f.read()

# Snapshot before merge
snapshot = os.path.join(snapshots_dir, f"pre-merge-epoch-{epoch}-$(date +%Y%m%d-%H%M%S).md")
with open(snapshot, 'w') as f:
    f.write(skill)

accepted = 0
rejected = 0

for f in sorted(glob.glob(os.path.join(val_dir, f"epoch-{epoch}-*.json"))):
    result = json.load(open(f))
    if result.get('verdict') == 'accepted':
        # Apply the edit
        edit = result
        proposal_id = edit.get('proposal_id', '')
        # Find the original proposal to get old/new text
        proposal_file = os.path.join(state_dir, 'proposals', f"epoch-{epoch}.json")
        if os.path.exists(proposal_file):
            proposals = json.load(open(proposal_file))
            for p in proposals.get('proposals', []):
                if p.get('id') == proposal_id:
                    edit_type = p.get('type', 'replace')
                    old_text = p.get('old_text', '')
                    new_text = p.get('new_text', '')
                    if edit_type == 'replace' and old_text:
                        skill = skill.replace(old_text, new_text, 1)
                        print(f"  Applied: {proposal_id} ({edit_type})")
                        accepted += 1
                    elif edit_type == 'add' and new_text:
                        skill = skill + '\n' + new_text
                        print(f"  Applied: {proposal_id} ({edit_type})")
                        accepted += 1
                    elif edit_type == 'delete' and old_text:
                        skill = skill.replace(old_text, '', 1)
                        print(f"  Applied: {proposal_id} ({edit_type})")
                        accepted += 1
    else:
        rejected += 1
        # Save to rejected buffer
        buffer_file = os.path.join(state_dir, 'rejected-buffer.json')
        buffer = []
        if os.path.exists(buffer_file):
            with open(buffer_file) as f:
                buffer = json.load(f)
        buffer.append(result)
        with open(buffer_file, 'w') as f:
            json.dump(buffer, f, indent=2)

# Write updated skill
with open(target, 'w') as f:
    f.write(skill)

print(f"  Merged: {accepted} edits, {rejected} rejected")
print(f"  Snapshot saved: {snapshot}")

# Update metadata epoch counter
meta_file = os.path.join(state_dir, 'board-metadata.json')
meta = json.load(open(meta_file))
meta['epoch'] = int(epoch) + 1
meta['last_merged_at'] = os.popen('date -u +%Y-%m-%dT%H:%M:%SZ').read().strip()
with open(meta_file, 'w') as f:
    json.dump(meta, f, indent=2)
print(f"  Epoch incremented to: {int(epoch) + 1}")
PYEOF

        local next_epoch=$((EPOCH + 1))
        if [[ "$EPOCH" -ge 4 ]]; then
            echo ""
            echo "Epoch $EPOCH reached. Triggering slow-meta phase."
            echo "Next: $0 --board $BOARD_SLUG --phase slow-meta --epoch $EPOCH"
        else
            echo ""
            echo "Next: $0 --board $BOARD_SLUG --phase rollout --epoch $next_epoch"
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
        result=$("$HERMES" oneshot -z -m "$prompt" 2>/dev/null || echo '{"error": "execution failed"}')

        echo "$result" | python3 -c "
import json, sys
try:
    data = json.loads(sys.stdin.read())
except:
    data = {'epoch': $EPOCH, 'error': 'parse failure'}
open('$reflect_dir/slow-meta-epoch-$EPOCH.json', 'w').write(json.dumps(data, indent=2))
rec = data.get('recommendation', 'unknown')
print(f'  Meta-reflection written: $reflect_dir/slow-meta-epoch-$EPOCH.json')
print(f'  Recommendation: {rec}')
" 2>/dev/null || echo "  Warning: Could not parse meta-reflection output"
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
