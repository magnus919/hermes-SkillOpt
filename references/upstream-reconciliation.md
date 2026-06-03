# Upstream/Local SkillOpt Reconciliation

Use this when maintaining the SkillOpt repository itself: comparing an installed local checkout against a newer upstream repository version, reconciling local Hermes CLI compatibility fixes, or deciding whether a SkillOpt run exposed a target-skill defect or a SkillOpt infrastructure defect.

This is maintainer guidance for SkillOpt as a meta-skill. Do not treat it as normal target-skill optimization procedure.

## Core Rule

Do not treat upstream freshness as correctness. Use upstream as evidence, not authority. Preserve local compatibility fixes unless upstream demonstrably includes them and live Hermes verification proves the new command path works.

## Recommended Flow

1. Capture local state first:
   - save a patch of dirty changes
   - create a backup branch or equivalent rollback point
   - record any local reference files that are not tracked upstream
2. Compare by file class, not by wholesale copy:
   - runner/control-flow logic can usually follow upstream when it fixes parsing or validation defects
   - Hermes CLI compatibility wrappers must be checked against the installed `hermes --help` surface
   - docs should explain whichever behavior the verified scripts actually implement
3. Preserve known local CLI fixes:
   - verify board cleanup against the installed CLI before accepting upstream archive/remove wording
   - prefer explicit board targeting such as `--board <slug>` when task creation depends on a specific board
4. Reconcile surgically with targeted patches.
   - avoid `git pull` or copying the whole upstream tree over the local checkout when local patches are known to matter
   - keep support files (`references/`, `templates/`, `scripts/`) consistent with SKILL.md pointers
5. Verify in layers:
   - `bash -n scripts/*.sh`
   - `python -m json.tool templates/*.json`
   - `git diff --check`
   - live harmless Hermes CLI probes for every changed command form
   - stub-Hermes phase-chain smoke tests for seed/rollout/validate/merge/revert/archive behavior

## What the Smoke Test Must Prove

A syntax-only pass is insufficient. A reconciliation is not complete until a temp-state smoke test proves:

- multiline task definitions are handled as single task payloads, not split into bogus tasks
- board slug/state directory naming stays consistent
- task creation targets the expected board
- archive/cleanup uses a command accepted by the installed Hermes CLI
- cumulative merge validation can both accept a passing candidate and revert a forced regression
- shell phases (`rollout`, `reflect`, `propose`) and Python phases (`validate`, `merge`) both honor the same `HERMES` command override, including fixed args such as `HERMES='hermes --provider openai-codex -m gpt-5.5'`
- expected artifact files are written exactly once for the tested phase path

## Failure Classification

When a reconciled script fails, classify the failure before editing the target skill text:

- upstream behavior mismatch
- local Hermes CLI compatibility mismatch
- shell/runtime runner defect
- artifact schema mismatch
- actual target-skill quality regression

Only the last category belongs in SkillOpt reflection as a target-skill defect. The others are runner or environment-control defects and should be fixed in SkillOpt infrastructure first.

## Meta-Learning From SkillOpt Runs

A SkillOpt run can produce two different learning streams:

- target-skill learning: accepted/rejected edits to the skill being optimized
- SkillOpt-system learning: runner bugs, CLI drift, validation blind spots, task-artifact contamination, weak smoke tests, unclear maintainer docs

Keep these separate. Do not patch the target skill to work around SkillOpt infrastructure defects. Fix the runner, docs, smoke tests, or maintainer workflow first, then rerun or reinterpret the target-skill evidence.
