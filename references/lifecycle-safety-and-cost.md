# Lifecycle safety, coexistence, and cost evidence

A SkillOpt epoch mutates a live skill for hours. Three things can go wrong that
the methodology itself does not prevent: another background process edits the
skill underneath the run, an unsupervised rollout writes something it should
not, and nobody can say what the epoch cost.

## 1. Pin the target against the curator

Hermes runs a background curator that reviews agent-created skills, prunes
stale ones, consolidates overlaps, and archives obsolete skills. A multi-epoch
optimization is exactly the kind of window it operates in: the skill is being
edited repeatedly, and a curator pass mid-run silently changes the artifact the
trajectories were scored against.

```bash
hermes curator pin <skill-name>
hermes curator status
```

Pin before the baseline snapshot and unpin after merge is committed. Do not
pin permanently: the curator is the mechanism that keeps the skill set
healthy, and a pinned skill is exempt from that maintenance.

Record the pin state in the run summary. If the curator ran anyway, or the
skill changed without a SkillOpt edit, classify the affected trajectories as
infrastructure-invalid and rerun them against a re-pinned baseline.

## 2. Supervise what rollouts are allowed to do

`hermes -z` bypasses approval prompts by design, because it exists for scripts
and pipes. A rollout that inherits it can write to unapproved paths without a
gate. Choose the strongest control that still measures the skill:

| Situation | Control |
|---|---|
| Rollout only reads and reasons | default `-z` in a disposable directory |
| Rollout writes, but the skill under test is the only intended target | worktree or `dir:<path>` workspace, plus a task that names the permitted write path |
| A write outside the sandbox would be damaging | do not use `-z`; run the task in an interactive/board worker with approvals enabled, or accept a declared limitation |
| The user needs everything to stop | `hermes pause` |

`hermes pause` halts new cron dispatch, kanban dispatch, and gateway turns. It
does not kill in-flight work, so do not report a pause as a rollback; it is a
barrier. `--safe-mode` is a troubleshooting flag (it strips user config,
memory, plugins, and MCP servers), not a sandbox, and it changes the harness a
skill is evaluated against. Do not use it for rollouts without recording that
the comparison is no longer a normal installation.

## 3. Record cost per epoch

An optimization that raises pass rate while multiplying token spend is not
automatically an improvement. `-z` writes a per-run usage report:

```bash
hermes -z "run training task T3 using the loaded skill" \
  --skills <skill-name> --usage-file epoch-3/t3-usage.json
```

The report is written even when the run fails, so failed trajectories are
accounted too. It contains estimated cost, token counts, model, and api_calls.

Rules:

- Derive `token_efficiency` from the recorded usage when it exists. A
  characters-divided-by-four estimate is a fallback, and the fallback must be
  labeled as an estimate in the dossier, not presented as measurement.
- Report epoch cost as the sum of its trajectories plus the reflection,
  proposal, and validation calls.
- State the acceptance rule before the epoch: for example, "accept if pass rate
  is non-regressing and cost does not exceed 1.2x baseline." Do not discover
  the cost threshold after seeing an expensive pass.
- `hermes usage` reports provider account limits, not per-run spend. Do not use
  it as epoch cost evidence.

## 4. Recovery, not re-implementation

Hermes checkpoints working directories before `write_file`, `patch`, and
`terminal` calls, so an accidental edit can be rolled back without a bespoke
backup scheme:

```bash
hermes checkpoints status
```

Keep the run's own baseline snapshot anyway: it is evidence for diffing the
candidate, not just a rollback aid. Use checkpoints for recovery and snapshots
for comparison. Do not claim a merge is reversible because a checkpoint exists
without checking that the checkpoint covers the edited path.

For a reproducible export of the installed skill set,
`hermes skills snapshot export <file>` records what Hermes had installed. It is
a bulk inventory, not a diff tool, so it supplements rather than replaces the
per-epoch snapshot.

## 5. Report the boundary

Every run summary should state what was and was not verified:

- target pinned for the whole run or not;
- rollout approval posture (bypassed, gated, or limited to a sandbox);
- cost evidence measured or estimated;
- recovery path exercised or merely available.
