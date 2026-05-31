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

### Code / Tool Skills (e.g., `forgejo-cli`, `arr-cli`)

Training tasks: "Run command X against a test environment"
Validation tasks: "Run command Y against a test environment"

Measurement: Correct exit code, correct output format, no unintended side effects.

## What to Avoid

- **Don't use the same domain for train and val if the domain is narrow.** If all your tasks are "summarize spreadsheet cell A1," you're testing one thing. Better: a mix of different cell types, formulas, and error states.
- **Don't make validation tasks harder than training tasks.** If the validation set is consistently harder, the gate will reject good edits. Train and val should be comparable difficulty.
- **Don't use subjective evaluation.** "Did the output look good" is not measurable. Use binary pass/fail criteria where possible: "Did the output have the correct JSON structure?" "Did the command exit 0?"

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
