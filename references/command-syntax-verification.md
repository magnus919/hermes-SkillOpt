# Command Syntax Verification During SkillOpt

## When This Applies

When a proposed skill edit (Epoch N Propose phase) adds or changes **command-line examples** — code blocks showing CLI invocations. Prose-only edits do not trigger this verification.

## The Failure Mode

Commands that look syntactically correct when read in text may not work when executed:

- A subcommand may not exist at the level you expect (`browser snapshot` when `snapshot` is an action of `exec`, not a subcommand of `browser`)
- A flag may have been renamed or removed in a newer CLI version
- A positional argument order may be different from what the help text implies

The validation task suite does not automatically test command syntax in prose examples — it tests task outcomes. A task that scores "success" on a scrape test does not validate that a browser command block in the pitfall section is syntactically correct.

## Worked Example: GroktoCrawl Epoch 2 → Epoch 3

In Epoch 2, the browser fallback pitfall was added with these commands:

```bash
groktocrawl browser navigate <url>   # WRONG — 'navigate' is not a browser subcommand
groktocrawl browser snapshot --full  # WRONG — 'snapshot' does not exist
```

These commands were derived from reading the `browser exec --help` output, which lists `navigate`, `snapshot`, `screenshot`, etc. as actions. The Mistake was lifting action names to the subcommand level.

In Epoch 3, running the commands against the live server revealed:

- `groktocrawl browser navigate <url>` → error: unrecognized arguments
- `groktocrawl browser snapshot --full` → error: unrecognized arguments
- The correct invocations are:
  ```bash
  groktocrawl browser create --ttl 60
  groktocrawl browser exec <session> navigate --url <url>
  groktocrawl browser exec <session> executeScript --script "document.body.innerText"
  ```

## Verification Checklist

Before merging any proposed edit that contains CLI examples:

1. [ ] Identify every code block in the edit
2. [ ] For each code block, extract the first CLI command (the one the user is supposed to type)
3. [ ] Run that command verbatim against the live tool/server
4. [ ] If the command fails with a syntax error, wrong-subcommand, or unrecognized-flag, fix the edit before running validation
5. [ ] If the command succeeds, verify the output looks like what the skill describes
6. [ ] Repeat for any alternative or fallback commands in the same block

This is a manual step that sits between Propose and Validate. It's fast (normally 30-60 seconds per command block) and catches the class of error that the validation task suite is structurally blind to.
