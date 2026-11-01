# Native orchestration substrate

Hermes already ships the primitives SkillOpt used to hand-build. Using them is
not cosmetic: hand-built phase graphs duplicate state, lose per-card runtime
bounds, and encode completion gates as prose that nothing enforces.

Prefer a native primitive when it maps cleanly. Keep the conversational path
(session-orchestrated phases with `delegate_task`) as the default; reach for the
board when a run must outlive the session, span profiles, or survive restarts.

## Phase-to-primitive map

| Phase | Native primitive | What it replaces |
|---|---|---|
| Rollout (parallel) | `hermes kanban swarm` with `--worker PROFILE:TITLE[:SKILL]` | N phase cards plus a manual link graph |
| Rollout (in-session) | `delegate_task(tasks=[...], background=True, output_schema={...})` | Blocking batches plus post-hoc JSON parsing |
| Reflect | synthesizer card (swarm) or in-session synthesis from dossiers | A worker told to "read the rollout records" |
| Propose | in-session, or a worker card bound with `--skill` | Pasting the skill body into the card text |
| Validate | verifier profile card with `--completion-contract` | A prose instruction to "only count passes" |
| Merge | human gate plus `request-review` / `promote` | A comment saying "ready to merge" |
| Slow/Meta | backlog card, no dependencies | A note in the run summary |

## Binding the skill, not transcribing it

```bash
hermes kanban --board skillopt-vault-note create "Rollout: capture a source" \
  --skill vault-note --body "Run task T3 from the training suite; return the artifact only." \
  --completion-contract local-only --max-runtime 1800 --max-retries 1 \
  --workspace worktree:/path/to/candidate
```

`--skill` force-loads the named skill into the worker; the kanban lifecycle is
injected automatically, so repeating it is unnecessary. The card body should
carry the task, never the skill's instructions. A body that restates the skill
creates a second copy that can drift from the artifact under test.

Keep `--body-file` for task text with quotes, newlines, or flag-shaped lines.
`--body` inline is fine only for single-line bodies without shell-active
characters.

## Completion contracts and runtime bounds

- `--completion-contract` states what "done" means for the card. When the run
  targets a repository, point it at `OWNER/REPO` or an exact PR URL so required
  CI gates count; `local-only` (the default) means no external gate.
- `--max-runtime` bounds a wedged worker instead of waiting on it.
- `--max-retries` should usually be 1. A second automatic retry hides a
  reproducible failure.
- `--idempotency-key` makes re-running a seeding command safe: the same key
  reuses the root card instead of creating a duplicate phase.
- `--model` / `--provider` set a per-card override for the next dispatch, which
  is how you run one phase on a cheaper model without changing the profile.

## Isolation

Rollouts that touch a repository must not share a working tree with the user's
checkout:

```bash
hermes kanban create "Rollout: apply config fix" --workspace worktree --branch wt/rollout-t4
```

`--workspace worktree` gives the worker its own checkout; `--workspace
dir:<path>` pins an existing directory; the default `scratch` is wrong for
anything that must persist. Never point two concurrent rollout cards at one
worktree.

## Reconciliation instead of guessing

Late worker results invalidate a provisional baseline. Do not infer worker
state from chat, and do not close an epoch while a batch is live:

```bash
hermes kanban runs <task_id> --json
hermes kanban heartbeat <task_id>
hermes kanban reclaim <task_id>          # only after confirming the worker is dead
```

For `delegate_task`, dispatch with `background=True` and use
`action="list"` / `action="steer"` / `action="stop"` on the returned handle. A
background batch joins on every child and re-enters as one consolidated result,
which is the signal that the gate can be scored.

## Steering and review

`request-review` records what was implemented and how it was verified for the
reviewer; `request-changes` and `reopen-review` close the loop; `promote`
advances the card with an audit-trail reason and supports `--dry-run`.

```bash
hermes kanban request-review <task_id> --summary "implemented X; verified by Y"
hermes kanban request-changes <task_id> --summary "rejected: reason"
hermes kanban promote <task_id> "epoch gate passed" --dry-run
hermes kanban reopen-review <task_id>
```
 A review
verdict is still a hypothesis until reconciled against evidence, and a merge
stays a human decision unless the user delegated it explicitly.

## What stays hand-rolled

- The training/validation split. No primitive enforces it.
- Per-edit mapping to a held-out criterion.
- The merge diff classification (accepted edit, later correction, rejected
  edit, path-normalization artifact).
- Artifact pyramids. The board records task state, not research structure.

If a proposed refactor replaces one of these with a card, it has removed the
methodology, not the glue.
