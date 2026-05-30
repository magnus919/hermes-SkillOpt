# Getting Started — Your First SkillOpt Run

This walkthrough takes you from install through your first completed SkillOpt optimization run.

## Prerequisites

- Hermes Agent installed and configured
- Kanban system available (your agent will check this)
- A target skill you want to optimize
- A few minutes to work with your agent on defining test tasks

## Step 1: Install the Skill

```bash
git clone https://github.com/magnus919/hermes-SkillOpt ~/.hermes/skills/skillopt/SkillOpt
```

That's the only shell command you'll need. Everything from here is conversation with your agent.

## Step 2: Start an Optimization

In a regular conversation with your Hermes Agent, say:

```
I want to optimize my hugo-blog skill using SkillOpt.
```

The agent will load the SkillOpt methodology and begin the guided process.

## Step 3: Define Your Test Suite

Your agent will ask you for training and validation tasks. These are concrete examples of what the skill should do well. For a first run, 3 training + 3 validation tasks is a good start.

Example conversation:

> **Agent:** Let's set up a SkillOpt optimization for hugo-blog. I'll need a few training tasks that represent the skill's core function, and a few different validation tasks for the gate.
>
> Can you describe 3 training tasks? These are tasks the skill should handle well.
>
> **You:** Write three blog posts about Python, Docker, and TDD from outlines.
>
> **Agent:** Great. And 3 validation tasks — different but related?
>
> **You:** Write posts about async Python, CI/CD, and API design.

See `test-suite-design.md` for detailed guidance on choosing good tasks.

## Step 4: The Agent Runs the Pipeline

Once the test suite is defined, the agent:

1. **Seeds** the kanban board and state directory
2. **Rolls out** each training task using the current skill
3. **Reflects** on the results to find failure patterns
4. **Proposes** 1-4 targeted edits to the skill
5. **Validates** each edit against the held-out validation tasks
6. **Merges** the accepted edits
7. **Reports** back with a summary of what changed

The agent drives each phase, showing you the results at natural checkpoints.

## Step 5: Iterate

After epoch 1, the agent will ask if you want to continue. Epochs 2-4 repeat the cycle, each time building on the previous improvements.

After epoch 4, the agent runs the slow-meta phase — analyzing the rejected-edit buffer to identify deeper patterns and recommend whether to continue or archive.

## Step 6: Review Results

Your agent will summarize:
- How many edits were proposed and accepted per epoch
- What specific changes were made to the skill
- The measured improvement on the validation set

The optimization artifacts (rollouts, reflections, proposals, validation results) are preserved at `~/.hermes/SkillOpt/<skill-name>/` for future reference.

## What to Expect

For most skills, the biggest gains come in epochs 1-2, with marginal refinement in epochs 3-4. If you see no improvement after 2 epochs, your test suite may need refinement — the tasks may not be measuring the skill's actual function.
