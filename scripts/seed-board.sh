#!/usr/bin/env bash
set -euo pipefail

# seed-board.sh — Create a SkillOpt kanban board for a target skill
#
# Usage:
#   seed-board.sh \
#     --target SKILL.md \
#     --training N \
#     --validation N \
#     [--train-tasks-file tasks.json] \
#     [--val-tasks-file tasks.json] \
#     [--budget N]
#
# If --*-tasks-file is provided, those tasks are loaded into the board.
# If omitted, generic task placeholders are created.

SKILLOPT_DIR="${SKILLOPT_DIR:-$HOME/.hermes/SkillOpt}"
HERMES="${HERMES:-hermes}"

show_usage() {
    sed -n '3,18p' "$0"
    exit 1
}

# --- Argument parsing ---
TARGET=""
TRAINING_COUNT=""
VALIDATION_COUNT=""
TRAIN_FILE=""
VAL_FILE=""
EDIT_BUDGET=4

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --training) TRAINING_COUNT="$2"; shift 2 ;;
        --validation) VALIDATION_COUNT="$2"; shift 2 ;;
        --train-tasks-file) TRAIN_FILE="$2"; shift 2 ;;
        --val-tasks-file) VAL_FILE="$2"; shift 2 ;;
        --budget) EDIT_BUDGET="$2"; shift 2 ;;
        --help|-h) show_usage ;;
        *) echo "Unknown option: $1"; show_usage ;;
    esac
done

# --- Validation ---

if [[ -z "$TARGET" || -z "$TRAINING_COUNT" || -z "$VALIDATION_COUNT" ]]; then
    echo "ERROR: --target, --training, and --validation are required."
    show_usage
fi

TARGET="$(cd "$(dirname "$TARGET")" 2>/dev/null && pwd)/$(basename "$TARGET")"
if [[ ! -f "$TARGET" ]]; then
    echo "ERROR: Target SKILL.md not found: $TARGET"
    exit 1
fi

SKILL_NAME="$(basename "$(dirname "$TARGET")")"
BOARD_SLUG="SkillOpt-${SKILL_NAME}"

# Check if board already exists — boards create errors if duplicate
if "$HERMES" kanban boards list 2>/dev/null | grep -q "^${BOARD_SLUG} "; then
    echo "ERROR: Board '$BOARD_SLUG' already exists for skill '$SKILL_NAME'."
    echo "Use a different board name or archive the existing one:"
    echo "  hermes kanban archive ..."
    exit 1
fi

# --- Load task definitions ---

load_tasks_json() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "ERROR: Task file not found: $file"
        exit 1
    fi
    python3 -c "
import json, sys
tasks = json.load(open(sys.argv[1]))
if not isinstance(tasks, list):
    print('ERROR: Task file must be a JSON array of task objects', file=sys.stderr)
    sys.exit(1)
for i, t in enumerate(tasks):
    if 'instruction' not in t:
        print(f'ERROR: Task {i} missing \"instruction\" field', file=sys.stderr)
        sys.exit(1)
print(json.dumps(tasks))
" "$file"
}

TRAIN_TASKS=""
VAL_TASKS=""

