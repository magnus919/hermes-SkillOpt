"""Shared utilities for the SkillOpt unified artifact pyramid.

Extracted from PYEOF blocks in run-phase.sh. Import with:

    import sys, os
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), "scripts"))
    import pyramid_utils
    pyramid_utils.update_root_pyramid(state_dir, epoch)
"""

import json
import os
from datetime import datetime, timezone


def load_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def write_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def update_root_pyramid(state_dir, epoch):
    """Scan 03-dossiers/ and rewrite root-level pyramid files (00-index, 01-summary, 02-analysis).
    Called after any phase writes new dossiers."""
    dossiers_dir = os.path.join(state_dir, "03-dossiers")
    os.makedirs(os.path.join(state_dir, "01-summary"), exist_ok=True)
    os.makedirs(os.path.join(state_dir, "02-analysis"), exist_ok=True)

    # Discover all epoch-N-* files in dossiers
    epochs = set()
    phase_map = {}  # epoch -> {phase: [filenames]}
    if os.path.isdir(dossiers_dir):
        for fname in sorted(os.listdir(dossiers_dir)):
            if not fname.endswith(".json"):
                continue
            # Parse epoch-N-phase-item.json
            parts = fname.split("-", 2)
            if len(parts) >= 2 and parts[0] == "epoch":
                e = parts[1]
                epochs.add(e)
                phase = parts[2].split("-")[0] if len(parts) > 2 else "unknown"
                phase_map.setdefault(e, {}).setdefault(phase, []).append(fname)

    epochs_sorted = sorted(epochs, key=int)
    created = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Read board metadata for trajectory
    meta_path = os.path.join(state_dir, "board-metadata.json")
    board_meta = load_json(meta_path) if os.path.exists(meta_path) else {}

    # — 00-index.md — navigation + provenance
    index_lines = [
        "# SkillOpt Run", "",
        "## Navigation", "",
        "- [01-summary/findings.md](01-summary/findings.md) — L1: run summary",
    ]
    for e in epochs_sorted:
        index_lines.append(
            f"- [02-analysis/epoch-{e}-overview.md](02-analysis/epoch-{e}-overview.md) — L2: epoch {e}"
        )
    index_lines += [
        "", "## Provenance", "",
        f"- total_epochs: {len(epochs_sorted)}",
        "- generated_by: SkillOpt unified pyramid",
        f"- generated_at: {created}",
    ]
    with open(os.path.join(state_dir, "00-index.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(index_lines) + "\n")

    # — 01-summary/findings.md — L1
    target = board_meta.get("target", "unknown")
    skill_name = os.path.basename(os.path.dirname(target)) if target != "unknown" else "unknown"
    history = board_meta.get("pass_rate_history", [])
    final_pr = history[-1]["pass_rate"] if history else "N/A"
    final_num = int(epochs_sorted[-1]) if epochs_sorted else 0

    summary = f"""---
final_epoch: {final_num}
skill_name: {skill_name}
target: {target}
total_epochs: {len(epochs_sorted)}
final_pass_rate: {final_pr}
---

# Run Summary

**Skill:** {skill_name}
**Final epoch:** {final_num}
**Total epochs:** {len(epochs_sorted)}

## SOURCES (LAYER 2 NAVIGATION)
"""
    for e in epochs_sorted:
        summary += f"02-analysis/epoch-{e}-overview.md\n -> Epoch {e} results\n"
    with open(os.path.join(state_dir, "01-summary", "findings.md"), "w", encoding="utf-8") as f:
        f.write(summary)

    # — 02-analysis/epoch-trajectory.md — across-epoch trends
    traj = [
        "# Epoch Trajectory", "",
        "| Epoch | Pass Rate | Quality | Score | Accepted | Rejected |",
        "|---|---|---|---|---|---|",
    ]
    for entry in history:
        ep = entry.get("epoch", "")
        pr = entry.get("pass_rate", "N/A")
        traj.append(f"| {ep} | {pr} | | | {entry.get('accepted', '')} | {entry.get('rejected', '')} |")
    traj.append("")
    traj.append("## SOURCES (LAYER 2 NAVIGATION)")
    for e in epochs_sorted:
        traj.append(f"epoch-{e}-overview.md")
        traj.append(f" -> Epoch {e} overview")
    with open(os.path.join(state_dir, "02-analysis", "epoch-trajectory.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(traj) + "\n")

    # — 02-analysis/epoch-<N>-overview.md — per epoch
    for e in epochs_sorted:
        phases = phase_map.get(e, {})
        lines = [f"# Epoch {e} Overview", "", f"**Epoch:** {e}"]
        for pname, label in [
            ("baseline", "Baseline"),
            ("rollout", "Rollout"),
            ("reflection", "Reflection"),
            ("proposal", "Proposals"),
            ("validation", "Validation"),
            ("slowmeta", "Slow-meta"),
        ]:
            files = phases.get(pname, [])
            if files:
                lines.append(f"**{label}:** {len(files)} dossier(s)")
        lines.append("")
        lines.append("## SOURCES (LAYER 3 NAVIGATION)")
        for pname in ("baseline", "rollout", "reflection", "proposal", "validation", "slowmeta"):
            for fname in phases.get(pname, []):
                lines.append(f"03-dossiers/{fname}")
                lines.append(f" -> {pname} dossier for epoch {e}")
        with open(os.path.join(state_dir, "02-analysis", f"epoch-{e}-overview.md"), "w", encoding="utf-8") as f:
            f.write("\n".join(lines) + "\n")

    print(f"  Root pyramid updated: {os.path.join(state_dir, '00-index.md')} ({len(epochs_sorted)} epochs)")
