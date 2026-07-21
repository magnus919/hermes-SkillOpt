# Multi-Epoch Progression Strategy

A worked example from optimizing the `mermaid-magnus919` skill across 3 epochs (May 2026).

## The Core Insight

**Each epoch should answer a different question about the skill.** Repeating the same kind of edit across multiple epochs wastes the edit budget. The progression follows a natural arc:

| Epoch | Question | Kind of edits |
|-------|----------|--------------|
| 1 | **What is wrong?** | Structural cleanup, ghost patterns, missing coverage |
| 2 | **How should the agent decide?** | Decision guidance, branching logic, when-to-use rules |
| 3 | **What does the output look like?** | Reference examples, pattern expansion, edge cases |
| 4+ | **What's still missing?** | Deep gaps, meta-reflection, tool-bug separation |

## Worked Example: mermaid-magnus919 (v1.0.0 → v1.0.3)

### Epoch 1 — Structural Cleanup (What is wrong?)

**Reflection finding:** All rollouts pass but agents consistently include Ghost CMS comment markers (`<!--kg-card-begin: html-->`) because the skill says they're "optional visual delimiters." On a Hugo site, these are noise.

**Edits:**
1. Removed Ghost markers from the embedding example
2. Added sequenceDiagram reference file (only flowchart existed)
3. Enhanced diagram type selection table (added "When to pick" column)
4. Added Special Characters in Labels section

**Validation:** 3/3 held-out tasks pass, no Ghost markers anywhere.

### Epoch 2 — Decision Guidance (How should the agent decide?)

**Reflection finding:** The skill documents both CDN and mmdc paths but doesn't say when to use which. The special characters section only documents one quoting approach, but agents reach for another.

**Edits:**
1. Added "When to Pre-Render" section with a delivery-target decision table (blog → CDN, RSS/email → mmdc)
2. Expanded quote escaping to document both `#quot;` entity and `\"` backslash escape

**Validation:** 3/3 held-out tasks pass, including one that's explicitly for a newsletter (agent correctly chose mmdc).

### Epoch 3 — Pattern Expansion (What does the output look like?)

**Reflection finding:** The skill says "do NOT reload CDN more than once" but doesn't show what multi-diagram output looks like. The skill handles unlisted diagram types (gantt, classDiagram) well but has no references for them.

**Edits:**
1. Added "Multiple Diagrams, One Post" section with a complete example showing first diagram with CDN, second diagram div-only
2. Added gantt chart reference file (`project-timeline-gantt.md`)

**Validation:** 3/3 held-out tasks pass, including two-diagram per post, gantt chart from reference, and regression check.

## Worked Example: hyperframes (v1.0.0 → v1.1.1)

A 3-epoch SkillOpt run on a creative/code skill (HTML-based video composition). Demonstrates the progression on a well-structured but navigationally weak skill.

### Epoch 1 — Structural Cleanup (What is wrong?)

**Reflection finding:** All 3 training rollouts produced valid compositions, but 2/3 agents wrote standalone HTML files outside `npx hyperframes init` — bypassing the scaffold → lint → validate → inspect → render pipeline entirely. 1/3 used Web Animations API instead of GSAP. The required workflow steps existed in the skill but were buried under 15+ KB of rules and reference documentation.

**Edits:**
1. Added a Pitfalls cross-reference callout at the top of the Procedure section
2. Added a CRITICAL hard-gate blockquote at Step 2 (Scaffold): "MUST use npx hyperframes init — no standalone HTML files"
3. Added a GSAP-only hard-gate at Step 4 (Animate): "Do NOT use WAAPI or requestAnimationFrame"
4. Added Step 10 to wire an orphaned reference file (blog-companion-explainer.md) into the Procedure

**Validation:** 3/3 held-out tasks all used `npx hyperframes init` (was 1/3 in baseline). All used GSAP exclusively (was 2/3). Zero regressions.

### Epoch 2 — Decision Guidance (How should the agent decide?)

**Reflection finding:** The skill's template list claimed 9 templates existed (`warm-grain`, `swiss-grid`, `vignelli`, `decision-tree`, etc.) but only 3 (`blank`, `title-card`, `video-edit`) actually ship in HyperFrames. This factual error caused agents to attempt non-existent `--example` flags. No render-config decision guidance existed — agents guessed `--quality`/`--docker`/`--format` choices.

**Edits:**
1. Fixed the template list to the 3 real templates with a selection table (when to use each)
2. Added a Render Config Quick Reference table covering `--quality`, `--format`, `--docker` (with Docker daemon check + fallback), and `--fps`

**Validation:** 3/3 held-out tasks reported the skill "directly guided" their decisions. Template choices were correct. Two tasks used `--quality draft` then `--quality high` per the table's guidance.

### Epoch 3 — Pattern Expansion (What does the output look like?)

**Reflection finding:** The skill covered custom fonts only via a buried pitfall warning. No step-by-step workflow existed for loading a font outside the compiler's auto-resolve list. The skill covered BGM and TTS separately but had no pattern for combining them (dual audio with volume ducking). The skill's lint caught errors but had no structured recovery workflow.