if [[ -n "$TRAIN_FILE" ]]; then
    TRAIN_TASKS=$(load_tasks_json "$TRAIN_FILE")
    TRAINING_COUNT=$(echo "$TRAIN_TASKS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
    echo "Loaded $TRAINING_COUNT training tasks from: $TRAIN_FILE"
fi

if [[ -n "$VAL_FILE" ]]; then
    VAL_TASKS=$(load_tasks_json "$VAL_FILE")
    VALIDATION_COUNT=$(echo "$VAL_TASKS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))")
    echo "Loaded $VALIDATION_COUNT validation tasks from: $VAL_FILE"
fi

# --- Setup state directory ---

mkdir -p "$SKILLOPT_DIR/$SKILL_NAME"/{rollouts,reflections,proposals,validation-results,snapshots}

SNAPSHOT_FILE="baseline-$(date +%Y%m%d-%H%M%S).md"
cp "$TARGET" "$SKILLOPT_DIR/$SKILL_NAME/snapshots/$SNAPSHOT_FILE"

# Write test suite definition
TEST_SUITE_FILE="$SKILLOPT_DIR/$SKILL_NAME/test-suite.json"

if [[ -z "$TRAIN_TASKS" ]]; then
    TRAIN_TASKS=$(python3 -c "
import json
tasks = []
for i in range($TRAINING_COUNT):
    tasks.append({
        'id': f'train-{i+1}',
        'instruction': f'Training task {i+1} — Execute the skill against this task and record the outcome',
        'tags': ['training']
    })
print(json.dumps(tasks))
")
fi

if [[ -z "$VAL_TASKS" ]]; then
    VAL_TASKS=$(python3 -c "
import json
tasks = []
for i in range($VALIDATION_COUNT):
    tasks.append({
        'id': f'val-{i+1}',
        'instruction': f'Validation task {i+1} — Execute the skill against this held-out task and record the outcome',
        'tags': ['validation']
    })
print(json.dumps(tasks))
")
fi

# Write test suite definition — write JSON to temp files to avoid injection in triple-quoted strings
TEST_SUITE_FILE="$SKILLOPT_DIR/$SKILL_NAME/test-suite.json"
local tmp_train
tmp_train=$(mktemp)
local tmp_val
tmp_val=$(mktemp)
echo "$TRAIN_TASKS" > "$tmp_train"
echo "$VAL_TASKS" > "$tmp_val"

python3 -c "
import json
with open('$tmp_train') as f:
    training = json.load(f)
with open('$tmp_val') as f:
    validation = json.load(f)
suite = {
    'training': training,
    'validation': validation,
    'created_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'skill_target': '$TARGET'
}
open('$TEST_SUITE_FILE', 'w').write(json.dumps(suite, indent=2))
"

rm -f "$tmp_train" "$tmp_val"

echo "Test suite written: $TEST_SUITE_FILE"

# Board metadata
cat > "$SKILLOPT_DIR/$SKILL_NAME/board-metadata.json" << EOF
{
    "target": "$TARGET",
    "skill_name": "$SKILL_NAME",
    "board_slug": "$BOARD_SLUG",
    "training_count": $TRAINING_COUNT,
    "validation_count": $VALIDATION_COUNT,
    "edit_budget": $EDIT_BUDGET,
    "epoch": 1,
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "baseline_snapshot": "$SNAPSHOT_FILE",
    "status": "active"
}
EOF

# --- Create kanban board ---

echo ""
echo "Creating board: $BOARD_SLUG for skill: $SKILL_NAME"

"$HERMES" kanban boards create "$BOARD_SLUG" \
    --name "SkillOpt: $SKILL_NAME optimization" \
    --description "Controlled optimization for ~/.hermes/skills/$SKILL_NAME/SKILL.md using the SkillOpt six-phase pipeline (rollout → reflect → propose → validate → merge → slow-meta)"

# Switch to the board for subsequent commands
"$HERMES" kanban boards switch "$BOARD_SLUG"

# Create Phase 1 rollout tasks (one per training task)
echo "$TRAIN_TASKS" | python3 -c "
import json, sys
tasks = json.load(sys.stdin)
for i, task in enumerate(tasks):
    desc = task.get('instruction', f'Training task {i+1}')
    task_id = task.get('id', f'train-{i+1}')
    print(f'TASK:{task_id}')
    print(f'DESC:{desc}')
" | while IFS= read -r line; do
    case "$line" in
        TASK:*) CURRENT_TASK="${line#TASK:}";;
        DESC:*)
            local body_file
            body_file=$(mktemp)
            cat > "$body_file" << BODYEOF
Rollout task ${CURRENT_TASK} for '${SKILL_NAME}' (epoch 1).

State: ${SKILLOPT_DIR}/${SKILL_NAME}/rollouts/epoch-1-${CURRENT_TASK}.json

Task: ${DESC}

Execute the skill at ${TARGET} against this task.
Record: task description, execution trace, outcome (success/failure), and any observed failure modes.
Output: JSON following the rollout record schema in references/artifact-formats.md
BODYEOF

            "$HERMES" kanban create "Rollout: ${CURRENT_TASK}" \
                --body "$(cat "$body_file")" \
                --priority 3 \
                --created-by "skillopt"
            rm -f "$body_file"
            ;;
    esac
done

# Create validation baseline task
"$HERMES" kanban create "Validation: establish baseline metrics" \
    --body "Run the $VALIDATION_COUNT validation tasks (defined in $TEST_SUITE_FILE) with the current skill at $TARGET. Record metrics as the baseline for future comparison.

State: $SKILLOPT_DIR/$SKILL_NAME/validation-results/baseline.json" \
    --priority 1 \
    --created-by "skillopt"

# Switch back to default board so subsequent non-SkillOpt commands aren't confused
"$HERMES" kanban boards switch default 2>/dev/null || true

echo ""
echo "Board created: $BOARD_SLUG"
echo "State directory: $SKILLOPT_DIR/$SKILL_NAME/"
echo "Baseline snapshot: $SNAPSHOT_FILE"
echo "Test suite: $TEST_SUITE_FILE"
echo ""
echo "Switch to the board:"
echo "  hermes kanban boards switch $BOARD_SLUG"
echo "List tasks:"
echo "  hermes kanban list"
echo ""
echo "Run the first rollout phase:"
echo "  run-phase.sh --board $BOARD_SLUG --phase rollout --epoch 1"
