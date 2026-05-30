---
name: SkillOpt
description: Run controlled skill optimization cycles on any skill document. Uses kanban-based pipelines with validation gates — the methodology from Microsoft Research's SkillOpt (arXiv 2605.23904).
version: 1.0.0-alpha
author: Jasper (on behalf of Magnus Hedemark)
license: MIT
compatibility: Hermes Agent only — uses hermes kanban and hermes oneshot — not compatible with Claude Code, Copilot, OpenCode, or Cursor
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [optimization, skills, kanban, methodology, validation, agent-skills]
    related_skills: [kanban-orchestrator, kanban-worker, plan]
    requires_toolsets: [terminal, kanban]
source_repo: "https://github.com/magnus919/hermes-SkillOpt"
---

# SkillOpt — Controlled Skill Optimization for Hermes Agent

Optimize any Hermes skill document using a rigorous, methodology-driven pipeline inspired by Microsoft Research's SkillOpt paper (Yifan Yang et al., 2025). The core insight: **evaluate skill changes by measuring task execution, not by reading the skill text.**

## When to Use This Skill

- A skill exists but its performance is inconsistent — sometimes it works, sometimes it doesn't
- You want to improve a skill but aren't sure which changes will actually help
- You've proposed edits to a skill and want to validate them before deploying
- You maintain multiple skills and want a repeatable process for quality improvement
- You're curious whether a skill change actually improved anything (the surface-plausibility trap)

**SkillOpt is designed for skills with measurable task outcomes.** For creative skills (image generation, writing) where "correctness" is subjective, the methodology still works but the validation criteria need thoughtful definition.

## How It Works

SkillOpt treats a skill document like a parameter vector in text-space. Instead of gradient descent, it uses a six-phase **kanban pipeline** that runs on your Hermes Agent's existing infrastructure:

```
Backlog → Rollout → Reflect → Propose → Validate → Merge → Done
                                               ↓              ↑
                                          Reject Buffer ──────┘
                                           (every 4 epochs)
```

Each phase produces structured artifacts. Downstream phases read these artifacts from disk — nothing depends on LLM context retention across phases.

### The Validation-Gate Principle

The single most important idea in this skill comes from the companion SkillLens paper (arXiv 2605.23899): **surface plausibility is not predictive of skill effectiveness.** LLM judges are 46.4% worse than chance at distinguishing effective from ineffective skills by reading them. Format has no significant effect (p > 0.34).

This means: **do not evaluate skill changes by reading the skill.** Evaluate by running it. The validation gate — a held-out set of tasks that the skill has never seen — is the only reliable quality signal.

Training and validation task sets MUST be distinct. This is not optional.

### The Six Phases

#### 1. Rollout — Execute the current skill against training tasks

