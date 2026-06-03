# Size-Objective SkillOpt Compaction

Use this when the user asks to reduce a skill's length, token footprint, or context bloat while preserving behavior.

## Core Pattern

Treat size as an explicit optimization objective, not an aesthetic review.

1. Snapshot the live target and work in an isolated run directory.
2. Measure baseline size: lines, words, characters, and a token estimate if available.
3. Create distinct training and held-out validation suites that exercise the skill's real behaviors.
4. Add size/token efficiency to the validation objective. Keep pass rate as the hard gate; do not accept a smaller skill that regresses held-out task success.
5. Prefer structural compaction over semantic deletion:
   - Move bulky templates to `references/`.
   - Move rare setup commands to `references/`.
   - Replace repeated specialized paragraphs with a trigger-to-reference routing table.
   - Preserve critical invariants and pitfalls in the main `SKILL.md`.
6. Validate candidates by execution against held-out tasks, not by reading the compacted text.
7. Treat unvalidated compaction candidates as proposals only. Do not merge them into the live skill until held-out validation accepts them and the user approves live application.

## Candidate Shapes

Conservative candidate:
- Move full templates or long examples into `references/`.
- Keep a short main-skill pointer with the non-negotiable invariants.
- Lowest regression risk.

Medium candidate:
- Conservative move-outs plus routing tables for specialized workflows already covered by reference docs.
- Good default target for large operational skills.

Aggressive candidate:
- Compress core workflows or replace manual checklists with scripts.
- Only use when validation coverage is strong enough to catch behavioral loss.

## Scoring Guidance

Default SkillOpt weights include `token_efficiency`, but for explicit compaction runs increase its importance while preserving pass/fail dominance. Example weights:

```json
{
  "pass_rate": 0.50,
  "quality_score": 0.25,
  "speed_score": 0.05,
  "token_efficiency": 0.20
}
```

Reject any candidate that reduces held-out pass rate. With unchanged pass rate, accept only if weighted score does not regress and size reduction is meaningful.

## Pitfalls

- Do not call a smaller skill "better" without held-out execution evidence.
- Do not delete rare-but-critical setup details; move them to `references/` and keep a clear pointer.
- Do not optimize only line count. Preserve trigger phrases, hard safety rules, verification requirements, and decision tables in the main skill.
- If validation requires spawning child Hermes runs and the approval gate blocks that action, stop. Report the candidate as unvalidated rather than retrying or routing around the denial.
