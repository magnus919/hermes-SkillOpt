# Trajectory schema enforcement

Use this during SkillOpt Rollout and Validate before any parent scoring.

## Required record

Every worker result must parse to exactly this shape:

```json
{
  "task_id": "string",
  "response": "string containing the complete direct user-facing answer",
  "execution_trace": ["string"],
  "failure_modes": ["string"],
  "rubric_self_check": {}
}
```

## Common near-misses

Treat each as infrastructure-invalid, even if the prose is otherwise useful:

- `response_string` or another alias instead of `response`
- an object/array in `response` rather than the literal direct-answer string
- a prose string in `execution_trace` rather than an array
- a summary, score table, or skill review instead of the direct response

## Recovery

1. Preserve the raw result and record why it was excluded.
2. Re-dispatch only the same scenario.
3. State the exact key names and value types in the retry prompt.
4. Keep the task, rubric, baseline/candidate context, and output budget unchanged.
5. Score the repaired record, not the invalid attempt.

This is a contract-repair retry, not permission to reroll a valid failure.
