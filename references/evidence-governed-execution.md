# Evidence-Governed Execution

Use this when a rollout retrieves credible sources yet still emits unsupported bridge claims, or when a command exists but its operational safety is unproven.

## The failure pattern

Evidence acquisition does not automatically govern response construction. A worker can retrieve official pages, then:

- promote hardware capability into framework-stack support;
- treat a failed search as evidence of feature absence;
- cite one project for another project's capability;
- treat `--help` as proof that a command is safe in the target's current state;
- replace an unknown component with “typical,” “usually,” or “some modules” archetypes;
- invent experimental intervals, margins, point counts, percentages, or model forms.

A claim ledger written after the prose merely rationalizes an answer already composed.

## Pre-response gate

Complete this before drafting the response:

1. **Claim ledger:** List every material positive claim, negative claim, command, and numeric design choice.
2. **Retrieval status:** A URL in a source index is navigation, not evidence. Record the directly retrieved, claim-specific, exact-chip/current-version source. Otherwise mark the claim `UNKNOWN`.
3. **No bridge claims:** Hardware availability does not prove framework integration. One framework's source does not prove another's behavior. A missing search result does not prove absence.
4. **Command contract:** `--help` proves syntax only. Separately establish target state, connection/loader requirements, reset and DTR/RTS effects, RAM-stub behavior, port effects, and mutation boundary. If these are unverified, do not present the command as executable.
5. **Unknown means unknown:** Do not substitute examples, archetypes, or “usually”/“typical” language for missing board or component artifacts. State what the observed label does not establish.
6. **No arbitrary protocol:** Derive thresholds, margins, intervals, durations, point counts, percentages, and model forms from an authoritative source or an explicit measurement criterion. Otherwise leave them unknown.
7. **Final audit:** Remove or downgrade every response claim that lacks the evidence required by its ledger entry.

## Observable gate result

An internal ledger is not auditable validation evidence. For SkillOpt trajectories, require one compact gate result beside the direct response. Each material claim or command uses one status: `CONFIRMED`, `UNKNOWN`, `REMOVED`, `ELIGIBLE`, or `BLOCKED`.

`CONFIRMED` requires a directly retrieved, exact-scope source that explicitly states the same claim. Omission, a 404, a partial or JavaScript-hidden table, a non-exhaustive list, or another framework's page never proves absence. Keep those claims `UNKNOWN`, and never use an `UNKNOWN` claim to justify a recommendation or exclusion.

The gate result should expose:

- retrieved sources used;
- material claims left `UNKNOWN`;
- command eligibility plus reset/loader/stub effects;
- blocked actions;
- unsupported claims removed before emission.

Score this block only as navigation into the raw response. It does not rescue a response that contradicts its own ledger. If the worker claims it removed archetypes while still emitting wire-color, component-class, or interface examples, score the literal response as a failure. Do not repeat the full answer inside the ledger.

## Observed command-side-effect example

With esptool 5.2, default `chip-id` and `flash-id` runs against a classic ESP32 uploaded a RAM stub and hard-reset the board via RTS. These are informational commands, but they were not state-neutral. Treat command names such as “read,” “info,” or “ID” as intent labels, not side-effect guarantees; verify connection mode, stub policy, and before/after reset behavior for the installed version and target family.

## Blocked-output stopping rule

When evidence is insufficient, continued explanation creates new opportunities to smuggle assumptions back in. Use the smallest response that preserves safety and forward motion:

1. **BLOCKED:** Name the action that cannot proceed.
2. **ESTABLISHED:** State only facts supported by the prompt or retrieved exact-scope evidence.
3. **MISSING:** Name the exact artifact or contract needed, without listing hypothetical component, interface, framework, or circuit types.
4. **NEXT:** Give one non-mutating evidence-acquisition step, then stop.

Do not enumerate archetypes even as parenthetical questions, cautionary examples, or a “removed claims” catalog; their presence can still anchor the response on invented possibilities. Ask for the exact datasheet electrical contract rather than listing what that contract might contain. Do not continue into downstream command catalogs, circuit choices, calibration protocols, framework comparisons, or migration designs.

A visible status table can make contradictions inspectable, but it does not make the gate binding. In held-out validation, adding a larger status vocabulary reduced pass rate because response prose continued to contradict the ledger. Prefer the four-part stop shape for blocked tasks; use a compact ledger only when the task genuinely needs several sourced claims or command-eligibility decisions.

## SkillOpt scoring

- Score the raw response, not the worker's evidence ledger or PASS label.
- A response fails an authority criterion when any material conjunct lacks direct, appropriate evidence.
- A command can pass syntax validation and still fail operational-validity or safety criteria.
- Treat unsupported generic archetypes as fabricated claims, even when presented as cautionary examples.
- Keep task-execution failures separate from evaluation-infrastructure failures such as summary-only output or unexpected file creation.

## Proposal shape

Prefer one prominent execution gate in the target skill's main `SKILL.md` over several domain-specific warnings scattered across references. Validate it on held-out tasks spanning source comparison, command preconditions, unknown hardware, and calibration or experimental design.
