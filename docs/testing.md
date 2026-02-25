# Testing with Pathfinder

How to verify Pathfinder skills and expedition workflows.

## Unit Testing the Scripts

### verify-expedition.sh

Test with a mock expedition:

```bash
# Create a minimal .pathfinder structure
mkdir -p .pathfinder/tasks

# Create state.json
cat > .pathfinder/state.json << 'EOF'
{
  "version": "0.4.0",
  "expedition": "test",
  "branch": "feat/test",
  "currentPhase": "build",
  "phases": {
    "survey": {"status": "approved", "timestamp": "2026-01-01T00:00:00Z"},
    "plan": {"status": "approved", "timestamp": "2026-01-01T00:00:00Z"},
    "scout": {"status": "complete", "timestamp": "2026-01-01T00:00:00Z"},
    "build": {"status": "complete", "timestamp": "2026-01-01T00:00:00Z"},
    "report": {"status": "pending", "timestamp": null}
  },
  "checkpoints": {"total": 2, "planned": 0, "red": 0, "green": 2, "verified": 0}
}
EOF

# Create gate files
echo '{"status":"approved"}' > .pathfinder/survey.json
echo '{"status":"approved"}' > .pathfinder/plan.json
echo '{"status":"complete"}' > .pathfinder/scout.json
echo '{"status":"complete"}' > .pathfinder/build.json

# Create task files
cat > .pathfinder/tasks/FEAT-01.json << 'EOF'
{
  "id": "FEAT-01",
  "status": "green",
  "dependencies": [],
  "evidence": {"red": {"e2e": "FAIL"}, "green": {"e2e": "PASS", "fullSuite": "2 passed"}}
}
EOF

# Run verification
bash scripts/verify-expedition.sh
```

### pathfinder-check-deps.sh

```bash
# Task with no dependencies — should pass
bash scripts/pathfinder-check-deps.sh FEAT-01

# Task with unsatisfied dependency — should fail
cat > .pathfinder/tasks/FEAT-02.json << 'EOF'
{"id": "FEAT-02", "status": "red", "dependencies": ["FEAT-01"]}
EOF

# FEAT-01 is green, so FEAT-02 should be unblocked
bash scripts/pathfinder-check-deps.sh FEAT-02
```

### pathfinder-update-state.sh

```bash
# After modifying task files, verify state updates correctly
bash scripts/pathfinder-update-state.sh
cat .pathfinder/state.json
```

## Testing Git Hooks

### pre-push (block main)

```bash
# Install hooks
git config core.hooksPath .githooks

# On main — push should be blocked
git checkout main
git push  # ✘ Should fail

# On feature branch — push should work
git checkout -b feat/test
git push  # ✓ Should succeed
```

### pre-commit (phase ordering)

```bash
# During scout phase, source code changes should be blocked
# Set currentPhase to "scout" in state.json, then:
echo "test" > src/test.ts
git add src/test.ts
git commit -m "test"  # ✘ Should fail

# Test files should be allowed during scout
echo "test" > src/test.test.ts
git add src/test.test.ts
git commit -m "test"  # ✓ Should succeed
```

### post-commit (auto-update)

```bash
# After any commit, state.json checkpoint counts should auto-refresh
git commit --allow-empty -m "test"
cat .pathfinder/state.json  # Verify counts match task files
```

## End-to-End Workflow Test

Run a complete expedition to verify the full workflow:

1. **Survey:** Create state.json + survey.json on a feature branch
2. **Plan:** Create plan.json + task files
3. **Scout:** Write failing tests, update tasks to `red`
4. **Build:** Implement, update tasks to `green`
5. **Report:** Run verify-expedition.sh, check quality score

```bash
# Quick smoke test — create a minimal expedition and verify
git checkout -b feat/smoke-test
mkdir -p .pathfinder/tasks

# ... create state.json, gates, tasks ...

bash scripts/verify-expedition.sh
# Should output quality score
```

## Verifying Skill Content

Skills are markdown files — verify they have correct YAML frontmatter:

```bash
for skill in skills/*/SKILL.md; do
  name=$(python3 -c "
import re
content = open('$skill').read()
m = re.search(r'name:\s*(.+)', content)
print(m.group(1).strip() if m else 'MISSING')
")
  echo "$skill → $name"
done
```

Expected output:
```
skills/brainstorming/SKILL.md → brainstorming
skills/building/SKILL.md → building
skills/planning/SKILL.md → planning
skills/reporting/SKILL.md → reporting
skills/scouting/SKILL.md → scouting
skills/surveying/SKILL.md → surveying
skills/using-pathfinder/SKILL.md → using-pathfinder
...
```
