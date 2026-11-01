# Rollout fidelity: evaluate the installed skill, not a transcription

A rollout that receives a pasted summary of the skill is measuring the summary.
The number it produces cannot be attributed to the artifact under test, because
the worker never loaded that artifact the way a real user's agent would.

Two mechanisms make this worse than it used to be:

1. **Skills are trees.** The dominant architecture is a thin `SKILL.md` index
   with procedure and detail deferred to `references/`. A transcript of
   `SKILL.md` alone silently deletes the content that decides hard tasks.
2. **Load conditions decide reachability.** Frontmatter gates (`platforms`,
   `requires_toolsets`, `requires_tools`, `session_platforms`) control whether
   the skill is even indexed. An inlined transcript evaluates a skill that
   Hermes might refuse to load.

## Use the real loader

For a one-shot rollout, preload the skill instead of describing it:

```bash
hermes -z "Capture the article at <url> into the vault. Report only the artifact path." \
  --skills vault-note
```

`--skills` preloads the named skill for the session (repeatable or
comma-separated). Combined with `--usage-file <path>`, this gives a
per-trajectory cost record alongside the outcome. `-z` bypasses approval
prompts, so it belongs only in a sandboxed or explicitly authorized task.

For a board worker, bind the skill to the card instead:

```bash
hermes kanban create "Rollout: capture a source" --skill vault-note --body "..." \
  --workspace dir:/path/to/candidate
```

## Delegated workers need explicit paths

`delegate_task` subagents do not preload profile-scoped skills. The orchestrator
must either pass the candidate root and require the worker to read it, or accept
that it is testing a transcription:

> Read `<candidate_root>/SKILL.md` first. Follow its links into
> `<candidate_root>/references/` when the task needs them. Do not answer from
> memory of a similar skill.

This is the correct fix for the documented "subagents don't load the target
skill" pitfall: give the path, not a paraphrase, and make the references
reachable.

## Validate a candidate as a tree

- Copy the whole skill directory for the candidate, not a single file. A
  validation copy that only mirrors `SKILL.md` cannot resolve `references/`
  links.
- Point baseline and candidate at sibling roots with identical structure, so
  the only difference is content.
- Keep the substitution identical in both prompts (`{skill_root}`) and assert
  the prompts are otherwise byte-identical. Behavior being tested must arrive
  through the skill copy, never through the orchestrator's wording.

## Prove the tree was actually read

A pass is not evidence that the worker used the reference layer. Require one
observable that can only come from it:

- a rule, format, or field that exists only in `references/`, exercised by the
  task and absent from `SKILL.md`;
- a negative control: a policy deliberately removed from the candidate's
  reference file must now be missed. If the worker still follows it, it was
  reading something other than the candidate.

Score that observable mechanically from the raw response. A worker's claim that
it followed the reference file is not evidence that it read one.

## When transcription is acceptable

Only when the harness cannot load a skill at all (a non-Hermes consumer, or a
worker restricted to prose). Record it as a declared limitation in the run
summary: `evaluated: transcribed SKILL.md, references/ not reachable`. Do not
report that trajectory as validation of the installed artifact.
