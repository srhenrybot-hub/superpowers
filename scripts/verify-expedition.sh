#!/usr/bin/env bash
# Pathfinder v0.4.0 Expedition Verification & Quality Score
set -euo pipefail

SCORE=0
MAX_SCORE=100

echo "🔍 Pathfinder Expedition Verification (v0.4.0)"
echo "================================================"

# --- Check state.json exists ---
if [ ! -f .pathfinder/state.json ]; then
  echo "✘ No .pathfinder/state.json — not a Pathfinder expedition"
  exit 1
fi

BRANCH=$(python3 -c "import json; print(json.load(open('.pathfinder/state.json'))['branch'])")
EXPEDITION=$(python3 -c "import json; print(json.load(open('.pathfinder/state.json'))['expedition'])")
echo "Expedition: $EXPEDITION | Branch: $BRANCH"
echo ""

# --- 1. Gate files (prerequisite, no points) ---
echo "📋 Gate Files"
GATE_ERRORS=0
for gate in survey plan scout build; do
  file=".pathfinder/${gate}.json"
  if [ ! -f "$file" ]; then
    echo "  ✘ Missing: $file"
    GATE_ERRORS=$((GATE_ERRORS + 1))
  else
    status=$(python3 -c "import json; print(json.load(open('$file')).get('status','?'))")
    if [ "$status" = "approved" ] || [ "$status" = "complete" ]; then
      echo "  ✓ $file ($status)"
    else
      echo "  ✘ $file: status=$status (expected approved/complete)"
      GATE_ERRORS=$((GATE_ERRORS + 1))
    fi
  fi
done
echo ""

if [ "$GATE_ERRORS" -gt 0 ]; then
  echo "✘ Gate files incomplete. Cannot compute quality score."
  exit 1
fi

# --- 2. Task files: evidence check (20 pts) ---
echo "📋 Task Evidence"
TASK_COUNT=0
EVIDENCE_COUNT=0
VERIFIED_COUNT=0
for task_file in .pathfinder/tasks/*.json; do
  [ -f "$task_file" ] || continue
  TASK_COUNT=$((TASK_COUNT + 1))
  id=$(python3 -c "import json; print(json.load(open('$task_file'))['id'])")
  status=$(python3 -c "import json; print(json.load(open('$task_file'))['status'])")
  has_evidence=$(python3 -c "
import json
t = json.load(open('$task_file'))
print('yes' if t.get('evidence',{}).get('green') else 'no')
")
  if [ "$has_evidence" = "yes" ]; then
    EVIDENCE_COUNT=$((EVIDENCE_COUNT + 1))
    echo "  ✓ $id ($status) — evidence present"
  else
    echo "  ⚠ $id ($status) — NO evidence"
  fi
  if [ "$status" = "verified" ]; then
    VERIFIED_COUNT=$((VERIFIED_COUNT + 1))
  fi
done

if [ "$TASK_COUNT" -gt 0 ]; then
  EVIDENCE_SCORE=$((20 * EVIDENCE_COUNT / TASK_COUNT))
  VERIFIED_SCORE=$((10 * VERIFIED_COUNT / TASK_COUNT))
else
  EVIDENCE_SCORE=0
  VERIFIED_SCORE=0
fi
SCORE=$((SCORE + EVIDENCE_SCORE + VERIFIED_SCORE))
echo "  Evidence: $EVIDENCE_COUNT/$TASK_COUNT ($EVIDENCE_SCORE/20 pts)"
echo "  Verified: $VERIFIED_COUNT/$TASK_COUNT ($VERIFIED_SCORE/10 pts)"
echo ""

# --- 3. Run tests (25 pts for checkpoint tests, 20 pts for no regressions) ---
echo "📋 Test Suite"
TEST_SCORE=0
REGRESSION_SCORE=0
if npm run test:all > /tmp/pathfinder-test-output.txt 2>&1; then
  echo "  ✓ All tests pass"
  TEST_SCORE=25
  REGRESSION_SCORE=20
  TESTS_DETAIL=$(tail -5 /tmp/pathfinder-test-output.txt)
elif npm test > /tmp/pathfinder-test-output.txt 2>&1; then
  echo "  ✓ Tests pass (via npm test)"
  TEST_SCORE=25
  REGRESSION_SCORE=20
  TESTS_DETAIL=$(tail -5 /tmp/pathfinder-test-output.txt)
else
  echo "  ✘ Tests failed"
  TESTS_DETAIL=$(tail -10 /tmp/pathfinder-test-output.txt)
fi
SCORE=$((SCORE + TEST_SCORE + REGRESSION_SCORE))
echo "$TESTS_DETAIL" | sed 's/^/  /'
echo ""

# --- 4. Branch hygiene (15 pts) ---
echo "📋 Branch Hygiene"
BRANCH_SCORE=0
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
  echo "  ✓ On feature branch: $BRANCH"
  BRANCH_SCORE=15
else
  echo "  ✘ On $BRANCH — must use feature branch"
fi
SCORE=$((SCORE + BRANCH_SCORE))
echo ""

# --- 5. PR created (10 pts) ---
echo "📋 Pull Request"
PR_SCORE=0
PR_URL=$(gh pr list --head "$BRANCH" --json url --jq '.[0].url' 2>/dev/null || echo "")
if [ -n "$PR_URL" ]; then
  echo "  ✓ PR exists: $PR_URL"
  PR_SCORE=10
else
  echo "  ⚠ No PR found for branch $BRANCH"
fi
SCORE=$((SCORE + PR_SCORE))
echo ""

# --- 6. Security check ---
echo "📋 Security"
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
secrets=$(git diff --name-only "${DEFAULT_BRANCH}..HEAD" 2>/dev/null | grep -E '\.env$|\.env\.local|secrets|credentials' || true)
if [ -n "$secrets" ]; then
  echo "  ⚠ Potential secrets in diff: $secrets"
else
  echo "  ✓ No secret files in diff"
fi
echo ""

# --- Summary ---
echo "================================================"
echo "Quality Score: $SCORE / $MAX_SCORE"
if [ "$SCORE" -ge 90 ]; then
  echo "🟢 Excellent — merge-ready"
elif [ "$SCORE" -ge 70 ]; then
  echo "🟡 Acceptable — review carefully"
else
  echo "🔴 Below threshold — fix issues before merge"
fi

# --- Write report.json ---
TIMESTAMP=$(python3 -c "import datetime; print(datetime.datetime.utcnow().isoformat() + 'Z')")
python3 -c "
import json
report = {
    'phase': 'report',
    'status': 'complete',
    'timestamp': '$TIMESTAMP',
    'qualityScore': $SCORE,
    'breakdown': {
        'allTestsPass': {'score': $TEST_SCORE, 'max': 25},
        'evidenceComplete': {'score': $EVIDENCE_SCORE, 'max': 20},
        'noRegressions': {'score': $REGRESSION_SCORE, 'max': 20},
        'branchHygiene': {'score': $BRANCH_SCORE, 'max': 15},
        'prCreated': {'score': $PR_SCORE, 'max': 10},
        'allVerified': {'score': $VERIFIED_SCORE, 'max': 10}
    },
    'pr': {'url': '${PR_URL:-}' or None}
}
json.dump(report, open('.pathfinder/report.json', 'w'), indent=2)
"
echo ""
echo "Report saved to .pathfinder/report.json"

exit $((SCORE < 70 ? 1 : 0))
