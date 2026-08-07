# SkillOpt testing and quality gates

This repository contains a methodology skill plus legacy shell runners that manipulate Kanban state and write structured run artifacts. The highest-risk failures are not cosmetic documentation errors: they are lost task instructions, incorrect state paths, broken phase handoffs, malformed artifact pyramids, and silent CLI failures.

## Risk tiers and test allocation

| Risk | Failure impact | Required evidence | Test level |
|---|---|---|---|
| P0 | A run loses its target, task content, validation evidence, or accepted edit | Deterministic end-to-end phase-chain smoke; seed/archive artifact assertions; blocking CI | Integration and contract |
| P1 | A phase computes or records the wrong result, or a supported path breaks on a boundary | Focused regression tests for metrics, task parsing, slugification, special characters, and pyramid generation | Unit and integration |
| P2 | A documented command, template, or entry-point contract drifts | Template and repository contract checks; manual Hermes CLI verification when Hermes is installed | Contract and inspection |
| P3 | Readability, examples, or optional reporting quality degrades | Documentation review and exploratory inspection | Advisory/manual |

The test shape is intentionally integration-heavy for a CLI tool. Unit tests protect pure artifact and metric logic; deterministic integration tests exercise the shell-to-Python-to-stub-CLI boundaries; a single phase-chain smoke test protects orchestration. No test contacts a live Hermes service, a real Kanban board, or the network.

## Blocking pull-request gates

1. `bash -n scripts/*.sh` passes.
2. Python sources and tests compile.
3. `templates/*.json` parse and satisfy their required structural contracts.
4. The complete standard-library test suite passes on the supported Python 3.8 and 3.11 matrix versions.
5. The phase-chain smoke test reaches merge and proves the accepted edit is written to the target workspace.
6. Seed and archive integration tests prove artifact preservation and safe handling of shell-active task text.

A failure blocks the pull request. Tests must be deterministic and isolated. The workflow does not retry a failed test; a failure is investigated as a real failure unless a separate run demonstrates a flake.

## Advisory evidence

- Coverage is diagnostic, not a release threshold. Use it to find untested P0/P1 paths, not to reward line execution.
- Mutation testing is targeted review evidence for changed high-risk logic, not a universal score gate. Preserve the raw report, classify every in-scope mutant, and independently review meaningful survivors.
- Verification against the installed Hermes CLI is an additional local or dedicated environment check because the generic repository CI does not install the Hermes application. The preflight is:

```bash
hermes --help
hermes kanban --help
hermes kanban boards --help
```

## Regression rules

Every fixed runner defect gets a permanent regression test. New tests should be derived from behavior and artifact contracts rather than from the current implementation. Use boundary-value analysis for counts, epoch values, and slugification; equivalence partitions for valid and invalid task files; and state-transition coverage for the phase chain.

When a blocking test fails, rerun it at most once. A pass on the one rerun is recorded as a flake and quarantined rather than counted as a clean pass. No second retry is allowed.

## Local commands

```bash
bash -n scripts/*.sh
python3 -m compileall -q scripts tests
python3 -m unittest discover -s tests -v
```

The tests use only the Python standard library and deterministic temporary fixtures, so they can run without Docker, network access, API keys, or a live Hermes installation.
