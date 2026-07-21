# Multi-Skill SkillOpt Patterns

Observations from running SkillOpt on 3 skills in a single session (2026-05-31): hyperframes → image-magnus919 → groktopus-branding.

## Cross-Cutting Patterns

### The 3-Epoch Arc Recurred Across All Skills

Every skill followed the same progression naturally, regardless of type:

| Epoch | Pattern | hyperframes | image-magnus919 | groktopus-branding |
|-------|---------|-------------|-----------------|-------------------|
| 1 — Structure | Scaffold hard-gates, orphaned references | ✅ Scaffold + GSAP gates | ✅ Path B checklist, assets moved | ✅ Pattern ref file, Quick Reference table |
| 2 — Decisions | Path selection, when-to-use rules | ✅ Template fix, render config table | ✅ Subject derivation, path selection table | Ambiguous pattern, diversity differentiation (proposed) |
| 3 — Patterns | Edge cases, error recovery, orphaned refs | ✅ Custom fonts, dual audio, lint recovery | ✅ Triptych wiring, error recovery, refinement fallback | — |

### The "Buried Content" Trap Is Universal

In all 3 skills, the first set of proposed edits were "add missing content" — and in all 3 cases, that content already existed elsewhere in the skill. The rollout agents simply weren't reaching it. This suggests a structural failure mode: **agents read the Procedure section and stop**. Anything in Pitfalls, references, or advanced sections after the Procedure is invisible to rollout agents.

**The fix is prominence, not duplication.** For all 3 skills, the edits that survived validation were: cross-references at the point of use, hard-gate blockquotes, and summary tables that point to existing detailed content.

**Detection heuristic in Propose phase:** Before writing any add-type edit, search the full skill AND all linked reference files. If the content already exists, your edit type changes from "add" to "prominence" — a cross-reference, a blockquote alert, or a reorder.

### Progressive Disclosure Is the Right Architecture

The inverse is also true: if the incoming edits are "add more" on a skill that's already 30KB+, the right move may be to EXTRACT rather than add. The groktopus-branding Epoch 1 is the worked example: 5 inline cover templates (~200 lines) were moved to a reference file, replaced with a 5-row summary table. The skill lost ~200 lines and gained discoverability.

**When to extract:** Inline content that is (a) longer than ~50 lines, (b) only needed in a subset of task types, and (c) has a natural summary form (a table, a list of links, a decision matrix). General procedure and hard rules stay inline.

### Creative Skills Need Different Metrics

| Dimension | Code/Tool skill | Creative skill |
|-----------|----------------|----------------|
| Style fidelity | Deterministic (lint, compile, test) | Human-in-the-loop (subagents can't verify) |
| Acceptance criteria | Binary (pass/fail) | Need user iteration (first draft likely wrong) |
| Subject derivation | N/A | The highest-leverage improvement (process over template) |
| Error recovery | Tool errors, API failures | Safety rejections, blank output, style drift |
| Output validation | Exit code, diff, file check | Visual frame check, user approval |

### The Subject Derivation Process Was the Highest-Impact Improvement

Across all 3 skills, the single edit that produced the most visible quality improvement was the 5-step subject derivation process in image-magnus919 (Epoch 2, Edit 1). This is not a coincidence: creative skill output quality is limited by the quality of the SUBJECT, not by the quality of the style template. A structured process for getting from thesis to visual metaphor is worth more than any number of style tweaks.

For future creative-skill SkillOpt runs: prioritize subject derivation over style description, unless the style template itself is broken (which it usually isn't).

### Rollout Can Surface Template Content Defects

SkillOpt was designed to evaluate skill changes by executing tasks, not by reading the skill text. But the same mechanism can surface defects that have nothing to do with the skill's methodology — specifically, template files with wrong content.

The sdd-verification Epoch 1 run (2026-06-05) is the worked example. During Rollout, training task agents produced VERIFICATION.md outputs with task-plan structure instead of verification-report structure. Investigation revealed that `templates/VERIFICATION.md` contained TASK-PLAN.md boilerplate — task cards, critical path, and implementation directives — because the file was accidentally copied from the wrong source during skill creation. The filename was correct but the content belonged to another skill entirely.

**Pattern:** When creating multiple template files with similar naming patterns (SPEC.md, TASK-PLAN.md, VERIFICATION.md, REVIEW.md) in a batch, each file's content must be verified independently. Relying on filenames alone is insufficient — especially when templates share structural patterns (frontmatter, revision history, placeholder variables).

**Detection:** Rollout task agents will produce structurally valid but semantically wrong output. The output looks correct (markdown, tables, sections) but contains task-plan concepts in a verification-report context. This manifests as a failure mode where the agent's output passes format validation but fails content-appropriateness checks. Static review of the template files before Rollout would catch this, but the Rollout signal is what makes it visible — the agent tries to use the template and produces obviously wrong output.

**Prevention (pre-Rollout):** Before the first Rollout of a new-skill SkillOpt run, verify that every template file's content matches its filename and purpose. The heuristic: read the first 5 lines of each template. If the content doesn't obviously belong in a file of that name (e.g., task cards in a verification template), it's a content defect, not a methodology issue. Fix it before Rollout so the baseline reflects the intended skill behavior.

**Prevention (during skill creation):** When creating a batch of template files, create and verify one at a time rather than copying a sibling and modifying. Copy-from-sibling is especially dangerous when the siblings have different output structures (a verification report has nothing in common with a task plan beyond frontmatter conventions). Each template should be authored independently against its own output contract, not adapted from a similar file.
