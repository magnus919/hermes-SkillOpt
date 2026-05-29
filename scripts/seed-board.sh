#!/usr/bin/env bash
set -euo pipefail

# seed-board.sh — Create a SkillOpt kanban board for a target skill
#
# Usage:
#   seed-board.sh --target SKILL.md --training N --validation N [--budget N]
#
# Prerequisites:
#   - Hermes Agent CLI on PATH
#   - Kanban system available (hermes kanban boards)
#
# Example:
#   seed-board.sh \
#     --target ~/.hermes/skills/content/hugo-blog/SKILL.md \
#     --training 5 \
#     --validation 5

SKILLOPT_DIR="${SKILLOPT_DIR:-$HOME/.hermes/SkillOpt}"
HERMES="${HERMES:-hermes}"

show_usage() {
    sed -n '3,10p' "$0"
    exit 1
}

# --- Argument parsing ---
TARGET=""
TRAINING_COUNT=""
VALIDATION_COUNT=""
EDIT_BUDGET=4

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target) TARGET="$2"; shift 2 ;;
        --training) TRAINING_COUNT="$2"; shift 2 ;;
        --validation) VALIDATION_COUNT="$2"; shift 2 ;;
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

# Extract the skill name from the target path
SKILL_NAME="$(basename "$(dirname "$TARGET")")"
BOARD_SLUG="SkillOpt-${SKILL_NAME}"

# Check if this board already exists
if "$HERMES" kanban boards list 2>/dev/null | grep -q "$BOARD_SLUG"; then
    echo "ERROR: Board '$BOARD_SLUG' already exists for skill '$SKILL_NAME'."
    echo "Run 'archive-run.sh' first to finalize the existing run."
    exit 1
fi

# --- Setup ---

mkdir -p "$SKILLOPT_DIR/$SKILL_NAME"/{rollouts,reflections,proposals,validation-results,snapshots}

# Baseline snapshot
SNAPSHOT_FILE="baseline-$(date +%Y%m%d-%H%M%S).md"
cp "$TARGET" "$SKILLOPT_DIR/$SKILL_NAME/snapshots/$SNAPSHOT_FILE"

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

echo "Creating board: $BOARD_SLUG for skill: $SKILL_NAME"

"$HERMES" kanban boards create "$BOARD_SLUG" \
    --columns "Backlog,Rollout,Reflect,Propose,Validate,Merge,Rejected-Buffer" \
    --labels "phase:rollout,phase:reflect,phase:propose,phase:validate,phase:merge,phase:slow-meta,status:in-progress,status:pending-validation,status:accepted,status:rejected"

# Create Phase 1 rollout tasks
for i in $(seq 1 "$TRAINING_COUNT"); do
    TASK_BODY="Rollout task $i of $TRAINING_COUNT for '$SKILL_NAME' (epoch 1).

State: $SKILLOPT_DIR/$SKILL_NAME/rollouts/epoch-1-task-$i.json

Execute the skill at $TARGET against training task $i.
Record: task description, execution trace, outcome (success/failure), and any observed failure modes.
Output: JSON to the state path above."
    
    echo "$TASK_BODY" | "$HERMES" kanban create "$BOARD_SLUG" \
        --column "Rollout" \
        --title "Rollout: training task $i" \
        --label "phase:rollout"
done

# Create a Validation task stub
"$HERMES" kanban create "$BOARD_SLUG" \
    --column "Backlog" \
    --title "Validation: establish baseline metrics" \
    --label "status:pending-validation" \
    --body "Run the $VALIDATION_COUNT validation tasks with the current skill at $TARGET. Record metrics as the baseline for future comparison."

echo ""
echo "Board created: $BOARD_SLUG"
echo "State directory: $SKILLOPT_DIR/$SKILL_NAME/"
echo "Baseline snapshot: $SNAPSHOT_FILE"
echo ""
echo "Next: run-phase.sh --board $BOARD_SLUG --phase rollout --epoch 1"
