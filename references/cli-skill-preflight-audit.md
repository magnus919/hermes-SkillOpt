# CLI Skill Pre-Flight Audit

Before running SkillOpt on a CLI/tool reference skill, conduct a systematic audit to establish ground truth about what the skill documents vs. what the actual tool provides. This prevents optimizing the wrong things — you want to find out the skill is missing 50% of the CLI's commands *before* Rollout, not during Reflect.

## The Process

### Step 1: Get the tool's actual command list

Two sources — use both:

**Source A — help output:**
```bash
/Applications/SomeTool.app/Contents/MacOS/sometool help
```
Always use the actual binary, not a wrapper or alias. If the tool is available via multiple paths (app bundle vs. Homebrew), check both — they may be different CLIs with different semantics.

**Source B — official docs:**
- `https://help.tool.com/cli` or equivalent
- Check for `/llms.txt` at the docs root
- web_extract the main CLI documentation page

### Step 2: Build a command inventory from the real tool

For each command in the help output, record:
- Command name and subcommands (e.g., `property:set`, `base:create`)
- Required vs. optional parameters
- Flags
- One-line description of what it does

Group commands by category (Search, Create/Edit, Dev, etc.). This becomes your ground-truth reference — the complete list of everything a user could do with the tool.

### Step 3: Cross-reference against the current skill

For each command in your inventory, check:
- Is it documented in the skill? (yes/no/partial)
- If yes: is the syntax correct? Are all subcommands covered?
- If no: is it a common workflow command or an edge case?
- Is it buried in a hard-to-find location (pitfalls, advanced sections)?

Build a coverage table:

| Category | Commands in CLI | Commands in Skill | Coverage |
|----------|----------------|-------------------|----------|
| Search/Read | search, surf, read, info, stats | search, read | 50% |
| Create/Edit | create, append, template | create, append | 66% |
| Properties | property:set, property:read, property:remove | property:set | 33% |
| Dev tools | plugin:reload, dev:errors, dev:screenshot, ... | all covered | 100% |
| ... | ... | ... | ... |

### Step 4: Categorize gaps by severity

- **Critical** — commands needed for basic workflows that are completely undocumented (e.g., `unresolved`, `stats`, `workspace`). These will cause validation task failures.
- **Medium** — commands that fill common use cases but users can work around (e.g., `surf` for grep-style search when `search` exists)
- **Low** — edge case commands, power-user features, or commands documented but in hard-to-find locations

### Step 5: Feed into task design

Use your gap analysis to design training and validation tasks:

- **Training tasks** should probe the commands the skill DOES document (to establish baseline behavior)
- **Validation tasks** should primarily test the *gaps* — commands that should be added (to measure whether edits work)
- Include at least one validation task for each critical gap

> **Example from obsidian-cli (June 2026):** The audit revealed the skill documented ~15 of ~30+ CLI commands. Three validation tasks were designed specifically around the critical gaps: `unresolved` (broken wikilinks), `stats`/`info` (file statistics), and `workspace:save` (workspace layouts). None of these commands existed in the skill — the validation gate would definitively measure whether coverage edits worked.

### Step 6: Always verify against the running binary

Documentation websites can be out of date. The actual `--help` output from the running binary is the single source of truth. If the help output and the docs disagree, the binary wins.

Check for:
- **Version mismatches** — the skill says "Requires X to be open" but the docs say "If not running, launches X"
- **Binary ambiguity** — multiple install paths with different semantics (e.g., app bundle CLI vs. Homebrew CLI that needs an API key)
- **Missing prerequisites** — the tool needs to be enabled in settings, or requires a minimum version

## Credentialed Follow-Up After Synthetic Optimization

When an initial CLI SkillOpt run was limited to help and dry-run probes, treat later credential access as a new post-publication run, not an extension of the completed synthetic epochs:

1. Record the merged commit as epoch 0 and branch afresh from current canonical `main`.
2. Reuse the synthetic run as provenance, but create distinct live training and validation tasks.
3. Restrict mutations to clearly named run-owned fixtures and capture every returned object ID.
4. Clean up only those exact IDs, then verify cleanup through a bounded read that includes archived or deleted records when supported. A successful mutation response alone is not cleanup proof.
5. Keep untouched controls in scope and verify the run never modified them.

For CLIs that classify raw queries versus mutations, use paired causal probes instead of trusting a keyword regex:

- harmless reads where the mutation keyword appears in a string, alias, operation name, fragment name, comment, or nested field;
- a real mutation without confirmation as the positive safety control;
- the same mutation in dry-run mode without credentials, proving preview and execution gates are distinct.

The classifier passes only when harmless reads execute normally and the real mutation is stopped at the intended confirmation layer.

## When to Skip This Audit

- The skill is about a conceptual method (writing process, methodology, decision framework) with no external tool to audit
- The skill is creative/artistic (image generation, writing) where the "tool" is the model API which changes too fast to pin down
- The skill was created this session from scratch — there's no existing content to audit

## Worked Example: obsidian-cli (June 2026)

The full audit of the `obsidian-cli` skill ran in about 10 minutes:

1. **Ran** `/Applications/Obsidian.app/Contents/MacOS/obsidian help` and `web_extract https://help.obsidian.md/cli`
2. **Built inventory:** Found 30+ commands across 10 categories (search, create, daily notes, properties, tasks/tags, links, navigation, workspace, publish/sync, plugin dev)
3. **Cross-referenced:** The skill covered ~15 commands. Missing: `surf`, `info`, `stats`, `publish`, `sync`, `template`, `workspace`, `bookmark`/`bookmarks`, `bases`/`base:views`/`base:create`/`base:query`, `aliases`, `command`/`commands`, `headings`, `outgoing`, `devtools`, `dev:debugger`, `dev:cdp`, `css:get`, `plugins`/`plugin:install`, `unresolved`
4. **Discovered:** The Homebrew `obsidian` binary requires `OBSIDIAN_API_KEY` — a completely different CLI from the app bundle binary the skill documents
5. **Designed tasks:** 3 training tasks for documented commands + 3 validation tasks targeting critical gaps
