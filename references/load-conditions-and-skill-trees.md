# What Hermes actually loads: trees and load conditions

A skill is not a markdown file. It is a directory that Hermes may or may not
index, whose content is deliberately split between an always-loaded index and
reference files loaded on demand. SkillOpt must optimize that object, not a
single document with the same name.

This file covers the two consequences: the load conditions that decide whether
the skill is reachable at all, and the tree structure that decides whether its
procedure survives progressive disclosure.

## Load conditions are part of the artifact

`metadata.hermes` gates decide whether a skill enters the index. A skill that is
excellent and unindexed scores zero, and the failure is invisible: no error, no
warning, just an agent that never loads it.

| Field | Meaning | Common mistake |
|---|---|---|
| `platforms` | Host OS the skill runs on | Listing a platform the evaluation host is not |
| `requires_toolsets` | Toolsets that must be active for the skill to be offered | Requiring a toolset Hermes ships **disabled by default** (for example `kanban`), which hides the skill on every stock install |
| `requires_tools` | Individual tools that must be present | Requiring a tool the target profile disables |
| `fallback_for_toolsets` | Skill appears only when a toolset is absent | Inverting this with `requires_toolsets` |
| `session_platforms` | Session channels the skill is for | Treating it as an OS gate |

Audit these in Phase 0, before any rollout. A trigger-phrasing audit cannot
catch a load-condition defect: the description can be perfect while the skill
never reaches the model.

Executable check:

```bash
hermes skills list --source local
```

Then confirm the skill appears in the index a real session sees, not merely in
the installed inventory. An `enabled` row in `skills list` is not evidence of
loadability; the index the agent receives is.

A run's Phase 0 record should state, per gate: satisfied, deliberately
unsatisfied, or unknown. Unknown is a finding, not a pass.

## The tree is the unit of optimization

The dominant architecture is a thin `SKILL.md` index with procedure and detail
deferred to `references/`. That makes several single-file assumptions wrong:

- **Snapshot the directory, not the file.** A baseline that copies only
  `SKILL.md` cannot reproduce the artifact, and it cannot diff a reference edit.
- **Validate against sibling roots.** Baseline and candidate must be whole
  directories with identical structure, differing only in content, so relative
  links resolve the same way in both.
- **Edits can create files.** A proposal that adds `references/foo.md` changes
  the snapshot, the reference table, and possibly the length budget. Treat the
  new file, its link, and its table row as one edit.
- **Progressive disclosure is a budget.** Moving content out of `SKILL.md` is an
  optimization only if the reference stays reachable from the index. An
  extracted section with no link is a deletion.

### Mechanical checks to run after an edit

```bash
ls -R <skill-root>
grep -rn "references/" <skill-root>/SKILL.md
```

For every `references/...` path named in `SKILL.md`, assert the file exists. For
every file in `references/`, assert some index document links it, or record it
as intentionally unreferenced. A reference nobody links is dead weight that
counts as size and never loads.

## Config belongs in declared metadata

Shell environment variables set inside a run are invisible to the skill's real
users. Hermes supports declared skill config variables:

```yaml
metadata:
  hermes:
    config:
      - key: skillopt_edit_budget
        description: Maximum accepted edits per epoch
        default: 4
```

They resolve to `skills.config.<key>` in `config.yaml` and are discoverable
without reading the skill source. Use this for knobs a user should be able to
change (edit budget, epoch ceiling, cost threshold) and keep only run-local
mechanics in environment variables. Document both, and state which wins.

## Distribution and naming

- Install from the repository or a skill registry, and verify discovery after
  install rather than assuming the copy is live.
- **Preflight the slug.** A locally installed skill can share its name with a
  registry skill of the same slug, in which case a registry query resolves to
  the other package. Confirm identity with a version string or a skill-specific
  probe before installing or referencing by name, and prefer an unambiguous
  name when publishing.
