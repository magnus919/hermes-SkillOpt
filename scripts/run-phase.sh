#!/usr/bin/env bash
set -euo pipefail

# run-phase.sh — Execute a single pipeline phase
#
# Usage:
#   run-phase.sh --board <board-slug> --phase <phase-name> [--epoch N]
#
# Phases: rollout, reflect, propose, validate, merge, slow-meta
#
# Each phase reads artifacts from ~/.hermes/SkillOpt/<skill-name>/<phase-dir>/
# and writes its output back to the same state directory.

SKILLOPT_DIR="${SKILLOPT_DIR:-$HOME/.hermes/SkillOpt}"
HERMES="${HERMES:-hermes}"

show_usage() {
    sed -n '3,12p' "$0"
    exit 1
}

BOARD_SLUG=""
PHASE=""
EPOCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --board) BOARD_SLUG="$2"; shift 2 ;;
        --phase) PHASE="$2"; shift 2 ;;
        --epoch) EPOCH="$2"; shift 2 ;;
        --help|-h) show_usage ;;
        *) echo "Unknown option: $1"; show_usage ;;
    esac
done

if [[ -z "$BOARD_SLUG" || -z "$PHASE" ]]; then
    echo "ERROR: --board and --phase are required."
    show_usage
fi

# Derive skill name from board slug (strip "SkillOpt-" prefix)
SKILL_NAME="${BOARD_SLUG#SkillOpt-}"
STATE_DIR="$SKILLOPT_DIR/$SKILL_NAME"

if [[ ! -f "$STATE_DIR/board-metadata.json" ]]; then
    echo "ERROR: State directory not found for board '$BOARD_SLUG'."
    echo "Expected: $STATE_DIR/board-metadata.json"
    exit 1
fi

EPOCH="${EPOCH:-1}"
METADATA_FILE="$STATE_DIR/board-metadata.json"
EDIT_BUDGET="${EDIT_BUDGET:-4}"

echo "SkillOpt: $PHASE phase for $SKILL_NAME (epoch $EPOCH)"

