# Validation Trajectory Integrity

Validation measures task execution, so the raw task response is the evidence. A worker's PASS label, score table, or prose review of the candidate is not a trajectory.

## Dispatch contract

Use the same neutral context for baseline and candidate runs. Candidate behavior must enter only through the candidate skill copy; do not teach the proposed edit in the prompt.

Generate paired prompts from one stored template with a single `{skill_root}` placeholder. Render baseline and candidate by substituting only that root, normalize both roots back to the placeholder, and assert the resulting prompt strings are identical before dispatch. Paths may differ; allowed tools, source boundaries, output budgets, cautions, and scenario wording may not. If a candidate prompt gains a criterion or mechanism that the baseline prompt lacked, preserve the attempts as infrastructure-invalid and rerun both sides from the corrected shared template.

Require every task record to contain:

```json
{
  "task_id": "...",
  "response": "full direct user-facing answer",
  "execution_trace": [],
  "failure_modes": [],
  "rubric_self_check": {}
}
```

Tell the worker explicitly:

- answer the user's scenario directly;
- do not review whether the skill text covers the rubric;
- do not omit `response` in favor of pass counts or summaries;
- return the artifact directly and do not write files;
- keep each response under a stated budget so raw evidence remains inspectable.

### Parent-owned envelope (preferred)

Do not make output-schema compliance the task being evaluated. When `delegate_task` already preserves the complete worker result and delegation metadata, prefer asking for the **direct user-facing answer only**. The orchestrator owns the dossier envelope: it stores the untouched worker output as `response`, records task ID and execution metadata from the delegation result, and adds parent-scored failure modes separately.

Use the five-key worker JSON contract only when an automated consumer genuinely requires it and the selected model has already demonstrated reliable schema adherence. If a complete direct answer is mechanically separable, normalize it once into a parent-owned envelope and record that normalization; do not spend repeated rollouts teaching the worker JSON bookkeeping. Never invent a missing trace or rewrite the answer.

This keeps the intervention focused on skill behavior instead of format obedience, reduces infrastructure-invalid retries, and still preserves raw evidence.

### Literal-schema contract

Name the required keys exactly and show the minimum shape. Saying “return a response string” is ambiguous: workers may emit `response_string`, put a nested object in `response`, or wrap the answer in commentary. Use this contract:

```text
Return only one JSON object with exactly these keys:
`task_id`, `response`, `execution_trace`, `failure_modes`, `rubric_self_check`.
`task_id` and `response` must be strings; `execution_trace` and `failure_modes` must be JSON arrays; `rubric_self_check` must be a JSON object.
`response` must be one complete direct user-facing string, not a nested object.
```

Before scoring, parse the raw JSON and reject a record whose key is not literally `response`, whose `response` is not a string, or whose trace/failure fields have the wrong JSON type. Preserve the malformed record as infrastructure-invalid, then rerun only that task with the literal-schema contract. This repairs evaluation infrastructure without rerolling a valid task outcome.

### Source and side-effect boundary

A source-restricted trajectory is infrastructure-invalid when the worker consults web search, live CLI help, source code, or another external authority that the baseline skill does not provide, even if the resulting answer is correct. Inspect the execution trace, tool/API-call record, and response claims; do not trust a self-check that says “skill only.” Baseline and candidate must receive the same source boundary.

Keep exact intervention mechanisms evaluator-only. A task may describe the user-visible outcome, but naming the missing command group, function, flag, SQLSTATE, or replacement text can teach the baseline the proposed edit. If the task wording leaks the mechanism, discard both sides and rerun them with the same non-leading scenario.

Read-only is also a filesystem boundary, not merely a candidate-worktree promise. Before dispatch, name allowed output roots. Afterward, inspect every absolute path claimed in the response or trace plus the candidate worktree. If a worker created an unauthorized artifact, preserve the raw attempt, verify creation time and content, remove only that exact file, classify the trajectory as infrastructure-invalid, and rerun only that task.

## Test-definition corrections

When later review reveals that a held-out task was incomplete, solution-bearing, or causally confounded, the comparison built from it is invalid — not merely the latest trajectory. Version the corrected task definition, preserve the superseded attempts, and rerun the baseline plus every candidate being compared with the same neutral prompt and source boundary. Recompute baseline scores before making acceptance decisions.

Do not add a newly discovered criterion only to candidate scoring, and do not compare a corrected candidate run against an older baseline run. A paired rerun is the minimum valid repair. If the correction names the intervention mechanism, move that detail into the parent-side rubric and keep the worker scenario outcome-focused.

## Infrastructure-invalid trajectories

Discard and rerun a trajectory when:

- it reviews the candidate instead of executing the task;
- it returns only scores, summaries, or self-checks without the full response;
- baseline and candidate received different solution-bearing instructions;
- the worker evaluated the wrong candidate, task ID, or path;
- the response cannot be reconstructed from the preserved artifact.

Record the raw attempt and rejection reason, but exclude it from metrics.

A worker-created output file is an infrastructure defect, not automatically a target-skill failure. Preserve the exact file as raw evidence when it contains the full response, remove only the exact verified worker-created artifact, and verify the candidate/worktree diff before scoring.

Treat unrelated prompt-injection or evaluator-instruction text appended to a worker result as infrastructure contamination. Preserve the complete raw output. Score only when the direct response is complete and mechanically separable inside the required schema field or a closed code fence; record the discarded suffix and extraction boundary. If the response boundary is ambiguous, classify the attempt as infrastructure-invalid and rerun it. Never silently edit a contaminated trajectory into a cleaner answer.

## Parent scoring

Score the literal response against every rubric conjunct. Ignore worker self-scores. A response that says it retrieved official evidence but provides no retrieved URL has not passed an authority gate. A plan that names an unsupported command or guessed offset is not rescued by a correct checklist.

Recompute mechanical criteria yourself. Count words or tokens from the extracted response field rather than trusting a worker-reported `word_count`; verify required headings/statuses from the actual text; and treat prose that contradicts its ledger as the governing failure.

Use the same metric formula and output budget for baseline and candidates. Independent edits retain independent verdicts. A later cumulative pass can identify interaction worth testing in another epoch, but it cannot retroactively accept components that failed their own mapped held-out task.

## Variance control

When model variance changes unrelated tasks:

1. First rule out infrastructure mismatch using the checks above.
2. Rerun only infrastructure-invalid attempts with the same neutral contract.
3. Do not rerun a valid failure merely to seek a pass.
4. Preserve mapped-task and full-suite results separately in the dossier.
5. If a coordinated bundle appears promising, propose it as one new intervention in the next epoch and validate it independently.
