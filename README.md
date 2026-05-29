# SkillOpt — Controlled Skill Optimization for Hermes Agent

**Optimize any agent skill document using a rigorous, methodology-driven pipeline.** Inspired by Microsoft Research's SkillOpt paper (arXiv 2605.23904), which proved that text-space optimization improves agent skills across 52/52 settings — 7 models, 6 benchmarks, and 3 agent harnesses.

## The Core Problem

Most skill development relies on reading the skill to judge its quality. **This doesn't work.** The companion SkillLens paper (arXiv 2605.23899) shows that LLM judges are 46.4% worse than chance at distinguishing effective from ineffective skills by reading them.

SkillOpt's answer: **don't evaluate the text — evaluate the execution.**

## How It Works

SkillOpt uses your Hermes Agent's built-in kanban system to run a six-phase optimization pipeline:

```
Backlog → Rollout → Reflect → Propose → Validate → Merge → Done
                                               ↓              ↑
                                          Reject Buffer ──────┘
                                           (every 4 epochs)
```

Each phase:
1. **Rollout** — Execute the skill against training tasks
2. **Reflect** — Identify systematic failure patterns
3. **Propose** — Generate 1-4 bounded edits
4. **Validate** — Test each edit against held-out tasks (the gate)
5. **Merge** — Deploy accepted edits
6. **Slow/Meta** — Learn from rejected edits every 4 epochs

## Quick Start

```bash
# 1. Install the skill (requires Hermes Agent)
hermes curator install magnus919/hermes-SkillOpt

# 2. Seed a board for your target skill
skillopt action=seed-board \
  target=~/.hermes/skills/your-skill/SKILL.md \
  training=5 validation=5

# 3. Run phases in sequence
skillopt action=run-phase --board SkillOpt-<name> --phase rollout
skillopt action=run-phase --board SkillOpt-<name> --phase reflect
skillopt action=run-phase --board SkillOpt-<name> --phase propose
skillopt action=run-phase --board SkillOpt-<name> --phase validate
skillopt action=run-phase --board SkillOpt-<name> --phase merge
```

## Design Philosophy

- **Methodology over implementation** — The phase design and validation-gate principle are the real deliverable. The scripts are wrappers around the methodology, not the other way around.
- **No new infrastructure** — Uses Hermes Agent's existing kanban system. No additional daemons, databases, or APIs.
- **Artifact contracts over context retention** — Each phase writes structured JSON to disk. Downstream phases read from disk, not from LLM context.
- **Model-agnostic** — Works with any LLM you'd normally use with Hermes. Skills optimized on one model transfer to others.

## Research Foundation

| Paper | Citation | Role |
|-------|----------|------|
| **SkillOpt** | Yifan Yang et al., arXiv 2605.23904 (2025) | Prescriptive — the optimization pipeline |
| **SkillLens** | Microsoft Research, arXiv 2605.23899 (2025) | Descriptive — why the methodology is necessary |

## License

MIT — see LICENSE file.
