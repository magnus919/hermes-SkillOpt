# Test Suite Design Guide

Good test suite design is the most important prerequisite for a successful SkillOpt run. Without well-chosen tasks, the validation gate measures noise, not improvement.

## The Core Rule

**Training tasks and validation tasks must be distinct.** Every task in the validation set must be different from every task in the training set. If they overlap, the validation gate tells you whether the skill memorized the task, not whether it generalized.

This is the non-negotiable methodological requirement. If you can't define 3 distinct training and 3 distinct validation tasks, don't run SkillOpt — your skill may not be well-suited to this methodology.

## Minimum Suite Sizes

| Level | Training | Validation | When to Use |
|-------|----------|------------|-------------|
| Small | 3 | 3 | Quick iteration, simple skills with binary outcomes |
| Serious | 10 | 10 | Most production skills with measurable quality |
| Rigorous | 50 | 50 | High-stakes skills (extraction prompts, safety rules) |

For the first run, start with the Small configuration. A full 4-epoch cycle completes quickly and tells you whether the methodology is providing signal for this skill.

## Negative Test Cases (Required)

Per Schmid (Google DeepMind, AI Engineer 2026), over-triggering from broad descriptions is a primary failure mode. **Every test suite must include negative cases** — tasks where the skill should NOT trigger or should NOT produce its specialized output.

**Minimum:** 2 negative cases per suite (training and validation each). For skills with meaningful overlap with siblings, use 3-5.

**Good negative cases are near-misses**, not obviously irrelevant tasks:
- Weak: "Write a fibonacci function" (no keyword overlap, tests nothing)
- Strong: "I need to update the formulas in my Excel budget spreadsheet" (shares "spreadsheet" and "data" concepts with a CSV analysis skill, but needs Excel editing, not CSV analysis)

**What negative cases test:**
1. **Description precision** — Does the skill correctly NOT trigger on near-miss prompts?
2. **Boundary behavior** — If the skill does trigger, does it correctly recognize the task is outside its scope and defer?
3. **Cross-harness consistency** — A skill that over-triggers on one harness may not on another. Negative cases catch this.

Record negative case results separately from positive cases in the rollout artifacts. A skill that passes all positive cases but fails negative cases (over-triggers) has a description problem, not a body problem — fix it in Phase 0, not in Propose.

## Metric Design

Each validation task should define both a hard pass/fail condition and a quality rubric. The runner records four weighted criteria, in priority order:

1. `pass_rate` — hard task success/failure; any regression rejects the edit.
2. `quality_score` — 0.0-1.0 score for minute output quality among outputs with the same pass/fail status.
3. `speed_score` — derived from measured wall-clock completion time; faster is better.
4. `token_efficiency` — derived from token usage when reported, otherwise a chars/4 heuristic including the skill text; fewer tokens is better.

Default weights are `0.55 / 0.30 / 0.10 / 0.05`. Override them in `board-metadata.json` or `test-suite.json` under `metric_weights` only when the skill genuinely needs a different tradeoff.

A good validation task describes what earns a high quality score, not just what passes. Example: "Pass if the answer identifies the correct CLI command. Quality: 1.0 if it also explains flags, failure modes, and a verification command; 0.5 if it only gives the command."

## Choosing Tasks by Skill Type

### Research / Retrieval Skills (e.g., `groktocrawl agent`, `arxiv-search`)

Training tasks: "Find papers about [known topic] and summarize key findings"
Validation tasks: "Find papers about [different but related topic] and summarize key findings"

Measurement: Does the returned content match the known key points? Is the summary accurate?

### Content / Writing Skills (e.g., `hugo-blog`, `write-draft`)

Training tasks: "Write a blog post from this outline"
Validation tasks: "Write a blog post from a different outline"

Measurement: Frontmatter correctness, link validity, word count within range, no hallucinated facts.

### Data Extraction Skills (e.g., cashew extraction prompts)

Training tasks: "Extract entities from this conversation" (with known ground truth)
Validation tasks: "Extract entities from a different conversation" (with known ground truth)

Measurement: Precision and recall of extracted entities against ground truth.

### Creative / Video Composition Skills (e.g., `hyperframes`, `manim-video`)

Training tasks: "Create a [type] video composition using [tool/pattern] with [specific constraints]"
Validation tasks: "Create a different [type] video composition using [same tool] with [different constraints]"

Measurement: Binary compliance checks — Did the agent use `npx hyperframes init`? Did they use GSAP timelines (not WAAPI)? Did they run lint/validate/inspect? Did the render produce a non-zero output at the correct duration? For skills where all rollouts structurally pass, measure compliance improvement rather than correctness (e.g., "3/3 agents used the scaffold command after edits, vs 1/3 at baseline").

