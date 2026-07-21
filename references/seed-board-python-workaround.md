# Seeding a SkillOpt Board with Python (Workaround for Complex Task Content)

Use this when `seed-board.sh` fails due to JSON injection issues with mixed-quote task content.

## Prerequisites

```bash
SKILL_NAME="<skill-name>"
SKILL_TARGET="$HOME/.hermes/skills/<category>/$SKILL_NAME/SKILL.md"
TRAIN_FILE="/tmp/${SKILL_NAME}-train.json"    # JSON array of training tasks
VAL_FILE="/tmp/${SKILL_NAME}-val.json"         # JSON array of validation tasks
SKILLOPT_DIR="$HOME/.hermes/SkillOpt/$SKILL_NAME"
```

## 1. Create state directory and copy baseline

```bash
mkdir -p "$SKILLOPT_DIR"/{rollouts,reflections,proposals,validation-results,snapshots}
cp "$SKILL_TARGET" "$SKILLOPT_DIR/snapshots/baseline-$(date +%Y%m%d-%H%M%S).md"
```

## 2. Write test suite JSON directly (Python, no shell injection)

```python
import json

with open('$TRAIN_FILE') as f:
    training = json.load(f)
with open('$VAL_FILE') as f:
    validation = json.load(f)

suite = {
    'training': training,
    'validation': validation,
    'created_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'skill_target': '$SKILL_TARGET'
}
with open('$SKILLOPT_DIR/test-suite.json', 'w') as f:
    json.dump(suite, f, indent=2)
print(f"Test suite: {len(training)} training, {len(validation)} validation")
```

## 3. Write board metadata

```python
import json
meta = {
    'target': '$SKILL_TARGET',
    'skill_name': '$SKILL_NAME',
    'board_slug': 'SkillOpt-$SKILL_NAME',
    'training_count': N_TRAIN,
    'validation_count': N_VAL,
    'edit_budget': 4,
    'epoch': 1,
    'created_at': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
    'baseline_snapshot': '$SNAPSHOT_FILE',
    'status': 'active'
}
with open('$SKILLOPT_DIR/board-metadata.json', 'w') as f:
    json.dump(meta, f, indent=2)
```

## 4. Create kanban board and tasks

```bash
# Create the board
hermes kanban boards create "SkillOpt-$SKILL_NAME" \
  --name "SkillOpt: $SKILL_NAME optimization" \
  --description "..."

# Switch to it
hermes kanban boards switch "SkillOpt-$SKILL_NAME"

# Create rollout tasks from training JSON. `--board` is global and must come before the subcommand.
# Use the explicit board on every create/list operation; do not rely on the active-board switch.
python3 -c "
import json, subprocess
with open('$SKILLOPT_DIR/test-suite.json') as f:
    suite = json.load(f)
for t in suite['training']:
    task_id = t['id']
    desc = t['instruction']
    body = f'''ROLLOUT TASK: {task_id} for $SKILL_NAME (epoch 1)
State: $SKILLOPT_DIR/rollouts/epoch-1-{task_id}.json
INSTRUCTION: {desc}
Execute the skill at $SKILL_TARGET against this task.'''
    subprocess.run(['hermes', 'kanban', '--board', 'skillopt-$SKILL_NAME', 'create', f'Rollout: {task_id}',
        '--body', body, '--priority', '3', '--created-by', 'skillopt'],
        check=True)
"

# Verify the tasks landed on the intended board before dispatching them.
hermes kanban --board "skillopt-$SKILL_NAME" list
hermes kanban boards list

# Create validation baseline task on the same explicit board.
hermes kanban --board "skillopt-$SKILL_NAME" create "Validation: establish baseline metrics" \
  --body "Run validation tasks and record baseline metrics" \
  --priority 1 --created-by "skillopt"
```

## 5. Switch back to default board

```bash
hermes kanban boards switch default 2>/dev/null || true
```
