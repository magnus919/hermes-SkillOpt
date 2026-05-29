# Artifact Formats

Every SkillOpt phase writes structured JSON to disk. These schemas define the contract between phases. Downstream phases read from the state directory — nothing depends on LLM context retention.

## Rollout Record (`rollouts/epoch-N-task-X.json`)

```json
{
    "epoch": 1,
    "task_id": "training-task-1",
    "task_description": "Write a blog post about Python typing from the provided outline",
    "skill_target": "/home/user/.hermes/skills/content/hugo-blog/SKILL.md",
    "execution_trace": "LLM received: the skill document + the task instruction. Generated: title, frontmatter, body sections A, B, C.",
    "outcome": "success",
    "failure_modes": [],
    "output_summary": "Generated valid Hugo post with correct frontmatter and all three required sections"
}
```

## Reflection Document (`reflections/epoch-N.json`)

```json
{
    "epoch": 1,
    "rollout_count": 3,
    "success_count": 2,
    "failure_count": 1,
    "failure_patterns": [
        {
            "pattern": "Missing table of contents structure in procedural blog posts",
            "frequency": "2 of 3 tasks",
            "severity": "medium",
            "tasks_affected": ["training-task-1", "training-task-2"],
            "suggested_fix_type": "add",
            "suggested_location": "Output Format section"
        }
    ],
    "summary": "The skill handles persuasive and tutorial writing well but lacks structure guidance for procedural walkthroughs"
}
```

## Proposal Document (`proposals/epoch-N.json`)

```json
{
    "epoch": 1,
    "reflection_source": "reflections/epoch-1.json",
    "edit_budget": 4,
    "proposals": [
        {
            "id": "edit-1",
            "type": "add",
            "location": "Output Format section, after line 12",
            "old_text": null,
            "new_text": "- For procedural content, include a bulleted overview of steps before the body",
            "rationale": "Two of three training tasks produced disorganized procedural content without step-level structure"
        }
    ]
}
```

## Validation Result (`validation-results/epoch-N-edit-X.json`)

```json
{
    "epoch": 1,
    "proposal_id": "edit-1",
    "edit_type": "add",
    "validation_tasks_run": 3,
    "baseline_metrics": {
        "pass_rate": 0.67,
        "tasks_passed": 2,
        "tasks_failed": 1
    },
    "post_edit_metrics": {
        "pass_rate": 1.0,
        "tasks_passed": 3,
        "tasks_failed": 0
    },
    "verdict": "accepted",
    "delta": "+0.33 pass rate",
    "validation_detail": [
        {"task_id": "validation-1", "baseline": "pass", "post_edit": "pass"},
        {"task_id": "validation-2", "baseline": "fail", "post_edit": "pass"},
        {"task_id": "validation-3", "baseline": "pass", "post_edit": "pass"}
    ]
}
```

## Rejected-Edit Buffer (`rejected-buffer.json`)

```json
[
    {
        "epoch": 1,
        "proposal_id": "edit-3",
        "edit_type": "replace",
        "rationale": "Proposed replacing the error-handling section",
        "failure_reason": "Edit caused regressions in validation tasks 2 and 3",
        "baseline_metrics": {"pass_rate": 0.67},
        "post_edit_metrics": {"pass_rate": 0.33},
        "delta": "-0.34 pass rate"
    }
]
```

## Meta-Reflection (`reflections/slow-meta-epoch-N.json`)

```json
{
    "epoch": 4,
    "rejected_edits_reviewed": 5,
    "patterns_identified": [
        {
            "pattern": "Replace-type edits in the error-handling section consistently fail validation",
            "affected_proposals": ["epoch-1/edit-3", "epoch-2/edit-2", "epoch-3/edit-1"],
            "recommendation": "Stop proposing structural changes to error-handling. Focus on additive edits only."
        }
    ],
    "optimizer_strategy_adjustment": "Restrict edit types for this skill section to 'add' only",
    "recommendation": "Continue to epoch 5 with restricted edit scope, or archive if plateau confirmed"
}
```

## Run Summary (`run-summary.json`)

```json
{
    "skill_name": "hugo-blog",
    "target": "/home/user/.hermes/skills/content/hugo-blog/SKILL.md",
    "final_epoch": 4,
    "archived_at": "2026-05-29T19:00:00Z",
    "state_dir": "/home/user/.hermes/SkillOpt/hugo-blog"
}
```