**Distinction from Code/Tool skills:** Creative skills often produce valid output even when the agent skips the toolchain entirely (e.g., writing standalone HTML that plays in a browser but can't render to video). Validation must check toolchain compliance, not just output validity.

### Knowledge / Instruction Skills (e.g., `github-runner`, `hugo-theme`)

These skills teach the agent *how to do something* — they're reference manuals for procedures, not tools the agent invokes. Rollouts test whether an agent using the skill produces correct guidance, not whether it successfully runs a command.

**Training tasks:** Give the agent a scenario that requires the skill's knowledge to answer correctly. Evaluate against ground truth from authoritative documentation.

**Validation tasks:** Same pattern, held-out scenarios, different concrete details.

**Measurement:** Structured checklist against ground truth. Did the agent use the right flags? Did it recommend the right approach? Did it correctly explain the trade-offs?

**Worked example from github-runner Epoch 1:**

```
Task: Produce a docker-compose.yml for a self-hosted runner targeting
      repo magnus919/SlopSearX. Explain the registration flow.

Ground truth checklist:
- [ ] Uses ACCESS_TOKEN, not RUNNER_TOKEN
- [ ] REPO_URL set to https://github.com/magnus919/SlopSearX
- [ ] RUNNER_SCOPE=repo
- [ ] LABELS includes self-hosted,linux,x64,slopsearx
- [ ] EPHEMERAL=false (string, not 0)
- [ ] Docker socket mounted
- [ ] Registration flow explains ACCESS_TOKEN generates tokens dynamically
- [ ] PAT scopes correct (repo for repo-level)
```

**Key difference from Tool skills:** You cannot run the output — you check it against documented conventions. The evaluation is a structured diff between what the agent produced and what the authoritative source says is correct.

**Subagent-based delivery pattern:** Use `delegate_task` with the skill content included in the delegation context string. The subagent loads the skill instructions as part of its task, produces output, and you evaluate against the rubric. This session's Epoch 1 ran 4 training tasks in parallel via `delegate_task` with full success — each subagent produced correct output that scored 92-100% against the rubric.

**Subagent context design for knowledge skills:** Include the skill's critical procedural rules directly in the delegation context. A bare "load the skill" instruction is insufficient — the subagent won't auto-load it. The context must contain the actual structural requirements, flag values, and pitfalls.

### Code / Tool Skills (e.g., `forgejo-cli`, `arr-cli`)

Training tasks: "Run command X against a test environment"
Validation tasks: "Run command Y against a test environment"

Measurement: Correct exit code, correct output format, no unintended side effects.

## What to Avoid

- **Don't use the same domain for train and val if the domain is narrow.** If all your tasks are "summarize spreadsheet cell A1," you're testing one thing. Better: a mix of different cell types, formulas, and error states.
- **Don't make validation tasks harder than training tasks.** If the validation set is consistently harder, the gate will reject good edits. Train and val should be comparable difficulty.
- **Don't use subjective evaluation.** "Did the output look good" is not measurable. Use binary pass/fail criteria where possible: "Did the output have the correct JSON structure?" "Did the command exit 0?"

## Creative Skills: Special Considerations

For skills with subjective outputs (image generation, writing, design), SkillOpt still works but with an additional constraint: **the acceptance criteria themselves may need validation before the validation gate runs.**

### The criteria-iteration trap

When you write success criteria for a creative task, the criteria you think define "good output" may not match what the user considers good. This session's image-magnus919 Epoch 2 is the worked example: the initial SUBJECT validation criteria included a "30-word max" constraint that the user correctly rejected. The subject that produced the best cover was 60+ words and richly detailed — the limit would have penalized the best output.

### How to avoid this

1. **Propose acceptance criteria during the Propose phase, not the Validate phase.** Before running validation, present your criteria to the user: "Here's how I plan to evaluate success — [criteria]. Does this match what you'd consider good?"
2. **Be explicit about what you're measuring.** "SUBJECT must be one line" is measurable. "Image must look good" is not. Frame each criterion as a binary check.
3. **Expect iteration on criteria.** The first set may be too tight (over-constraining the creative output), too loose (not distinguishing good from bad), or measuring the wrong thing. Iterate the criteria until the user agrees, then run validation.
4. **Document the corrected criteria.** After user sign-off, update the task definitions with the final criteria. This prevents re-proposing the same wrong criteria in future epochs.
5. **Tight criteria can still catch real quality issues.** Even with subjective output, you can measure: Did the template get modified? Was the output format wrong? Was the reference path incorrect? Focus criteria on the procedural aspects that are universally valid.

## Task Format

Each task in your test suite should be a self-contained instruction that the target LLM can execute. A good task description includes:

1. **The instruction:** What to do
2. **Input data (if any):** The specific inputs to operate on
3. **Expected outcome:** What constitutes success
4. **Scoring criteria:** How to evaluate the output

Example:
```
Task: Search for papers about swarm robotics published since 2024
Input: arXiv search with query '"swarm robotics" AND NOT survey'
Expected: Return at least 3 papers with correct metadata (title, authors, abstract)
Pass if: All returned papers are about swarm robotics, not general robotics
```
