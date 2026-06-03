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

slugify() {
    # Keep archive cleanup aligned with seed-board.sh and Hermes' board slug
    # normalization: lowercase kebab-case, no underscores or mixed case.
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
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

RAW_SKILL_NAME="${BOARD_SLUG#skillopt-}"
RAW_SKILL_NAME="${RAW_SKILL_NAME#SkillOpt-}"
SKILL_SLUG="$(slugify "$RAW_SKILL_NAME")"
BOARD_SLUG_CLI="skillopt-${SKILL_SLUG}"
SKILL_NAME="$RAW_SKILL_NAME"
STATE_DIR="$SKILLOPT_DIR/$SKILL_SLUG"

# Backward-compatible read path for runs created by older local versions that
# used the raw skill directory name instead of the slugified state directory.
if [[ ! -f "$STATE_DIR/board-metadata.json" && -f "$SKILLOPT_DIR/$RAW_SKILL_NAME/board-metadata.json" ]]; then
    STATE_DIR="$SKILLOPT_DIR/$RAW_SKILL_NAME"
fi

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

# Remove/archive the board unless explicitly preserved for review. Current
# Hermes exposes this as `boards rm`; `boards archive` is not a valid boards
# subcommand in the installed CLI.
if [[ "$KEEP_STATE" == true ]]; then
    echo "Board preserved for review (--keep-state was set): $BOARD_SLUG_CLI"
elif "$HERMES" kanban boards list 2>/dev/null | grep -qF "$BOARD_SLUG_CLI"; then
    echo "Removing board: $BOARD_SLUG_CLI"
    "$HERMES" kanban boards rm "$BOARD_SLUG_CLI"
else
    echo "Board '$BOARD_SLUG_CLI' not found — may already be archived."
fi

echo ""
echo "Run archived successfully."
echo "State preserved at: $STATE_DIR"
echo ""
if [[ "$KEEP_STATE" == true ]]; then
    echo "Board preserved for review (--keep-state was set)."
else
    echo "Board cleaned up. To restore: seed-board.sh --target ${TARGET:-<target-skill>} ... --budget ..."
fi