The target LLM (any model you'd normally use with Hermes) executes a set of training tasks using the current skill document. Each trajectory produces a (task, execution trace, outcome) triple.

**Entry:** Current skill document + training task suite
**Exit:** N trajectory records (one per training task)

#### 2. Reflect — Identify systematic failure patterns

Review the rollout trajectories in a batch. Identify what went wrong, under what conditions, and what kind of change would address those failures. Batching prevents overfitting to any single failure mode.

**Entry:** Trajectory records from Phase 1
**Exit:** Reflection document with identified failure patterns categorized by frequency and severity

#### 3. Propose — Generate bounded edits

Based on the reflection, propose 1-4 specific, targeted edits to the skill document. Each edit is a concrete text operation: add a line, replace a clause, delete an instruction. The edit budget is the textual analogue of a learning rate — it prevents large destabilizing changes.

**Entry:** Reflection document
**Exit:** Proposed edits (1-4), each with: type (add/replace/delete), location, old_text/new_text, rationale

#### 4. Validate — Test each edit against held-out tasks

This is the heart of the methodology. Apply each proposed edit to a copy of the skill. Run the validation task suite with the edited skill. Compare against the baseline metrics. Accept edits that improve or maintain performance. Reject the rest.

**Entry:** Proposed edits + validation task suite + baseline metrics
**Exit:** Accepted edits (merged into deployment candidate) + rejected edits (stored in buffer with rationale and metrics)

#### 5. Merge — Deploy accepted changes

Apply all accepted edits to the working skill document. Update the baseline snapshot. Increment the epoch counter. If this is epoch 4 or validation gains have plateaued, trigger the slow-meta phase.

**Entry:** Deployment candidate (accepted edits)
**Exit:** Updated skill document + new baseline snapshot

#### 6. Slow/Meta — Learn from rejected edits (every 4 epochs)

The optimizer reflects on the accumulated rejected-edit buffer — all proposals that failed validation across recent epochs. Look for patterns: are you proposing the same kind of edit that keeps failing? Is there a structural issue the per-epoch optimizer isn't addressing? This produces a strategy refinement, not a direct skill edit.

**Entry:** Rejected-edit buffer (accumulated across epochs)
**Exit:** Meta-reflection document — optimizer strategy adjustments, structural observations

### Epoch Structure and Edit Budget

A full optimization run consists of 4 epochs by default. Each epoch follows the Rollout → Reflect → Propose → Validate → Merge cycle.

- **Default edit budget:** 4 edits per epoch (matching the paper's optimal Lt=4)
- **Budget decay:** Cosine decay to a floor of 2 edits per epoch
- **Epoch 4 or plateau:** Trigger the slow-meta phase

The edit budget is configurable in `board-metadata.json` under `edit_budget`.

## Quick Start

1. **One-time install** — clone the repo into your skills directory:
   ```bash
   git clone https://github.com/magnus919/hermes-SkillOpt \
     ~/.hermes/skills/skillopt/SkillOpt
   ```

2. **In a conversation** with your agent, say something like:
   ```
   I want to optimize my vault-note skill.
   ```

3. The agent loads this skill via `skill_view(name='SkillOpt')`, guides you through defining training and validation tasks, seeds the kanban board, and orchestrates the six-phase pipeline — reporting results at each stage.

## Scripts — Power Users Only

The primary interface for SkillOpt is conversational — your agent drives the pipeline. These shell scripts exist for power users who want to run phases from the command line instead. The agent ignores them and uses `hermes oneshot` + `hermes kanban` directly.

| Script | What it does | 
|--------|-------------|
| `scripts/seed-board.sh` | Create kanban board, state directory, baseline snapshot |
| `scripts/run-phase.sh` | Execute a single pipeline phase (rollout/reflect/propose/validate/merge/slow-meta) |
| `scripts/archive-run.sh` | Finalize a run, store metrics, clean up the board |

## References

| Reference | What it covers |
|-----------|----------------|
| `references/methodology-guide.md` | Deep rationale for every phase — why each exists, what failure it prevents, the research it's based on |
| `references/test-suite-design.md` | How to pick training and validation tasks for different skill types |
| `references/artifact-formats.md` | JSON schemas for every intermediate artifact across all phases |

## Templates

| Template | Purpose |
|----------|---------|
| `templates/board.json` | Kanban board specification — columns, labels, task dependencies |
| `templates/test-suite.json` | JSON schema for defining a test suite |

## Design Principles

1. **Training and validation sets must be distinct.** This is the non-negotiable methodological requirement. Without it, you're measuring memorization, not improvement.

2. **Evaluate execution, not text.** Never ask an LLM to judge a skill change by reading it. Run it against actual tasks.

3. **Edits are bounded per epoch.** The edit budget (default 4) prevents large destabilizing changes. Think of it as a learning rate for skill text.

4. **Rejected edits are preserved.** Every rejected edit — with its rationale and validation metrics — goes into the buffer. These become the input to the slow-meta phase, turning failures into learning signals.

5. **The optimizer and target can be the same model.** The paper shows same-model optimization still produces strong gains. A more capable optimizer helps, but it's not required.

## Pitfalls

- **Not separating training and validation sets.** This is the most common mistake and the most damaging. If your validation tasks overlap with training tasks, the validation gate tells you nothing about generalization.

- **Skipping the validation gate.** The gate is not optional. It's the only thing preventing the optimizer from overfitting to the training batch. If you merge edits without validation, you're optimizing by feel — exactly what the SkillLens paper shows is unreliable.

- **Unbounded edits.** An optimizer that can rewrite the entire skill will introduce skill drift — removing working patterns while trying to fix failures. The bounded-edit strategy exists for this reason.

- **Running epochs without plateau detection.** After 4 epochs, if the validation metric isn't improving, you've reached a plateau. Continuing to run epochs past this point wastes compute and risks overfitting. The slow-meta phase exists to handle this.

- **Applying the methodology to skills without measurable outcomes.** If you can't define what "working" looks like for a skill (e.g., "write a better image prompt"), the validation gate has nothing to measure. For these skills, use the methodology loosely — define correctness as "produces valid output in the expected format."

## Attribution

This skill implements the methodology described in:

- **SkillOpt:** Yifan Yang et al., "Controllable Text-Space Optimization for Agent Skills" (arXiv 2605.23904, 2025)
- **SkillLens:** Microsoft Research, "A Systematic Study of Model-Generated Agent Skills" (arXiv 2605.23899, 2025)

The kanban execution substrate is provided by Hermes Agent. The methodology is model-agnostic and framework-agnostic — the kanban implementation is Hermes-native but the phase design applies to any agent skill optimization workflow.

## License

MIT — see LICENSE file.
