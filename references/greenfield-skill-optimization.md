# Greenfield Skill Optimization

Optimizing a skill that has never been used — created and optimized in the same session. The standard SkillOpt methodology assumes a skill has been exercised and has known failure modes to fix. Greenfield skills have **zero usage history**, so the rollouts produce 100% pass rate and the reflection must look at *discoverability and decision guidance* instead of *bugs and failures*.

## When This Pattern Applies

- You just created a skill and the user asks you to optimize it before first use
- A skill exists but hasn't been loaded in any real session — no trajectory data exists
- The baseline rollout passes everything, leaving no failure signal to reflect on

This is distinct from the "Baseline is 100%?" case in `references/multi-epoch-progression.md`. That case describes a *mature skill* that happens to pass (e.g., `hyperframes` whose rollouts produced valid output structurally). The greenfield case is a *newborn skill* where 100% pass rate means the test was too easy — not that the skill is polished.

## The Three Shifts

### Shift 1: The Baseline Tells You Nothing

In greenfield SkillOpt, a 100% baseline pass rate is expected. The training tasks were designed from the same knowledge the skill was built from — of course the agent passes them. The baseline tells you:
- The skill isn't contradictory (it won't fail on its own terms)
- The task design is consistent with the skill content

It does NOT tell you:
- Whether the skill is discoverable from cold start
- Whether the right content is prominent or buried
- Whether an agent can navigate to the right reference without guidance

**The reflection must shift from "what failed?" to "what would an agent miss?"**

### Shift 2: Epoch 1 Tests Prominence, Not Correctness

Standard Epoch 1 asks "what is wrong?" — structural cleanup, ghost patterns, missing coverage. The rollout trajectories reveal what agents do wrong. Greenfield Epoch 1 has no trajectories to reveal this, so you must **evaluate the skill text directly**:

| Signal | What to Look For | Example from spec-driven-development Epoch 1 |
|--------|-----------------|----------------------------------------------|
| Key principles in reference files, not SKILL.md | Content that changes every decision is one load-away | 6 core SDD principles were in `references/sdd-overview.md` — moved to SKILL.md as hard-gate blockquote |
| Template-to-phase mapping is implicit | Agent must infer which template belongs to which pipeline phase | Template table had "Purpose" column — replaced with "Pipeline Phase" showing SPECIFY/DECOMPOSE/VERIFY |
| User's primary use case not in trigger conditions | Agent may not discover the skill for its intended purpose | "Software factory" was the last trigger condition — promoted to first |
| Quick start is a list, not a guided walkthrough | Agent has steps but doesn't know which reference to load at each step | Quick Start list replaced with "Load This Reference" column linking each step to its reference file |

**The diagnostic question for greenfield Epoch 1:** *If an agent loads this skill cold — no context, no prior knowledge, just the SKILL.md — can it produce correct output without loading a reference file? For each "yes," that content should be inline. For each "no," the reference file's trigger condition must be unambiguous.*

### Shift 3: Epoch 2 Pre-Loads Decision Intelligence

Standard Epoch 2 asks "how should the agent decide?" — but it has the benefit of rollout trajectories showing which decisions confused agents. Greenfield Epoch 2 must **pre-load decision intelligence** — anticipate what decisions an agent will face and provide the guidance before the confusion manifests.

| Decision Type | Greenfield Question | Template from spec-driven-development |
|--------------|-------------------|---------------------------------------|
| Where to start | What phase do I enter given what I already have? | Pipeline Entry Points table: vague idea → SPECIFY, approved spec → DECOMPOSE, code → VERIFY |
| How much process | Do I need all gates for this change? | Pipeline Mode table: Full / Lightweight / Minimal with risk-based selection criteria |
| Which methodology | What format do I use for this concern? | Methodology Quick-Pick table: REST → OpenAPI, behavior → Gherkin, contracts → DbC |

**The diagnostic question for greenfield Epoch 2:** *What questions will an agent ask when it first encounters this skill? For each question, does the SKILL.md answer it inline, or does the agent need to load a reference file to find the answer?*

## Training Task Design for Greenfield

Greenfield training tasks should probe **structural quality**, not correctness:

| Task Type | What It Tests | Example |
|-----------|--------------|---------|
| Produce artifact from template | Can the agent navigate the template and reference structure? | "Write a SPEC.md using the skill" |
| Navigate pipeline | Can the agent determine which phase to enter? | "You have a complete spec — where do you start?" |
| Select methodology | Can the agent choose the right methodology from the quick-pick table? | "You need a REST API spec — what format?" |
| Compress the process | Does the agent know when gates can be skipped? | "One-line bug fix — do you run the full pipeline?" |
| Route between frameworks | Does the skill help agents choose among sibling portfolio skills? | "I have three specialist agents — is this the right skill?" |

These tasks pass/fail doesn't measure correctness — it measures **whether the skill's structure is self-guiding**. A pass means the agent could navigate the skill. A fail means the skill lacks a necessary signpost.

### Conversational and capability-matchmaking skills

For skills that guide an open-ended conversation rather than produce a file or command, use small synthetic one-turn scenarios with explicit rubrics. Score observable behavior: consent, one-question pacing, reflection before probing, uncertainty labeling, agency boundaries, capability classification, and truthful routing to existing tools versus a new skill or CLI. Keep training and validation scenarios distinct by life domain and failure mode. A 100% rollout pass is still a greenfield signal, not proof of quality: reflect on whether the skill makes the right decision visible at the moment it matters, then validate edits against unseen conversational scenarios.

## Portfolio-Awareness Check (Pre-Epoch 1)

When the skill being optimized is part of a portfolio of sibling skills covering related territory (e.g., framework skills like LlamaIndex, LangGraph, PydanticAI), add a pre-Propose audit step:

1. **List the sibling skills** — what other skills in the user's collection cover overlapping or adjacent territory?
2. **Check for routing guidance** — does the skill being optimized help agents choose between it and its siblings? If not, that's a structural gap Epoch 1 should address.
3. **The routing table pattern** — the standard template is a scenario-to-skill table with columns for Scenario, Reach For, and Why. This is more actionable than a flat "When NOT to Use" list because it proactively routes the agent to the correct sibling.

**Why this matters for greenfield runs:** Greenfield skills are often created in response to the user acquiring or investing in a new tool. That tool almost always exists alongside alternatives the user already has skills for. A greenfield skill published without routing guidance creates a cross-reference gap that agents won't discover organically.

**Worked example:** The llamaindex greenfield run (July 2026) initially had a flat "When NOT to Use" list with three exceptions. The user corrected: "Add to your considerations when to use / not use: we are building skills for other AI frameworks like langgraph & pydanticai with more coming. So why or why not llamaindex when we have other frameworks to choose from?" The fix replaced three defensive exceptions with a 9-row routing table covering 5 frameworks.

## Worked Example: spec-driven-development (v1.0 → v1.1.0)

| Dimension | Standard Pattern | Greenfield Pattern |
|-----------|-----------------|-------------------|
| Skill prior | Used in production for weeks | Created in the same session |
| Baseline rollout | Revealed 3 specific failures | All 3 tasks passed — told us nothing about quality |
| Epoch 1 focus | Fix known bugs | Move buried content to prominence, add phase anchors, fix trigger conditions |
| Epoch 2 focus | Fix known decision confusion | Pre-load entry points, mode selection, methodology quick-pick |
| Reflection method | "What failed in rollouts?" | "What would an agent miss on cold load?" |
| Validation signal | "Did the fix resolve the failure?" | "Did the agent navigate correctly without being led?" |