**Edits:**
1. Added a Custom Fonts subsection with 3 options: Google Fonts CDN, local @font-face with .woff2 in assets/fonts/, fallback substitution
2. Added a Dual Audio pattern (TTS at full volume + BGM pre-processed with ffmpeg volume=0.15, separate data-track-index values)
3. Added a Lint Error Recovery Workflow with a 5-step recovery cycle and a table of common error codes (timed_element_missing_clip_class, overlapping_clips_same_track, gsap_css_transform_conflict, etc.)

**Validation:** 3/3 held-out tasks passed. Custom font agent followed CDN→@font-face flow correctly. Dual audio agent had both sources with correct volume ducking. Error recovery agent caught `overlapping_clips_same_track`, fixed it, and rendered with clean lint.

### Key differences from the mermaid-magnus919 run

- **hyperframes had 100% baseline pass rate** — all rollouts produced valid outputs structurally, so validation measured compliance improvement, not correctness
- **hyperframes Epoch 1 uncovered content-that-existed-but-was-inaccessible** — the standalone HTML and WAAPI prohibitions were already documented in Pitfalls but agents never reached them
- **hyperframes Epoch 2 found a factual error** (non-existent templates) rather than a missing decision table — more severe than the mermaid run's equivalent epoch

## Worked Example: image-magnus919 (v1.0.0 → v1.1.0)

A 2-epoch SkillOpt run on a **creative skill** (gonzo illustration cover generation for magnus919.com). Demonstrates that the methodology works on creative skills too, but with a critical difference: validation criteria may require user iteration.

### Epoch 1 — Structural Cleanup

**Reflection finding:** The skill had strong procedural guidance but the Path B (edits API) workflow had significant undocumented friction. Agents hitting the API discovered that `response_format` is not supported (400 error), the API key gets redacted in tool output forcing workarounds, and landscape output size (1792x1024) may be rejected by some models. The skill's reference images lived in another skill's assets (blog-it), creating a cross-skill dependency.

**Edits:**
1. Added a 6-step Path B Quick Reference checklist (crop → key → size → no response_format → timeout → convert)
2. Documented edits API quirks: `response_format` rejection, key redaction workaround, landscape size fallback
3. Moved reference images into image-magnus919/assets/ (self-contained)
4. Added a SUBJECT validation checklist (concrete elements, friction point, no style words, anatomy check)

**Validation:** 3/3 held-out tasks passed. The Path B checklist was verified successful (landscape 1792x1024, no response_format error).

### Epoch 2 — Decision Guidance

**Reflection finding:** The skill said "Path B when a reference image exists" but didn't gate this on thematic relevance. An agent with an irrelevant reference (spider face for an article about prototyping) would incorrectly force it through Path B. The subject derivation process was intuitive — no structured steps for going from article thesis → visual metaphor → concrete SUBJECT.

**Edits:**
1. Added a 5-step Subject Derivation Process (extract thesis → identify friction point → brainstorm 3 metaphors → pick strongest → describe concretely)
2. Added a Path Selection Quick Reference table with a thematic relevance gate
3. Added a Cover Format Decision Table for nonstandard cover situations

**Validation:** 3/3 held-out tasks passed. Most informative result: the initial validation criteria for SUBJECT quality included a 30-word limit that the user corrected as contradicting the rich, complex subjects that produce the best covers. **The criteria themselves were wrong** — not the edits they were evaluating. This is a methodological lesson: for creative skills, validate your acceptance criteria with the user before running the validation gate.

### Key lesson for creative-skill optimization

When running SkillOpt on a skill with subjective outputs, the Propose phase should include a **criteria review step**: present your proposed acceptance criteria to the user alongside the edit proposals. The user may reject criteria that are too strict (word limits, style constraints) or too loose. This is distinct from the "buried content" trap — it's a criteria-quality issue, not a discovery issue. Add "Proposed acceptance criteria: [...] — do these match what you'd consider a successful output?" to your Proposals presentation.

## Worked Example: spec-driven-development (v1.0 → v1.2.0)

A 3-epoch SkillOpt run on a **knowledge/instruction skill** — a methodology document teaching Spec-Driven Development for AI software factories. Unlike CLI skills (which agents *run*) or creative skills (which agents *generate with*), knowledge skills guide agents through *how to write structured specs, run reviews, and verify implementations*.

### Epoch 1 — Structural Cleanup (What is wrong?)

**Reflection finding:** The skill's 6 core principles (precision over clarity, completeness over brevity, etc.) lived only in `references/sdd-overview.md`. Agents loading SKILL.md got the pipeline diagram and loading table but missed the decision philosophy that governs every spec-writing choice. The skill was structurally complete but the principles were buried one reference-file deep.

**Edits:**
1. Inlined the 6 core principles as a hard-gate blockquote after the pipeline overview
2. Added Pipeline Phase column to the templates table (mapping SPEC.md → Phase 1, REVIEW.md → Gate 1-4, etc.)
3. Reordered trigger conditions to lead with "software factory" as the primary use case
4. Replaced bare Quick Start bullet list with a phase-anchored Quick Reference table (step, action, load-this-reference, produces)

