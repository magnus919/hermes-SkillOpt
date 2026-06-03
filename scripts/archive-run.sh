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

    # Regenerate the root artifact pyramid via the shared function
    # (inline Python that mirrors update_root_pyramid from run-phase.sh)
    EPOCH_VAL="$EPOCH" STATE_DIR_VAL="$STATE_DIR" python3 << 'PYEOF'
import json, os
state_dir = os.environ["STATE_DIR_VAL"]
epoch = os.environ["EPOCH_VAL"]
dossiers_dir = os.path.join(state_dir, "03-dossiers")
os.makedirs(os.path.join(state_dir, "01-summary"), exist_ok=True)
os.makedirs(os.path.join(state_dir, "02-analysis"), exist_ok=True)

epochs = set()
phase_map = {}
if os.path.isdir(dossiers_dir):
    for fname in sorted(os.listdir(dossiers_dir)):
        if not fname.endswith(".json"):
            continue
        parts = fname.split("-", 2)
        if len(parts) >= 2 and parts[0] == "epoch":
            e = parts[1]
            epochs.add(e)
            phase = parts[2].split("-")[0] if len(parts) > 2 else "unknown"
            phase_map.setdefault(e, {}).setdefault(phase, []).append(fname)

epochs_sorted = sorted(epochs, key=int)
meta_path = os.path.join(state_dir, "board-metadata.json")
board_meta = json.load(open(meta_path)) if os.path.exists(meta_path) else {}

# 00-index.md
idx = ["# SkillOpt Run", "", "## Navigation", "",
       "- [01-summary/findings.md](01-summary/findings.md) — L1: run summary"]
for e in epochs_sorted:
    idx.append(f"- [02-analysis/epoch-{e}-overview.md](02-analysis/epoch-{e}-overview.md) — L2: epoch {e}")
idx += ["", "## Provenance", "",
        f"- total_epochs: {len(epochs_sorted)}",
        f"- generated_by: SkillOpt archive",
        f"- generated_at: archive time"]
with open(os.path.join(state_dir, "00-index.md"), "w") as f:
    f.write("\n".join(idx) + "\n")

# 01-summary/findings.md
target = board_meta.get("target", "unknown")
skill_name = os.path.basename(os.path.dirname(target)) if target != "unknown" else "unknown"
history = board_meta.get("pass_rate_history", [])
final_pr = history[-1]["pass_rate"] if history else "N/A"
summary = f"""---
final_epoch: {int(epochs_sorted[-1]) if epochs_sorted else 0}
skill_name: {skill_name}
target: {target}
total_epochs: {len(epochs_sorted)}
final_pass_rate: {final_pr}
---

# Run Summary

**Skill:** {skill_name}
**Final epoch:** {epochs_sorted[-1] if epochs_sorted else 'N/A'}
**Total epochs:** {len(epochs_sorted)}

## SOURCES (LAYER 2 NAVIGATION)
"""
for e in epochs_sorted:
    summary += f"02-analysis/epoch-{e}-overview.md\n -> Epoch {e} results\n"
with open(os.path.join(state_dir, "01-summary", "findings.md"), "w") as f:
    f.write(summary)

# 02-analysis/epoch-trajectory.md
traj = ["# Epoch Trajectory", "",
        "| Epoch | Pass Rate | Accepted | Rejected |",
        "|---|---|---|---|"]
for entry in history:
    ep = entry.get("epoch", "")
    pr = entry.get("pass_rate", "N/A")
    traj.append(f"| {ep} | {pr} | {entry.get('accepted', '')} | {entry.get('rejected', '')} |")
traj.append("")
with open(os.path.join(state_dir, "02-analysis", "epoch-trajectory.md"), "w") as f:
    f.write("\n".join(traj) + "\n")

# Per-epoch overviews
for e in epochs_sorted:
    phases = phase_map.get(e, {})
    lines = [f"# Epoch {e} Overview", ""]
    for pname in ("baseline", "rollout", "reflection", "proposal", "validation", "slowmeta"):
        files = phases.get(pname, [])
        if files:
            lines.append(f"**{pname.title()}:** {len(files)} dossier(s)")
    lines.append("")
    lines.append("## SOURCES (LAYER 3 NAVIGATION)")
    for pname in ("baseline", "rollout", "reflection", "proposal", "validation", "slowmeta"):
        for fname in phases.get(pname, []):
            lines.append(f"03-dossiers/{fname}")
            lines.append(f" -> {pname} dossier for epoch {e}")
    with open(os.path.join(state_dir, "02-analysis", f"epoch-{e}-overview.md"), "w") as f:
        f.write("\n".join(lines) + "\n")

print(f"  Root pyramid regenerated: {os.path.join(state_dir, '00-index.md')} ({len(epochs_sorted)} epochs)")
PYEOF
    echo "Run pyramid archived."
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
