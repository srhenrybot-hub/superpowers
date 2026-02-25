---
name: reporting
description: "Use after building to independently verify all tests, compute quality score, and create PR — wraps verification-before-completion and finishing-a-development-branch."
---

# Reporting

*Verify the trail before declaring it open.*

## Overview

Reporting wraps `superpowers:verification-before-completion` and `superpowers:finishing-a-development-branch`. You independently re-run all tests, verify checkpoints, compute a quality score, and create a PR.

**Announce at start:** "I'm using the pathfinder:reporting skill to verify and finalize this expedition."

## Prerequisites

- `.pathfinder/state.json` exists with `phases.build.status === "complete"`
- All task files have `status: "green"`
- Build gate exists: `.pathfinder/build.json`

<HARD-GATE>
If build is not complete, REFUSE to report. Invoke pathfinder:building first.
No completion claims without fresh verification evidence.
</HARD-GATE>

## The Process

### Step 1: Independent Verification

Do NOT trust builder evidence. Re-run everything fresh:

```bash
# Run full test suite
npx playwright test --reporter=list 2>&1 | tee /tmp/pathfinder-verify.txt
npx vitest run 2>&1 | tee -a /tmp/pathfinder-verify.txt
```

### Step 2: Verify Each Checkpoint

For each task file with `status: "green"`:

```bash
npx playwright test --grep "FEAT-01" --reporter=list
npx vitest run --testNamePattern "FEAT-01"
```

If tests pass, update task to `verified`:

```python
import json, datetime
task = json.load(open('.pathfinder/tasks/FEAT-01.json'))
task['status'] = 'verified'
task['evidence']['verified'] = {
    'output': '<paste actual test output>',
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z'
}
json.dump(task, open('.pathfinder/tasks/FEAT-01.json', 'w'), indent=2)
```

If tests FAIL, update back to `red` and report the failure.

### Step 3: Run Quality Score

```bash
bash scripts/verify-expedition.sh
```

This computes a 0-100 quality score:

| Criterion | Points | Check |
|-----------|--------|-------|
| All checkpoint tests pass | 25 | Run test suite, 0 failures |
| Evidence complete | 20 | Every task has `evidence.green` filled |
| No regressions | 20 | Full suite passes (not just new tests) |
| Branch hygiene | 15 | On feature branch, not main/master |
| PR created | 10 | PR exists for this branch |
| All verified | 10 | Every task has `status: "verified"` |

**Thresholds:**
- 🟢 **90-100:** Excellent — merge-ready
- 🟡 **70-89:** Acceptable — review carefully
- 🔴 **Below 70:** Do not merge — fix issues first

### Step 4: Create Report Gate

The `verify-expedition.sh` script creates `.pathfinder/report.json` automatically. If running manually:

```python
import json, datetime
report = {
    'phase': 'report',
    'status': 'complete',
    'timestamp': datetime.datetime.utcnow().isoformat() + 'Z',
    'qualityScore': <score>,
    'breakdown': {
        'allTestsPass': {'score': <n>, 'max': 25},
        'evidenceComplete': {'score': <n>, 'max': 20},
        'noRegressions': {'score': <n>, 'max': 20},
        'branchHygiene': {'score': <n>, 'max': 15},
        'prCreated': {'score': <n>, 'max': 10},
        'allVerified': {'score': <n>, 'max': 10}
    },
    'pr': {'number': <n>, 'url': '<url>'}
}
json.dump(report, open('.pathfinder/report.json', 'w'), indent=2)
```

### Step 5: Create PR

Follow `superpowers:finishing-a-development-branch`:

```bash
git add .pathfinder/
git commit -m "Report: Expedition <name> complete (score: <N>/100)"

gh pr create \
  --title "feat: <expedition-name>" \
  --body "## Pathfinder Expedition Report

**Expedition:** <name>
**Quality Score:** <score>/100

### Checkpoints
| ID | Description | Status |
|----|-------------|--------|
| FEAT-01 | ... | ✅ verified |
| FEAT-02 | ... | ✅ verified |

### Quality Breakdown
- All tests pass: <n>/25
- Evidence complete: <n>/20
- No regressions: <n>/20
- Branch hygiene: <n>/15
- PR created: <n>/10
- All verified: <n>/10

### Test Results
\`\`\`
<paste full suite output>
\`\`\`
"
```

### Step 6: Update State

```python
import json
state = json.load(open('.pathfinder/state.json'))
state['currentPhase'] = 'report'
state['phases']['report'] = {'status': 'complete', 'timestamp': '<ISO-8601>'}
json.dump(state, open('.pathfinder/state.json', 'w'), indent=2)
```

### Step 7: Announce Completion

Present the quality score and PR link. If score is below 70, list what needs fixing.

## Cross-Agent Verification (Optional)

For higher confidence, dispatch a separate verifier subagent:

```
You are a VERIFIER for the Pathfinder expedition.

YOUR JOB: Independently run tests for checkpoints marked "green".
Do NOT trust the builder's evidence. Run the tests yourself.

For each .pathfinder/tasks/*.json where status is "green":
1. Run: npx playwright test --grep "<checkpoint-id>" --reporter=list
2. Run: npx vitest run --testNamePattern "<checkpoint-id>"
3. If BOTH pass: update status to "verified", fill evidence.verified
4. If EITHER fails: update status back to "red", note the failure

Do NOT modify any source code or test code. Only update task JSON files.
```

## Output

- `.pathfinder/report.json` — quality score and breakdown
- `.pathfinder/tasks/FEAT-XX.json` — all updated to `status: "verified"`
- Updated `.pathfinder/state.json` — report phase complete
- Pull request created with expedition report
