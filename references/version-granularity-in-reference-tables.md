# Version Granularity in Reference Tables

A cross-cutting observation from SkillOpt Epoch 1 on `hugo-theme` (June 2026).

## The Problem

A skill's SKILL.md may claim a single version number in frontmatter (e.g., `hugo-version: v0.154+`), but individual features documented in its reference files often require different minimum versions. In the hugo-theme case:

| Feature | Actual minimum | Frontmatter claim |
|---------|---------------|-------------------|
| Base template blocks | v0.120+ | v0.154+ |
| Partial decorators | v0.154+ | v0.154+ |
| css.TailwindCSS | v0.161+ | v0.154+ |
| Content adapters | v0.126+ | v0.154+ |
| Hugo Modules workspace | v0.109+ | v0.154+ |

The single frontmatter number misleads: it's simultaneously too restrictive (agents think v0.120 is too old for basic templates) and too permissive (agents try css.TailwindCSS on v0.155 and fail).

## The Fix

Replace the single frontmatter version with a version column in the SKILL.md reference table. This lets:

- **Agents** route to the right reference file based on what version they're running
- **Users** quickly see which Hugo version they need for a given task
- **Authors** annotate per-feature minimums without maintaining separate version matrices

## Implementation Pattern

The SKILL.md reference table gains a "Hugo Min" column between "Topic" and "Load when...":

```
| Topic | Hugo Min | Load when... | File |
|-------|----------|-------------|------|
| **Template Architecture** | v0.120+ | ... | `references/...` |
| **Asset Pipeline** | v0.161+ | ... | `references/...` |
```

The frontmatter `hugo-version` field then becomes a range or general guidance:
```
hugo-version: v0.112+ (see version column in reference table for feature-specific minimums)
```

## When to Apply

Use this pattern when:
- The skill covers features released across 2+ major Hugo/software versions
- The frontmatter version claim is a compromise between old and new features
- Rollout agents consistently try unsupported features and hit errors
- A user asks "why didn't X work?" and the answer is "you need a newer version"

## When NOT to Apply

- The skill covers a single stable API with no version-specific features
- The feature set all shipped in the same release
- The skill's minimum version is set by a single binding constraint (the oldest feature)