**Validation:** 3/3 held-out tasks passed. The CLI tool SPEC.md task produced measurably more thorough output (31KB, 4 stories, 19 ACs vs baseline 19KB, 2 stories).

### Epoch 2 — Decision Guidance (How should the agent decide?)

**Reflection finding:** The skill assumed the pipeline always starts at SPECIFY. But an agent joining mid-stream (with an existing spec, a task plan, or just code) had no guidance on where to enter. The skill also presented all 4 gates as mandatory, giving no latitude for simple changes.

**Edits:**
1. Added a Methodology Quick-Pick table mapping 8 concerns (REST API contracts, behavioral requirements, interface correctness, etc.) to their best-fit methodology with AI-readiness ratings
2. Added "Where to Enter the Pipeline" table (vague idea → SPECIFY, approved spec → DECOMPOSE, code → VERIFY)
3. Added "Which Pipeline Mode to Use" table (Full / Lightweight / Minimal) with gate counts and spec depth
4. Added rule of thumb: "If you know the fix in under 60 seconds and it touches one file, use Lightweight mode"

**Validation:** All 3 held-out decision tasks passed. Entry point task correctly chose DECOMPOSE. Mode selection task correctly chose Lightweight for a one-line change. Methodology selection task recommended OpenAPI + AsyncAPI + Gherkin + DbC.

### Epoch 3 — Pattern Expansion (What does the output look like?)

**Reflection finding:** The skill had templates (showing structure) and references (showing methodology) but no completed example showing the *expected output depth*. Agents had no calibration target for how many edge cases, how detailed NFRs, or how complete data contracts should be. Additionally, the skill had no guidance for what to do when a gate rejects — it said "return to current phase" but didn't walk through the iteration cycle.

**Edits (budget 2 — cosine decay):**
1. Added `references/example-spec.md` — a complete, filled-in SPEC.md for a password reset feature showing proper AC format, edge case enumeration, NFR thresholds, full JSON schemas, and assumptions. Added a row to the Loading Guide table pointing to it.
2. Added a Gate Recovery & Revision section covering: the revision loop diagram, severity-based patching actions (BLOCKING/CRITICAL/MINOR/INFO), re-review scope rules, and a table of common revision patterns with fix strategies and prevention tips.

**Validation:** Both held-out tasks passed. Worked example was discoverable via Loading Guide and provided clear calibration targets (2 stories, 5-6 edge cases per story, 7 NFRs with concrete thresholds, full JSON schemas). Gate Recovery section correctly guided a CONDITIONS-verdict scenario with mixed severities.

### Key lessons for knowledge/instruction skill optimization

- **Epoch 1 reveals buried content** — principles, rules, and decision frameworks that exist in reference files but aren't visible in SKILL.md. The fix is prominence (hard-gate blockquotes, inline tables, trigger-first ordering), not duplication.
- **Epoch 2 must address pipeline entry and mode selection** — unlike CLI or creative skills, knowledge skills describe a *procedure*. Agents need to know where to enter that procedure based on what they already have, and which mode (full/lightweight/minimal) fits their context.
- **Epoch 3 needs a worked example for depth calibration** — templates show *structure*; examples show *depth*. Without a filled-in example, agents consistently undershoot on edge case enumeration, NFR detail, and data contract completeness. Templates + examples is the correct pairing.
- **Knowledge skills need explicit recovery workflows** — when a gate rejects an artifact, agents need to know what to do next. The revision loop, severity-based patching, and re-review scope rules are not obvious from the pipeline diagram alone.

## How to Use This Pattern

When starting a SkillOpt run on an unfamiliar skill:

1. **Assess the skill's maturity.** Is it brand new? Rough but working? Already polished? This determines whether you start at Epoch 1 or skip ahead.

2. **Design training tasks that explore.** Epoch 1 tasks should probe for structural issues (does the agent follow the rules?). Epoch 2 tasks should include decision points. Epoch 3 tasks should stress edge cases.

3. **Each epoch's reflection should ask:** "What kind of question did this epoch answer?" If two epochs in a row answer the same question (e.g., both are about structural cleanup), the edit budget is misallocated.

4. **Know when to stop.** After Epoch 3 or 4, if the reflection finds only minor gaps (missing reference file, unclear phrasing), consider whether a slow-meta cycle or manual polish would be more efficient than another full epoch.

## When to Deviate

- **Baseline is 100% on first rollout?** Start at Epoch 2 (decision guidance) — structural cleanup isn't needed. The mermaid-magnus919 Epoch 2 pattern (add decision tables, expand options) is the right first step.
- **Baseline is under 50%?** Epoch 1 is critical — fix the structural failures before adding decision guidance or examples. Multiple Epoch 1 cycles may be needed.
- **Skill is documentation-heavy (CLI skills, reference guides)?** Prioritize Epoch 3-style edits early — good examples improve these skills more than decision tables.
