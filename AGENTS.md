# SkillOpt — Agent Guide

## Overview

SkillOpt is a methodology skill that any Hermes Agent can load to run controlled optimization cycles on any skill document. It uses the built-in kanban system as its execution substrate.

## Where Things Live

After install, the skill lives at one of:

- `~/.hermes/skills/skillopt/SkillOpt/` — manual clone install
- `~/.hermes/skills/` — curator install (may use a category directory)

Per-target state directories go in `~/.hermes/SkillOpt/<skill-name>/`.

## Skills to Load When Working on This Project

| Task | Load This Skill |
|------|-----------------|
| Modifying the methodology | `plan` (read-only mode for methodology changes) |
| Adding scripts | `terminal` (shell scripting patterns) |
| Creating references | Any content authoring skill |
| Releasing to GitHub | `github-pr-workflow`, `opensource-contributions` |

## Key Files

- `SKILL.md` — The methodology document. Any changes here affect what users and agents see when they load the skill.
- `scripts/seed-board.sh` — Board creation and state initialization
- `scripts/run-phase.sh` — Unified phase runner
- `scripts/archive-run.sh` — Run completion and cleanup
- `references/methodology-guide.md` — Deep research rationale
- `references/test-suite-design.md` — Task selection guidance
- `references/artifact-formats.md` — JSON schemas for all phase outputs

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
