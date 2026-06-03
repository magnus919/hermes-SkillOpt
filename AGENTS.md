# SkillOpt — Agent Guide

## Overview

SkillOpt is a methodology skill that any Hermes Agent can load to run controlled optimization cycles on any skill document. It uses the built-in kanban system as its execution substrate.

## Where It Lives

- Skill: `~/.hermes/skills/skillopt/`
- Per-target state: `~/.hermes/SkillOpt/<skill-name>/`

## Key Files

- `SKILL.md` — The methodology document. Changes affect what users and agents see when loading the skill.
- `scripts/seed-board.sh` — Board creation (power-user CLI alternative)
- `scripts/run-phase.sh` — Phase execution (power-user CLI alternative)
- `scripts/archive-run.sh` — Run cleanup (power-user CLI alternative)
- `references/methodology-guide.md` — Deep research rationale
- `references/test-suite-design.md` — Task selection guidance
- `references/artifact-formats.md` — JSON schemas for all phase outputs
- `references/size-objective-compaction.md` — Size/token-footprint optimization guidance
- `references/upstream-reconciliation.md` — Maintainer guidance for reconciling upstream changes, local Hermes CLI compatibility fixes, and SkillOpt-system defects

## How to Use This Skill in a Conversation

When a user says they want to optimize a skill:

1. Load this skill with `skill_view(name='skillopt')` to access the methodology
2. Guide the user through defining 3-5 training and 3-5 validation tasks
3. Call `hermes kanban boards create` with the proper lowercase `skillopt-<skill-slug>` slug and description
4. Create rollout tasks with `hermes kanban --board <slug> create "Rollout: ..." --body "..." --priority 3`
5. Run each phase: rollouts via `hermes -z`/`--oneshot`, reflections by reviewing artifacts, proposals by analyzing failure patterns, validation by comparing before/after pass rate, quality score, speed, and token-efficiency metrics. For large skills, pass skill paths in prompts instead of inlining full SKILL.md content to avoid Linux per-argument limits.
6. Apply accepted edits to the target skill file
7. Report results conversationally

## Meta-learning from SkillOpt Runs

A SkillOpt run can produce two different learning streams:

- **Target-skill learning:** accepted/rejected edits to the skill being optimized.
- **SkillOpt-system learning:** runner bugs, Hermes CLI drift, validation blind spots, artifact contamination, weak smoke tests, or documentation-boundary problems in this repo.

Keep these separate. Do not treat SkillOpt infrastructure failures as target-skill defects. For upstream/local reconciliation and CLI-compatibility decisions, use `references/upstream-reconciliation.md`.

## File Conventions

- All shell scripts use `set -euo pipefail`
- Script names are `kebab-case.sh`
- Phase artifact JSON schemas are documented in `references/artifact-formats.md`
- Board slugs follow `skillopt-<skill-slug>` format, where `<skill-slug>` is lowercase kebab-case
- State directories follow `~/.hermes/SkillOpt/<skill-slug>/`

## Change Workflow

1. File an issue describing the change
2. Branch from main
3. Make changes (SKILL.md, scripts, references)
4. Run tests: `bash -n scripts/*.sh`, parse `templates/*.json`, verify documented Hermes CLI subcommands against `hermes --help`, and run a temp-state stub-Hermes smoke test for rollout → reflect → propose → validate → merge
5. Open a PR
6. Wait for review
7. Merge

## License

MIT — contributions welcome.
