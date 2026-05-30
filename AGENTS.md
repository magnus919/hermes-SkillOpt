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

## How to Use This Skill in a Conversation

When a user says they want to optimize a skill:

1. Load this skill with `skill_view(name='SkillOpt')` to access the methodology
2. Guide the user through defining 3-5 training and 3-5 validation tasks
3. Call `hermes kanban boards create` with the proper columns and labels
4. Run each phase: rollouts via `hermes oneshot`, reflections by reviewing artifacts, proposals by analyzing failure patterns, validation by comparing before/after metrics
5. Apply accepted edits to the target skill file
6. Report results conversationally

## File Conventions

- All shell scripts use `set -euo pipefail`
- Script names are `kebab-case.sh`
- Phase artifact JSON schemas are documented in `references/artifact-formats.md`
- Board slugs follow `SkillOpt-<skill-name>` format
- State directories follow `~/.hermes/SkillOpt/<skill-name>/`

## Change Workflow

1. File an issue describing the change
2. Branch from main
3. Make changes (SKILL.md, scripts, references)
4. Run tests: `bash -n scripts/*.sh`
5. Open a PR
6. Wait for review
7. Merge

## License

MIT — contributions welcome.
