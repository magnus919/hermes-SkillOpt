# Clean-Room Docker Evaluation for Skill Rollouts

When running SkillOpt rollouts or validation, you sometimes need an isolated Hermes environment — no personal config, no memory, no custom plugins. This reference covers the patterns for building and using such environments for evaluation work.

## Key Insight: The .env Delivery Problem

Hermes reads its `.env` from `PROJECT_ROOT` (the directory containing the Hermes source code, e.g. `/opt/hermes/`), **not** from `HERMES_HOME` (e.g. `/opt/data/`). The `config.yaml` lives in `HERMES_HOME`. The `.env` with API keys must go where Hermes looks for it.

### The Wrong Way: Bind Mount

```yaml
volumes:
  - ./.env:/opt/hermes/.env:ro
```

This breaks when the container user (UID 10000 for Hermes) differs from the host user (UID 1000). The mounted file inherits host ownership and permissions.

### The Right Way: docker cp

```sh
# SCP preserves bytes perfectly — no shell-level key corruption
scp ~/.hermes/.env user@remote:/tmp/env.txt

# After container starts, copy into the right location
docker cp /tmp/env.txt container-name:/opt/hermes/.env
docker exec container-name chmod 644 /opt/hermes/.env
```

`docker cp` assigns the file to the container's default user, bypassing the UID mismatch entirely.

## Session Export Path Problem

When running `hermes sessions export` via `docker exec`, the path argument is resolved **inside the container**, not on the host.

### The Wrong Way

```sh
docker exec container hermes sessions export /host/path/session.jsonl
```

### The Right Way

```sh
# 1. Export to a temp file inside the container
docker exec container hermes sessions export /tmp/session.jsonl

# 2. Copy it out to the host
docker cp container:/tmp/session.jsonl /host/path/session.jsonl

# 3. Clean up
docker exec container rm -f /tmp/session.jsonl
```

## Session ID Extraction

`hermes sessions list` has a 2-line header. Extracting the most recent session ID:

```sh
SESSION_ID=$(hermes sessions list | tail -n +3 | head -1 | awk '{print $NF}')
```

**Wrong:** `grep -v "^Title"` — header says "Preview", not "Title".

## Config for Clean-Room Evaluation

```yaml
auxiliary:
  compression: null
  vision: null
  approval: null
  memory: null
  title_generation: null
  curator: null
  goal_judge: null
memory:
  provider: null
kanban:
  enabled: false
```

## Stock Skills vs Trimmed Skills

Test against **full stock skills** when evaluating skill-selection behavior. The model's ability to find the right skill among 90+ options is a meaningful signal. Trimming changes what you're measuring.

## Worked Example

See `groktopus/groktobench` for a complete implementation of all these patterns in a full evaluation pipeline.
