#!/usr/bin/env bash
# Pathfinder: Check if a checkpoint's dependencies are satisfied
# Usage: pathfinder-check-deps.sh FEAT-01
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: pathfinder-check-deps.sh <CHECKPOINT-ID>"
  exit 1
fi

TASK_ID=$1
TASK_FILE=".pathfinder/tasks/${TASK_ID}.json"

if [ ! -f "$TASK_FILE" ]; then
  echo "✘ Task file not found: $TASK_FILE"
  exit 1
fi

python3 -c "
import json, sys

task = json.load(open('$TASK_FILE'))
deps = task.get('dependencies', [])

if not deps:
    print(f'✓ {task[\"id\"]} has no dependencies — unblocked')
    sys.exit(0)

blocked = []
for dep in deps:
    dep_file = f'.pathfinder/tasks/{dep}.json'
    try:
        dep_task = json.load(open(dep_file))
        if dep_task['status'] not in ('green', 'verified'):
            blocked.append(f'{dep} (status: {dep_task[\"status\"]})')
    except FileNotFoundError:
        blocked.append(f'{dep} (file missing)')

if blocked:
    print(f'✘ Blocked: {task[\"id\"]} depends on:')
    for b in blocked:
        print(f'  - {b}')
    sys.exit(1)
else:
    print(f'✓ {task[\"id\"]} is unblocked — all dependencies satisfied')
    sys.exit(0)
"
