#!/usr/bin/env bash
set -euo pipefail

# archive-run.sh — Finalize a SkillOpt run
#
# Usage:
#   archive-run.sh --board <board-slug> [--keep-state]
#
# Normally cleans up the kanban board but preserves state directory.
# Use --keep-state to preserve the board for review.

SKILLOPT_DIR="${SKILLOPT_DIR:-$HOME/.hermes/SkillOpt}"
HERMES="${HERMES:-hermes}"

show_usage() {
    sed -n '3,8p' "$0"
    exit 1
}

BOARD_SLUG=""
KEEP_STATE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --board) BOARD_SLUG="$2"; shift 2 ;;
        --keep-state) KEEP_STATE=true; shift ;;
        --help|-h) show_usage ;;
        *) echo "Unknown option: $1"; show_usage ;;
    esac
done

if [[ -z "$BOARD_SLUG" ]]; then
    show_usage
fi

SKILL_NAME="${BOARD_SLUG#SkillOpt-}"
STATE_DIR="$SKILLOPT_DIR/$SKILL_NAME"

if [[ ! -f "$STATE_DIR/board-metadata.json" ]]; then
    echo "WARNING: No state directory found for '$SKILL_NAME'."
fi

# Generate a run summary
if [[ -f "$STATE_DIR/board-metadata.json" ]]; then
    METADATA=$(cat "$STATE_DIR/board-metadata.json")
    TARGET=$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['target'])")
    EPOCH=$(echo "$METADATA" | python3 -c "import sys,json; print(json.load(sys.stdin)['epoch'])")

    SUMMARY_FILE="$STATE_DIR/run-summary.json"
    cat > "$SUMMARY_FILE" << EOF
{
    "skill_name": "$SKILL_NAME",
    "target": "$TARGET",
    "final_epoch": $EPOCH,
    "archived_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "state_dir": "$STATE_DIR"
}
EOF
    echo "Run summary written to: $SUMMARY_FILE"
fi

# Archive the board
if "$HERMES" kanban boards list 2>/dev/null | grep -qF "$BOARD_SLUG"; then
    echo "Archiving board: $BOARD_SLUG"
    "$HERMES" kanban boards archive "$BOARD_SLUG" 2>/dev/null || \
        echo "  (board archived manually)"
else
    echo "Board '$BOARD_SLUG' not found — may already be archived."
fi

echo ""
echo "Run archived successfully."
echo "State preserved at: $STATE_DIR"
echo ""
if [[ "$KEEP_STATE" == true ]]; then
    echo "Board preserved for review (--keep-state was set)."
else
    echo "Board cleaned up. To restore: seed-board.sh --target $TARGET ... --budget ..."
fi
