# Validating Edits When Baseline Pass Rate Is 100%

When all training and validation tasks succeed at baseline (100% pass rate), the standard pass/fail validation gate cannot distinguish improvement from stagnation. This typically happens when editing an already-strong skill — the content is comprehensive but navigation or structure could be improved.

## Acceptance Criteria

1. **Zero regressions** — post-edit pass rate must remain 100%. Any edit that causes a regression is rejected.
2. **Structural correctness** — verify the edit was applied as intended (re-read the affected region, confirm markdown structure is valid).
3. **Manual navigability check** — for navigational edits (trigger maps, section indexes, flowcharts), verify the new pointer actually leads to the right content.

## What NOT to Do

- **Don't fabricate harder tasks** to claim validation improvement — that's methodological fraud.
- **Don't reject an edit just because it can't improve the metric.** Document why it was accepted despite no metric change.
- **Don't add time-to-answer measurement as a substitute** — it's noisy, confounded by LLM latency, and invalidates cross-epoch comparisons.

## Worked Example 1: agent-memory (May 2026)

During Epoch 1 of the agent-memory optimization, all 5 training and 5 validation tasks passed at baseline. The optimizer proposed navigational edits (trigger->section mapping, diagnostic flowchart, section index). These were accepted on the basis of: (a) zero regressions, (b) manual verification that each new wikilink resolves correctly. The validation record explicitly notes: `"delta: 0.0 — structural improvement to discoverability, not measurable by pass/fail"`.

## Worked Example 2: vault-note (May 2026)

Epoch 1 of the vault-note optimization had a 6/6 baseline pass rate (3 training + 3 validation). The optimizer proposed three structural/navigational edits:

1. **Atom content boundary guidance** — a blockquote after the schema table defining atoms as "single knowledge units, 1-3 paragraphs, no H2 subsections." Accepted based on: (a) zero regression — subsequent validation atom followed the guidance correctly; (b) user had explicitly corrected the scope of a training atom ("that atom is more than an atom though"), confirming the gap existed; (c) no functional task relied on H2 subsections in atoms, so adding the constraint could not create regressions.

2. **Section reorder** — moved the Note Type Schema before Knowledge Extraction. Accepted based on: (a) zero regression; (b) the schema table is referenced on every note creation while extraction ratios are task-specific, so the new order matches usage frequency; (c) manual verification confirmed all internal wikilinks and section references survived the move.

3. **Quick QA inline summary** — added a 3-check subsection (bare wikilinks, inline arrays, scoring indentation) under Post-Write QA, reducing reference-file lookups for single-note operations. Accepted based on: (a) zero regression; (b) the checks were extracted from the already-validated full QA audit, so they couldn't introduce new defects; (c) manual verification confirmed each command produced correct results on validation artifacts.

**Key takeaway:** When all tasks pass at baseline, look for user corrections as evidence of real gaps (the atom-scope correction was the signal that validated the edit). Structural edits need non-regression plus a manual check — they cannot be validated by pass/fail alone. Document the acceptance rationale explicitly in the validation record so future epochs don't re-propose the same edits.
