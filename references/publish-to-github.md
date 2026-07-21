# Publishing a SkillOpt-Honed Skill to GitHub

After a SkillOpt epoch completes on a skill destined for open source, the Merge phase applies local edits to the working copy. For local-only skills (no `.git`), those edits are invisible to version control. When you're ready to publish, use this workflow to create a GitHub repo and seed it with the skill artifacts.

## When to Use

- A SkillOpt epoch validated edits on a skill, and the skill needs a permanent home
- You're open-sourcing a skill that was previously local-only
- You need AGENTS.md, LICENSE, and repo infrastructure alongside the skill content

## Workflow

### 1. Sanitize (pre-flight)

Before creating the repo, scan the skill for personal/private context:
- Custom infrastructure references (cashew, private hostnames, personal paths)
- Internal build pipelines or cron job names
- Environment-specific configuration that won't generalize
- Attribution to unpublished or internal sources

Replace personal references with stock Hermes equivalents (`cashew auto-extracts` → `Memory provider auto-extracts`). Keep open-source-safe attribution (author handles, X/Bluesky posts, published articles).

### 2. Rename if needed

If the local skill name is too specific (`loop-designer-roadmap`) or contains internal nomenclature, rename to a clean open-source name (`loop-designer`):
- Change directory name
- Update `name:` field in frontmatter
- Update any internal self-references
- Version bump (minor — rename is a breaking change for references)

### 3. Create the repo

```bash
gh repo create <org>/<repo-name> --public \
  --description "<one-line description>" \
  --clone --license mit
```

The `--clone` flag creates a local clone of the empty repo (with LICENSE) in the current directory.

### 4. Copy skill artifacts

```bash
cp /path/to/skill/SKILL.md /path/to/repo/SKILL.md
```

If the skill has reference files, templates, or scripts, copy them too:
```bash
cp -r /path/to/skill/references /path/to/repo/
cp -r /path/to/skill/templates /path/to/repo/  # if any
```

### 5. Create AGENTS.md

An AGENTS.md file gives future agents a landing page when they're loaded into the repo context. Include:
- One-line description and source attribution
- Quick Reference table (from SKILL.md)
- Prerequisites
- Load instructions (`skill_view(name="repo-name")`)

See the loop-designer AGENTS.md at `groktopus/loop-designer` for a worked example.

### 6. Commit and push

```bash
cd /path/to/repo
git add -A
git commit -m "feat: <skill-name> vX.Y.Z — <description>"
git push -u origin main
```

**Commit prefix convention:** `feat:` for a first publish (new repo), matching the minor version bump. Subsequent SkillOpt epochs use `fix:` with patch bumps.

## Pitfalls

- **Don't forget AGENTS.md.** A repo with only SKILL.md and LICENSE is just documentation — AGENTS.md is what tells an agent how to load and use the skill from this repo.
- **Sanitize before repo creation.** Once pushed, a commit with personal infrastructure references lives in git history. Easier to catch before the first push.
- **Version humility.** A skill born this session is v0.x.y, even if the change feels significant. The version number reflects actual iteration count and cross-session stability, not ambition.
- **SKILL.md vs AGENTS.md split.** SKILL.md is the full procedural document. AGENTS.md is a quick-reference landing page. Don't duplicate the full Procedure in AGENTS.md — a Quick Reference table + load instructions + prerequisites is enough.
- **License selection.** MIT is the convention for Hermes Agent skills. If the skill contains methodology from a published paper, keep attribution in the SKILL.md body (the License section references it, but the body gives human-readable credit).
