# Creative Skill Optimization

SkillOpt is designed for skills with measurable task outcomes. Creative skills (image generation, writing, video composition) where "correctness" is subjective require adaptation. This reference documents the pattern validated across the image-magnus919 3-epoch optimization run (May 2026) and the groktopus-branding 2-epoch run.

## The Problem

Creative skills produce output where quality is subjective. You cannot run "lint --strict" on a cover image or count "correct" paragraphs in a draft. Standard validation gates (pass/fail on task completion) don't distinguish effective from ineffective edits.

## The Pattern: Measurable Wrappers

Instead of evaluating the creative output directly, wrap it in **measurable dimensions** that are binary: either the agent followed the rule or it didn't.

### Dimensions Used in image-magnus919

| Dimension | Measurable Check | Example |
|-----------|-----------------|---------|
| **Template fidelity** | Was the locked template used verbatim (only SUBJECT changed)? | Grep for template lines outside the subject block |
| **Path selection** | Did the agent choose the correct generation path? | Binary: Path A (no ref) vs Path B (ref exists + relevant) |
| **Format compliance** | Was the output processed to 1600px JPEG Q85? | File size, dimensions, format check |
| **Error handling** | Was the appropriate recovery pattern applied? | Safety workaround, timeout retry, empty output rewrite |
| **Decision correctness** | Did the agent make the right judgment call? | Subject derivation process followed, relevance gate applied |
| **Cleanup** | Were intermediate files removed? | Old cover deleted, frontmatter updated |

### How to Define Tasks

Training and validation tasks for creative skills should describe the **subject and constraints**, not the expected creative output. The evaluation checks the **process**, not the result:

- **Good:** "Generate a cover for article X. The SUBJECT must be concrete, capture a friction point, and contain no style words. Output must be 1600px JPEG Q85."
- **Bad:** "Generate a beautiful cover that looks like this description." — unmeasurable.

### Rollout Evaluation

For creative skill rollouts, the subagent produces both the creative output AND a report documenting:

1. Which path they chose and why (tests decision making)
2. Whether the template was used verbatim (tests rule following)
3. What processing steps were taken (tests workflow compliance)
4. Any issues encountered (tests error handling awareness)

The report IS the measurable artifact. The image IS the creative artifact. They serve different evaluation purposes.

### Rollout Subagent Style Drift

When running rollouts for image generation or illustration skills, be aware that **subagents cannot faithfully reproduce a locked style template.** The style is a text description passed to an image model — there is no "lint check" for visual fidelity. Subagents generate in the model's default aesthetic (often polished, magazine-cover quality) rather than the specific style described in the template (e.g., frantic dip-pen linework, ink splatter, controlled delirium).

**How to interpret rollout images for creative skills:**

- The **subject** (what is in the scene, the conceptual metaphor) IS meaningful — rollouts validate that the subject derivation process works and the friction point is captured.
- The **style** (how it looks) is NOT meaningful — rollouts will drift toward the model's defaults. This does not indicate a problem with the style documentation.
- The **workflow compliance** (template verbatim, correct output format, path selection, error handling) IS the measurable signal for creative skills.

Document this distinction explicitly when presenting rollout results so the user knows which artifacts to evaluate and which to ignore for style fidelity.

**Worked example from image-magnus919 Epoch 1-3 (May 2026):** Subagents consistently produced magazine-cover-quality images with polished compositions instead of the gonzo frantic linework described in the locked template. The subjects were excellent and faithful to the derivation process. The style drift was expected and did not indicate a flaw in the template — it was a limitation of text-to-image evaluation for style fidelity.

**Worked example from groktopus-branding Epoch 1-2 (May 2026):** Subagents designed cover layouts following the vintage steel engraving brand templates (Pattern A-E) but the actual generated images showed anatomy glitches and surface-level engraving effects rather than true 19th-century etching quality. Again, the decision making (which pattern, which register, which demographic) was correct — the execution fidelity was a model limitation, not a skill limitation.

## Acceptance Criteria: Propose Before Validating

**Critical lesson from the image-magnus919 run:** When defining acceptance criteria for creative tasks, you MUST present the criteria to the user as part of your Proposals presentation, before running the validation gate. The user may disagree with the criteria — as happened with the "~30 word max SUBJECT" criterion that the user correctly rejected as contradicting the rich, detailed subjects that produce the best covers.

**How to prevent this:**
1. Include the acceptance criteria alongside each proposed edit in Phase 3 (Propose).
2. Ask: "Here's how I plan to evaluate success — are these criteria right?"
3. If the user adjusts the criteria, update them before running Phase 4 (Validate).
4. Document accepted criteria in the validation record so future epochs don't re-propose the same rejected standard.

This is distinct from the "buried content" trap (a content-discovery issue) — this is a criteria-quality issue. See the skillopt SKILL.md pitfalls for both.

