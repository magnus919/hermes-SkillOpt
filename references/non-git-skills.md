# SkillOpt for Local-Only (Non-Git) Skills

## The Problem

Not every skill you optimize lives in a git repository. Skills installed directly into `~/.hermes/skills/` have no version control, no branch context, and no PR workflow. The standard SkillOpt post-merge commit step is inapplicable.

## When This Applies

- Skills listed in `~/.hermes/skills/` that have no `.git` directory
- Skills installed by copying files rather than cloning
- Skills where `git status` returns `fatal: not a git repository`

## Workflow

### Merge Phase (Phase 5)

Apply edits directly via `patch`/`write_file`. No branch, no PR, no commit. Changes go live immediately.

### Version Tracking

Without git, use frontmatter version field:

1. **If the skill has no version field yet**, add one during Epoch 1 as part of your first merge. Start at `1.0.0`.
2. **Bump on each subsequent merge** using semantic versioning:
   - `patch` (x.y.z → x.y.z+1): Additive fixes, workflow scaffolding, documentation — the default for most SkillOpt epochs.
   - `minor` (x.y.z → x.y+1.0): New features, structural changes, breaking reorgs.
3. **Save a baseline snapshot** before and after each epoch for rollback:
   ```bash
   cp path/to/SKILL.md ~/.hermes/skills/skillopt/state/<skill>-v1.0.0-baseline.md
   ```
4. **Keep a changelog** in the state directory.

## Verification

After applying edits to a non-git skill:

1. **Reload via `skill_view`** and confirm the version bumped.
2. **Run a regression check** — execute one validation task.
3. **Update the baseline snapshot.**

## When to Migrate to Git

If a local-only skill receives 3+ SkillOpt epochs or is used daily, consider:

```bash
cd ~/.hermes/skills/<category>/
git init && git add <skill-name>/ && git commit -m "init: <skill-name>"
```

This unlocks the full post-merge commit workflow (rollback, diffing, PR history).
