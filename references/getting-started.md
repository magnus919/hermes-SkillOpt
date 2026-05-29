# Getting Started — Your First SkillOpt Run

This walkthrough takes you from a fresh Hermes install through your first completed SkillOpt optimization run.

## Prerequisites

- Hermes Agent installed and configured
- Kanban system available (run `hermes kanban boards list` to verify)
- A target skill document at a known path
- 3-5 training tasks and 3-5 validation tasks defined (see test-suite-design.md)

## Step 1: Install the Skill

```bash
# Via curator (recommended)
hermes curator install magnus919/hermes-SkillOpt

# Or manually
git clone https://github.com/magnus919/hermes-SkillOpt ~/.hermes/skills/skillopt/SkillOpt
```

## Step 2: Load the Skill

In a new Hermes session or a session where you want to run SkillOpt:

```
/load SkillOpt
```

Or include it in your session's skill configuration.

## Step 3: Define Your Test Suite

Create a test suite for your target skill. For a first run, use the Small configuration (3 training + 3 validation tasks). See `references/test-suite-design.md` for guidance on choosing tasks.

Example — optimizing a blog post creation skill:
- Training task 1: "Write a post about Python typing from this outline"
- Training task 2: "Write a post about Docker networking from this outline"
- Training task 3: "Write a post about test-driven development from this outline"

- Validation task 1: "Write a post about async Python from this outline"
- Validation task 2: "Write a post about CI/CD pipelines from this outline"
- Validation task 3: "Write a post about API design from this outline"

## Step 4: Seed the Board

```bash
skillopt action=seed-board \
  target=~/.hermes/skills/content/hugo-blog/SKILL.md \
  training=3 validation=3
```

This creates:
- A kanban board named `SkillOpt-hugo-blog`
- A state directory at `~/.hermes/SkillOpt/hugo-blog/`
- 3 Rollout tasks in the Rollout column
- A baseline skill snapshot

## Step 5: Run Epoch 1

```bash
# Phase 1 — Execute training tasks with the current skill
# (Run each Rollout task on the board)
skillopt action=run-phase --board SkillOpt-hugo-blog --phase rollout --epoch 1

# Phase 2 — Review rollouts, identify failure patterns
skillopt action=run-phase --board SkillOpt-hugo-blog --phase reflect --epoch 1

# Phase 3 — Propose 1-4 edits based on reflections
skillopt action=run-phase --board SkillOpt-hugo-blog --phase propose --epoch 1

# Phase 4 — Validate each edit against held-out tasks
skillopt action=run-phase --board SkillOpt-hugo-blog --phase validate --epoch 1

# Phase 5 — Merge accepted edits
skillopt action=run-phase --board SkillOpt-hugo-blog --phase merge --epoch 1
```

## Step 6: Iterate (Epochs 2-4)

Repeat the rollout → reflect → propose → validate → merge cycle for epochs 2, 3, and 4.

After epoch 4, run the slow-meta phase:

```bash
skillopt action=run-phase --board SkillOpt-hugo-blog --phase slow-meta --epoch 4
```

## Step 7: Archive

```bash
skillopt action=archive-run --board SkillOpt-hugo-blog
```

Your optimized skill is at the target path. The run summary and all artifacts are preserved in `~/.hermes/SkillOpt/<skill-name>/`.

## What to Expect

For most skills, the biggest gains come in epochs 1-2, with marginal refinement in epochs 3-4. If you see no improvement after 2 epochs, your test suite may need refinement — the tasks may not be measuring the skill's actual function.