## Style-Catalog Validation

For skills that recommend reusable named visual treatments, validate two layers in order:

1. **Routing before rendering.** Use text-only training and held-out tasks spanning different registers. Require one named treatment, a use-case rationale, and a scene-free style clause. Test that two independent workers applying the same exact treatment reproduce the clause verbatim, and that an explicit style outside the catalog remains allowed.
2. **Representative rendering after approval.** Generate only a small sample across distinct registers. Parent pixel review checks the catalog's observable markers plus identity, anatomy, and composition gates. The user remains the final style-fidelity gate.

A style clause defines rendering grammar only. Keep character identity, scene, action, setting, props, and narrative events outside it. Avoid named-artist or studio shorthand; specify medium, materials, light, palette, texture, depth, and print/film behavior directly.

## Identity-Preserving Probe Design

Do not make a style-validation scene also age, de-age, slim, enlarge, sexualize, injure, disfigure, or otherwise transform a known subject unless the user explicitly approved that transformation as the behavior under test. An agent-authored scenario is not user consent. Such probes confound style fidelity with portrayal preference and can produce a technically correct but personally unacceptable artifact.

Prefer neutral identity-preserving uncanny or stylistic probes: independent same-age reflection movement, impossible shadows, changed lighting, altered setting, or spatial inconsistency. If the user rejects a transformation:

1. Classify the trajectory as `criteria-invalid`, not as a model or skill failure.
2. Exclude it from baseline and candidate metrics.
3. Replace only that paired held-out task and its generated artifact.
4. Preserve the rejected artifact as evidence until the replacement passes.
5. Require user acceptance of the corrected portrayal before Merge.

## Image Fidelity Is Conjunctive

Style remains subjective, but several pixel-level image properties are binary enough to gate:

- Requested left/right orientation matches the direction the nose points.
- A known person's identity remains recognizable before and after a correction.
- Every clearly visible human hand has five plausible digits including the thumb.
- Body guidance is present without becoming a caricature.
- The authoritative identity reference remains primary on every retry.

Score these from the pixels, not the worker's report. A worker can call a reversed profile correct, miss a six-fingered hand, or excuse failed proportions as a soft pass. Preserve criterion-level failure identities: fixing body proportions while replacing the face or creating a squat caricature is a regression even if the task remains FAIL in both baseline and candidate.

**Correction rule:** retries must keep the original authoritative character reference as the primary input. Never replace it with the previous generated attempt; that turns a correction loop into compounding identity drift. Reject a correction that improves geometry by weakening likeness.

## Application to Other Creative Skills

### Writing Skills (write-draft)

| Dimension | Measurable Check |
|-----------|-----------------|
| Voice compliance | Zero emdashes, contracted negatives, no banned phrases |
| Structure | Thesis in first 3-4 paragraphs, descriptive H2s, conversational transitions |
| Citations | Every claim has inline link, no fabricated sources |
| Frontmatter | Correct site profile, all required fields present |

### Video Composition Skills (hyperframes)

| Dimension | Measurable Check |
|-----------|-----------------|
| Scaffold compliance | Used `npx hyperframes init` (not standalone HTML) |
| Animation engine | GSAP `gsap.timeline()` only (not WAAPI/RAF) |
| Lint pass | `npx hyperframes lint --strict` returns 0 errors |
| Render checklist | Duration matches data-duration, visual frame extracted |

## Validation Strategy

When all tasks pass at baseline (common for well-established creative skills), use the **all-pass-baseline** acceptance criteria:

1. **Zero regressions** — post-edit pass rate must remain 100%
2. **Structural correctness** — verify the edit was applied correctly
3. **Manual navigability check** — for navigational/referential edits, verify the new pointer leads to the right content

Do NOT fabricate harder tasks to claim validation improvement. Do NOT add time-to-answer measurement. Document the acceptance rationale explicitly.

## Tested Example: image-magnus919 Epoch 1-3

The full 3-epoch cycle on image-magnus919 used these wrappers:

- **Epoch 1 (Structure):** Template fidelity, Path B checklist compliance, output format, key extraction method
- **Epoch 2 (Decisions):** Path selection relevance gate, subject derivation process step count, cover format decision table row count
- **Epoch 3 (Patterns):** Orphaned reference discovery, iterative refinement fallback usage, error recovery table row application

All 9 training tasks and 9 validation tasks passed across 3 epochs. The creative output quality was confirmed by user acceptance of the generated images — the external validity check.

## Tested Example: groktopus-branding Epoch 1-2

- **Epoch 1 (Structure):** Pattern templates extracted to reference file, Pattern Selection Quick Reference table, cover-composition-patterns wired
- **Epoch 2 (Decisions):** Diversity differentiation rule, ambiguous pattern resolution guidance, inline illustrations cross-reference

All 6 training tasks and 6 validation tasks passed across 2 epochs.