case "$PHASE" in
    rollout)
        echo "Executing rollout phase..."
        echo "  State: $STATE_DIR/rollouts/"
        echo "  The optimizer should execute each training task using the current skill"
        echo "  and record (task, trace, outcome) to epoch-$EPOCH-task-N.json files."
        echo ""
        echo "NOTE: Phase execution is currently manual."
        echo "Run each Rollout task on the kanban board manually."
        echo "When all rollout tasks are complete, run:"
        echo "  run-phase.sh --board $BOARD_SLUG --phase reflect --epoch $EPOCH"
        ;;

    reflect)
        ROLLOUT_DIR="$STATE_DIR/rollouts"
        REFLECT_DIR="$STATE_DIR/reflections"
        mkdir -p "$REFLECT_DIR"

        ROLLOUT_COUNT=$(ls "$ROLLOUT_DIR"/epoch-"$EPOCH"-task-*.json 2>/dev/null | wc -l)
        if [[ "$ROLLOUT_COUNT" -eq 0 ]]; then
            echo "ERROR: No rollout records found for epoch $EPOCH."
            echo "Run the rollout phase first."
            exit 1
        fi

        echo "Reflecting on $ROLLOUT_COUNT rollout records..."
        echo "  Writing reflection to: $REFLECT_DIR/epoch-$EPOCH.json"
        echo ""
        echo "NOTE: Phase execution is currently manual."
        echo "Review the rollout records and produce a reflection document."
        echo "When done, run:"
        echo "  run-phase.sh --board $BOARD_SLUG --phase propose --epoch $EPOCH"
        ;;

    propose)
        REFLECT_DIR="$STATE_DIR/reflections"
        PROPOSAL_DIR="$STATE_DIR/proposals"
        mkdir -p "$PROPOSAL_DIR"

        if [[ ! -f "$REFLECT_DIR/epoch-$EPOCH.json" ]]; then
            echo "ERROR: No reflection document found for epoch $EPOCH."
            echo "Run the reflect phase first."
            exit 1
        fi

        echo "Proposing up to $EDIT_BUDGET edits based on reflection..."
        echo "  Writing proposals to: $PROPOSAL_DIR/epoch-$EPOCH.json"
        echo ""
        echo "Each proposal should include: type (add/replace/delete),"
        echo "location (section/line), old_text/new_text, and rationale."
        echo ""
        echo "NOTE: Phase execution is currently manual."
        echo "When proposals are ready, run:"
        echo "  run-phase.sh --board $BOARD_SLUG --phase validate --epoch $EPOCH"
        ;;

    validate)
        PROPOSAL_DIR="$STATE_DIR/proposals"
        VALIDATION_DIR="$STATE_DIR/validation-results"
        mkdir -p "$VALIDATION_DIR"

        if [[ ! -f "$PROPOSAL_DIR/epoch-$EPOCH.json" ]]; then
            echo "ERROR: No proposals found for epoch $EPOCH."
            echo "Run the propose phase first."
            exit 1
        fi

        echo "Validating each proposed edit against held-out tasks..."
        echo "  Writing results to: $VALIDATION_DIR/"
        echo ""
        echo "For each proposed edit:"
        echo "  1. Snapshot the current skill"
        echo "  2. Apply the edit to a copy"
        echo "  3. Run validation tasks with the edited skill"
        echo "  4. Compare against baseline metrics"
        echo "  5. Accept or reject"
        echo ""
        echo "NOTE: Phase execution is currently manual."
        echo "When validation is complete, run:"
        echo "  run-phase.sh --board $BOARD_SLUG --phase merge --epoch $EPOCH"
        ;;

    merge)
        VALIDATION_DIR="$STATE_DIR/validation-results"
        METADATA=$(cat "$METADATA_FILE")

        ACCEPTED=$(ls "$VALIDATION_DIR"/epoch-"$EPOCH"-*-accepted* 2>/dev/null | wc -l || echo 0)
        REJECTED=$(ls "$VALIDATION_DIR"/epoch-"$EPOCH"-*-rejected* 2>/dev/null | wc -l || echo 0)

        echo "Merging $ACCEPTED accepted edits (${REJECTED} rejected)..."
        echo "  Apply accepted edits to: $(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['target'])")"
        echo ""

        if [[ "$EPOCH" -ge 4 ]]; then
            echo "Epoch $EPOCH reached. Triggering slow-meta phase."
            echo "  After merge, run:"
            echo "  run-phase.sh --board $BOARD_SLUG --phase slow-meta --epoch $EPOCH"
        else
            echo "After merge, increment epoch and run rollout for epoch $((EPOCH + 1)):"
            echo "  run-phase.sh --board $BOARD_SLUG --phase rollout --epoch $((EPOCH + 1))"
        fi
        ;;

    slow-meta)
        REJECTED_BUFFER="$STATE_DIR/rejected-buffer.json"
        REFLECT_DIR="$STATE_DIR/reflections"

        if [[ ! -f "$REJECTED_BUFFER" ]]; then
            echo "WARNING: No rejected-edit buffer found. Creating initial buffer."
            echo "[]" > "$REJECTED_BUFFER"
        fi

        echo "Running slow-meta phase for $SKILL_NAME (epoch $EPOCH)..."
        echo "  Rejected-edit buffer: $REJECTED_BUFFER"
        echo "  Writing meta-reflection to: $REFLECT_DIR/slow-meta-epoch-$EPOCH.json"
        echo ""
        echo "The meta-reflection should identify patterns across all rejected edits:"
        echo "  - What kinds of edits systematically fail validation?"
        echo "  - Are failures concentrated in specific skill sections?"
        echo "  - Is there a structural issue the per-epoch optimizer isn't addressing?"
        echo ""
        echo "NOTE: Phase execution is currently manual."
        echo "When done, decide whether to continue to epoch $((EPOCH + 1)) or archive."
        ;;

    *)
        echo "ERROR: Unknown phase: $PHASE"
        echo "Valid phases: rollout, reflect, propose, validate, merge, slow-meta"
        exit 1
        ;;
esac
