# Tool Bugs Found During Validation

SkillOpt validation tasks run the *actual tool*, not a simulation. This means they can reveal bugs in the tool itself that code reading alone won't catch. When validation consistently fails on a task that should work, the failure may be in the tool code, not the skill instructions.

## Worked Example: GroktoCrawl Search Bug

During SkillOpt Epoch 1 on the `groktocrawl` skill, all three search tasks failed — every search returned "No results" even though the server was healthy.

**Initial suspicion:** The skill instructions were wrong — maybe the search command syntax was incorrect or the skill was missing a step.

**Actual root cause:** A bug in the CLI tool itself — `cmd_search()` at line 324 did:

```python
data = result.get("data", [])        # gets {"web": [...], "images": []}
if not isinstance(data, list):        # dict is not a list
    data = []                         # silently clears
```

The API returned `{"data": {"web": [results], "images": [], "news": []}}` but the CLI read `data` as a flat list then threw it away when it got a dict.

**Key diagnostic for asana:** The `asana custom-fields list` command returned 404 even though the skill correctly documented the CLI syntax. The subagent found the command in the Quick Reference, ran it correctly, but got an API error. The tool-bug signal was: **command executed successfully at the CLI level (exit code 1 from API, not from argparse)**, which differs from a skill-gap signal where argparse itself rejects the command with "unrecognized arguments" or the subagent can't find the command at all.

## Diagnosis method
1. Ran validation tasks → all failed → systematic failure pattern (not flaky)
2. Checked `--json` output — empty `results` array confirmed the CLI wasn't receiving data
3. Direct API call via `curl` — confirmed the *server* returned correct results
4. Read the CLI source code — found the parsing mismatch at line 324
5. Both local and upstream CLI had the same bug — it wasn't a version issue

**Key insight:** SkillOpt's "run the tasks, don't read the skill" methodology surfaced this. A code review alone would have found the bug too, but the validation tasks made it *visible as a concrete failure* with clear evidence (empty search results). The tasks forced the investigation because the failure was undeniable and systematic.

## When to Suspect a Tool Bug

- **All tasks of a specific type fail** (e.g., all search tasks, all download tasks) while other task types pass
- **Consistent failure across varied inputs** — the same error regardless of query/URL
- **The API/server responds correctly** when tested directly (curl, browser)
- **The CLI's `--json` output shows empty/truncated data** even when the human-readable output says "success"
- **The failure is deterministic** — same input, same failure, every time

## Action Pattern

1. **Isolate the layer:** API → CLI transport → CLI parsing → output formatting. Test each independently.
2. **Read the CLI code, not just the skill:** The bug is in `cmd_search()`, not in how the skill describes search usage.
3. **Check both local and upstream copies:** A bug may exist in both, or only in one.
4. **File an issue + PR:** The bug is upstream material. The skill documents *how to use the tool*; the fix goes in the tool code.
5. **Patch locally** to unblock validation: Apply the fix to the local CLI so Epoch 2 can measure whether the skill edits improved outcomes. The skill fixes and the tool fix are independent interventions — measure the skill edit against a working tool.
