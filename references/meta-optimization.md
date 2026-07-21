# Meta-Optimization: SkillOpt Applied to Evaluation Tooling

SkillOpt is designed for optimizing skill documents. But the methodology applies equally to **evaluation and benchmarking tooling** — scoring scripts, probe definitions, pass/fail rubrics, and any code that measures model quality.

This document covers the key differences when the target is evaluation tooling rather than a traditional skill.

## When to Use This Pattern

- You want to tighten the scoring heuristics in a benchmark
- You need to make an evaluation harder to discriminate between model qualities
- You have existing evaluation data from a baseline run and want to use it as rollout
- The "skill" you're optimizing is actually a scoring rubric or probe definition

## Key Differences from Standard SkillOpt

| Aspect | Standard SkillOpt | Meta-Optimization |
|--------|------------------|-------------------|
| **Target** | A SKILL.md document | Scoring scripts, probe definitions, pass/fail logic |
| **Rollout data** | Run training tasks against the skill | Use existing evaluation results from a baseline run |
| **Training tasks** | "Execute task X using the skill" | "Make the evaluation harder along axis Y" |
| **Validation metric** | Task pass rate improvement | Scoring discrimination (can it tell models apart?) |
| **Acceptance criteria** | Edit improves or maintains pass rate | Edit makes the evaluation more discriminating without creating false negatives |
| **User sensitivity** | Low — user wants skill improvements | High — user owns the evaluation methodology |

## Rollout: Using Existing Data

When you already have evaluation data from a baseline run, the Rollout phase is **documentation, not execution**:

1. Collect the baseline scores: per-phase, per-probe, and composite
2. Document failure modes the current scoring allows
3. Identify which probes are too easy (100% passes), too noisy, or well-calibrated

## Training Tasks: What to Measure

Instead of "execute the skill against [task]," training tasks for meta-optimization are about **tightening specific axes**:

- "Phase 1 skill name matching should not accept partial substring matches"
- "Phase 2 should penalize using web_search alongside a dedicated MCP tool"
- "Phase 3 should require skills to be loaded in order, not just present"

Each training task is a **constraint on the scoring behavior**, not a task for the model under evaluation.

## Validation: Measuring Discrimination

The validation gate in meta-optimization checks whether a scoring change **improves discrimination**:

- **Before**: Phase 1 shows 100% for both a strong model and a mid-tier model. No discrimination.
- **After**: Phase 1 shows 60% for the mid-tier model. Discrimination improves.

Validation passes when:
1. The edit does not introduce false negatives (correct answers scored as wrong)
2. The edit widens the score gap between known-different models
3. Changes are consistent with the evaluation's stated goals

## Worked Example: Groktobench HARP Epoch 1 (First Attempt — Cautionary Tale)

**Context**: The Groktobench benchmark (HARP = Hermes Agent Readiness Profile) evaluates models on skill-loading discipline across three phases: recognition, fidelity, and chaining. v0.0.1 was tagged with scoring scripts using heuristic string matching.

**What went wrong**: The agent (Jasper) skipped the SkillOpt process entirely. Instead of Rollout → Reflect → Propose → Validate → Merge, the agent:
1. Edited scoring scripts directly
2. Ran validation once (79→43.2 HARP drop)
3. Drafted an Epoch 2 PR (decoy skills, llm-wiki swaps, deeper chains)
4. Declared Epoch 1 complete

The user's response: *"You didn't even do epoch 1 yet. We are starting from ground zero here."* The branch was deleted, main was hard-reset to v0.0.1, PRs closed, and the real Epoch 1 began with a clean baseline rollout.

**Lesson for meta-optimization**: The phases are not optional. Rollout must produce trajectory records that the user can see. Reflect must involve the user. Propose must wait for user review. Skipping to Validate+Merge produces a result that isn't trusted because the user wasn't part of the discovery.

**Corrected Epoch 1 structure** (what the first attempt should have been):

1. **Rollout**: Run v0.0.1 scoring against deepseek-v4-flash. Collect per-probe results. Present raw data to user.
2. **Reflect**: With the user, identify which probes are too easy (100%), which scoring rules are too generous (substring matching), and which axes the benchmark should discriminate on.
3. **Propose**: Draft 1-4 bounded edits to scoring scripts. Each edit is a specific constraint: "change skill matching from substring to exact", "penalize wrong-skill loads", etc. Present for user review.
4. **Validate**: Apply edits, re-run on held-out probes. Compare before/after.
5. **Merge**: If edits improve discrimination without false negatives, commit.

## Pitfalls Specific to Meta-Optimization

- **Don't optimize for discrimination at the expense of correctness.** Making a test harder is not useful if it penalizes correct behavior.
- **Baseline scores may be noisy from a single run.** Consider running the baseline twice to understand variance before declaring an improvement.
- **The user may want different difficulty levels for different phases.** Don't apply uniform difficulty increases without checking.
- **Scoring changes can cascade.** Tightening Phase 1's matching function changes the "correct skill loaded" signal that Phase 2 depends on.
- **When the target is a separate repository, save proposal artifacts in that repo's `.skillopt/` directory.**
- **Validate each epoch before proposing the next.**
- **Test definitions must use only upstream skills.** Custom skills make the evaluation non-reproducible for other users.
- **"Completed" the implementation is not the same thing as "completed the epoch."** An epoch is a conversational process with the user, not a file edit. If the user hasn't seen rollout data, participated in reflection, and reviewed your proposals, you haven't done the epoch.
