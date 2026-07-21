# Post-SkillOpt Commit Catch-Up

## The Problem

SkillOpt's Phase 5 (Merge) applies accepted edits to the working skill document
in-place using `patch`/`write_file`. After a multi-epoch SkillOpt run, the
improvements are all live on disk but **unstaged and uncommitted** — they sit
on whatever branch the working tree was on (often `main`) with no branch
context, no commit history, and no PR.

When you return to the repo later, `git status` shows modified files with no
indication of why they changed or what epoch produced them. The improvements
are invisible to git's history.

## Worked Example: Groktocrawl Skill (2026-05-30)

A 4-epoch SkillOpt run on `skills/groktocrawl/` applied improvements across:

- v1.1.0: download command, PATH-vs-script clarification
- v1.2.0: browser lifecycle, extraction examples, cross-command chaining
- v1.3.0: structured extraction workflow, session ID plumbing
- v1.4.0: monitor/parse/generate-llmstxt, fallback chain, domain exploration

The Merge phase applied all edits to the working files. After the SkillOpt
kanban board showed all epochs complete, `git status` showed 3 modified files
on `main` with no branch context.

### Detection

```bash
cd /Volumes/tank01/magnus/git/groktocrawl
git status --short
# M skills/groktocrawl/SKILL.md
#  M skills/groktocrawl/assets/examples.md
#  M skills/groktocrawl/scripts/groktocrawl

git diff --stat
# 3 files changed, 331 insertions(+), 88 deletions(-)
```

### Recovery — Branch, Commit, PR

```bash
# 1. Branch from main (captures the dirty state)
git checkout -b feat/skillopt-epoch-5-skills

# 2. Stage the skill directory (not other accidental changes)
git add skills/groktocrawl/

# 3. Commit with changelog in the body
git commit -m "feat: SkillOpt Epoch 5 — groktocrawl skill document optimization

Combined improvements from SkillOpt Epochs 1-4 applied to the groktocrawl
skill:

- v1.1.0: Add download command, clarify PATH-vs-script CLI path
- v1.2.0: Add browser session lifecycle guidance, extraction examples
- v1.3.0: Add full structured extraction workflow with session ID plumbing
- v1.4.0: Add monitor/parse/generate-llmstxt CLI subcommands, fallback chain"

# 4. Push and create PR
git push -u upstream HEAD
gh pr create \
  --base main \
  --head feat/skillopt-epoch-5-skills \
  --title "feat: SkillOpt Epoch 5 — groktocrawl skill optimization" \
  --body-file /tmp/pr-body.md
```

### Prevention

After the **Merge phase of the final epoch**, immediately run:

```bash
# Check if the target skill has uncommitted changes
cd path/to/repo
if [ -n "$(git status --porcelain -- skills/target-skill/)" ]; then
  echo "WARNING: SkillOpt changes are unstaged. Creating branch..."
  git checkout -b feat/skillopt-$(basename skills/target-skill)-epoch-$(cat epoch-counter)
  git add skills/target-skill/
  git commit -m "feat: SkillOpt Epoch N — target-skill optimization"
  echo "Branch created. Open a PR when ready."
fi
```

Add this as a step at the end of Phase 5 in the run-phase.sh script or as a
manual step the agent executes after the kanban pipeline completes.

## Key Principles

1. **The "Done" column on the kanban board is not a git commit.** The board
   tracks methodology progress; git tracks code history. Don't confuse them.
2. **Branch BEFORE committing** — you need a feature branch to PR from.
   Committing to main then branching creates a confusing baseline.
3. **Include the changelog in the commit body** — the epoch history is valuable
   context for reviewers and future maintainers.
4. **One PR per SkillOpt run** — don't break epoch improvements into separate
   PRs unless the reviewer requests it.
