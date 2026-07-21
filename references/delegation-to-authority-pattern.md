# Delegation-to-Authority Pattern — Worked Example

When optimizing Skill A, the Reflect phase may reveal that some of Skill A's instructions duplicate conventions already defined in Skill B. The naive fix is to update the duplicate text in Skill A. The principled fix is to **delegate** — have Skill A's instructions tell subagents to load Skill B instead.

## When to Use

- Skill A contains a block of instructions that duplicates content from Skill B
- Skill B is the authoritative source for those conventions
- Subagents can call `skill_view(name='skill-b')` to load Skill B's instructions
- Skill A only needs a thin supplement for conventions specific to its domain

## Worked Example: news-scan → vault-note

### Before

The `news-scan` skill contained an 88-line "Vault-Note Standards for Subagents" block with 14 rules duplicated from `vault-note`. Every subagent delegation context carried ~2200 tokens of duplicate text. When `vault-note` updated its conventions, `news-scan`'s copy would silently drift.

### After

The 88-line block was replaced with a 25-line delegation:

```
1. `skill_view(name='vault-note')` in the delegation context
2. A 6-line news-scan-specific supplement for clipping filename rules
```

Benefits:
- **Single source of truth** — vault-note conventions update in one place
- **~85% reduction in delegation context** — 2200 → 250 tokens
- **No drift risk** — news-scan never has stale conventions again
- **Self-documenting** — the delegation makes the dependency explicit

### How to Apply During SkillOpt

1. **Rollout phase** — when a training task shows the subagent spending excessive tokens on boilerplate, flag the duplication
2. **Reflect phase** — identify which conventions are duplicated and which skill is authoritative
3. **Propose phase** — frame the edit as: "Replace duplicated conventions block with `skill_view()` to authoritative skill, plus a domain-specific supplement"
4. **Validate phase** — test that subagents actually CAN load the target skill via `skill_view()` (this is a framework assumption, not guaranteed for all agents)
5. **Merge phase** — apply to both skills if the authoritative skill needs a schema fix (e.g., vault-note's atom `source:` field was ambiguous)

## Validation Risk

Before merging, verify that the target agent can actually call `skill_view()` during delegation. This is a framework-level capability — it works in Hermes Agent but may not work in all consuming agents. If it fails, fall back to including the conventions inline with a note to migrate when skill_view is available.

## Related

- SkillOpt Design Principle #6: "Prefer delegation over duplication"
- Epoch 2 of the news-scan optimization (this skill's first session applying the pattern)
