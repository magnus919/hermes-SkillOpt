# Methodology Guide — Deep Rationale

## Why Each Phase Exists

### Rollout — Gather Evidence Before Acting

Without a rollout phase, you're editing skills based on intuition about what's wrong. The rollout captures actual execution traces — evidence of what the skill actually does, not what you think it does. This prevents the common failure mode of "I think this isn't working" when the skill is actually fine.

### Reflect — Find Signals in Noise

Individual task failures are noisy. A model might fail one task for model-specific reasons (attention drift, prompt format sensitivity) while succeeding on similar tasks. Batching rollouts and reflecting across them separates the signal (systematic failure patterns) from the noise (idiosyncratic failures). This is directly analogous to minibatch gradient computation in neural networks — individual samples are too noisy, but the batch gradient points in a useful direction.

### Propose — Bound the Learning Rate

Unconstrained skill editing is like setting the learning rate to infinity — the optimizer can change everything at once, often breaking working behaviors while trying to fix broken ones. The bounded-edit budget (default 4) acts as a textual learning rate. The SkillOpt paper shows this is not arbitrary: Lt=4 outperforms Lt=16 (overfitting) and Lt=1 (too slow to converge) by significant margins across three benchmarks.

### Validate — The Non-Negotiable Check

This is the heart of the methodology. The SkillLens paper proves that evaluating skill quality by reading the text is worse than useless — LLM judges are 46.4% worse than chance at distinguishing effective from ineffective skills. The validation gate is the only reliable signal. It directly measures what matters: does the edited skill produce better task outcomes on unseen data?

SkillOpt should not collapse "better" to pass/fail alone. Pass/fail remains the primary hard gate, but useful skill changes also affect output quality, completion speed, and token use. The local runner computes a weighted score from pass rate, `quality_score`, measured duration, and token estimate, with pass/fail weighted highest.

### Merge — Lock in Gains

Each accepted edit is a verified improvement. Merging them one epoch at a time creates a monotonic improvement trajectory — the skill never gets worse. This is the textual analogue of gradient descent's monotonic improvement property (with a small enough learning rate).

### Slow/Meta — Learn from What Didn't Work

Rejected edits are not failures — they're information. The slow-meta phase examines the entire rejected-edit buffer for meta-patterns: "Am I proposing the same kind of edit that keeps failing?" This is the analogue of adaptive optimizers (Adam, RMSProp) that accumulate gradient history to adjust per-parameter learning rates.

## The Research Foundation

This methodology is derived from two Microsoft Research papers:

### SkillOpt (arXiv 2605.23904)
- First systematic controllable text-space optimizer for agent skills
- 52/52 settings improved across 7 models, 6 benchmarks, 3 harnesses
- Key design patterns adopted: bounded-edit strategy, validation gate, rejected-edit buffer, slow/meta updates

### SkillLens (arXiv 2605.23899)
- Systematic study of model-generated agent skills across 5 domains, 6 models, 3 RQs
- Surface plausibility is not predictive — LLM judges 46.4% worse than chance
- Format inertness — no significant effect of skill structure on performance (p > 0.34)
- Meta-skill guided extraction produces validated gains; surface-focus rubrics produce negative results

## Why Not Just Read the Skill?

A skill document is an intervention in an LLM's behavior. Its effect depends on:
- How the consuming model interprets the instructions
- The task structure (what constitutes success)
- The execution context (environment, tools, available actions)
- The skill's actual content (what it says to do)

Surface features (coherence, formatting, specificity of language) are only weakly correlated with how these factors combine. A beautifully written instruction can be wrong; an awkwardly written one can be exactly right. The only way to know is to test.

## When the Methodology Works Best

- **Well-defined tasks:** The task has a clear right/wrong answer
- **Reproducible evaluation:** Running the same task with the same skill produces similar results
- **Distinct train/val sets:** You can define tasks for training that differ from tasks for validation
- **Bounded edit scope:** The skill is large enough that small edits make sense (not a 2-line instruction)
