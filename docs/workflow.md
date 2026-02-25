# Expedition Workflow

A complete guide to running a Pathfinder expedition from start to finish.

## Quick Start

```
/survey  →  /scout  →  /build  →  /report
```

That's it. Each command triggers the corresponding Pathfinder skill.

## Phase 1: Survey (`/survey`)

**What happens:**
1. Agent reads project context (files, docs, recent commits)
2. Asks clarifying questions one at a time
3. Presents 2-3 design approaches with trade-offs
4. Gets your explicit approval

**What's created:**
- Feature branch (`feat/<expedition-name>`)
- `.pathfinder/state.json`
- `.pathfinder/survey.json`

**When it's done:** You've approved a design. The agent transitions to planning automatically.

## Phase 2: Plan (automatic after survey)

**What happens:**
1. Breaks approved design into bite-sized tasks
2. Assigns dependencies between tasks
3. Creates a Mermaid dependency graph
4. Saves human-readable plan to `docs/plans/`

**What's created:**
- `docs/plans/YYYY-MM-DD-<name>.md`
- `.pathfinder/plan.json`
- `.pathfinder/tasks/FEAT-XX.json` (one per checkpoint)

**When it's done:** All checkpoints are `planned`. Ready for scouting.

## Phase 3: Scout (`/scout`)

**What happens:**
1. For each checkpoint, writes failing e2e + unit tests
2. Runs each test to verify it fails correctly
3. Captures failure output as evidence in task files
4. Commits after each checkpoint's tests

**What's created:**
- Test files (e2e + unit per checkpoint)
- `.pathfinder/scout.json`
- Task files updated: `status: "planned"` → `"red"`

**Rules:**
- ❌ No implementation code during scouting
- ❌ Tests must fail because the feature doesn't exist (not because of typos)
- ✅ Both e2e and unit tests for each checkpoint
- ✅ Commit after each checkpoint

**When it's done:** All tests written and failing. Ready for building.

## Phase 4: Build (`/build`)

**What happens:**
1. For each checkpoint (in dependency order):
   - Checks dependencies are satisfied
   - Runs the failing test
   - Writes minimal code to make it pass
   - Runs full suite to check for regressions
   - Updates task file with evidence
   - Commits
2. For large expeditions, dispatches one subagent per checkpoint

**What's created:**
- Implementation code
- `.pathfinder/build.json`
- Task files updated: `status: "red"` → `"green"`

**Rules:**
- ❌ Cannot work on checkpoints with unsatisfied dependencies
- ❌ Cannot modify test files (unless fixing genuine test bugs)
- ✅ One checkpoint at a time
- ✅ Full suite after each checkpoint (catch regressions)

**When it's done:** All tests passing. Ready for reporting.

## Phase 5: Report (`/report`)

**What happens:**
1. Independently re-runs ALL tests (doesn't trust builder evidence)
2. Verifies each checkpoint individually
3. Computes quality score (0-100)
4. Creates PR with expedition report

**What's created:**
- `.pathfinder/report.json`
- Pull request with quality breakdown

**Quality score breakdown:**

| Criterion | Points |
|-----------|--------|
| All tests pass | 25 |
| Evidence complete | 20 |
| No regressions | 20 |
| Branch hygiene | 15 |
| PR created | 10 |
| All verified | 10 |

**Thresholds:**
- 🟢 **90-100:** Merge-ready
- 🟡 **70-89:** Review carefully
- 🔴 **Below 70:** Fix issues before merge

## Resuming an Expedition

If you start a new session mid-expedition, the agent reads `.pathfinder/state.json` and announces where you left off. Just say the next command:

```
# Agent: "Expedition 'weather-dashboard' is in build phase. 3/5 checkpoints cleared."
# You: /build
# Agent: Continues from FEAT-04
```

## Helper Commands

```bash
# Check current status
cat .pathfinder/state.json

# Check specific checkpoint
cat .pathfinder/tasks/FEAT-01.json

# Check if a checkpoint is unblocked
bash scripts/pathfinder-check-deps.sh FEAT-03

# Refresh state from task files
bash scripts/pathfinder-update-state.sh

# Run full verification + quality score
bash scripts/verify-expedition.sh
```

## Example: Weather Dashboard

```
/survey
# → Discusses requirements, proposes approaches
# → You approve: "Show current weather + 5-day forecast"

# → Planning auto-runs:
# WDASH-01: Dashboard loads and shows current temp
# WDASH-02: 5-day forecast cards
# WDASH-03: Error state when API fails
# WDASH-04: Loading skeleton
# Dependencies: WDASH-03 depends on WDASH-01, WDASH-04 depends on WDASH-01

/scout
# → Writes failing tests for all 4 checkpoints
# → Each test verified to fail correctly

/build
# → WDASH-01: implements current temp display (unblocked)
# → WDASH-02: implements forecast cards (unblocked)
# → WDASH-03: implements error handling (WDASH-01 is green ✓)
# → WDASH-04: implements loading skeleton (WDASH-01 is green ✓)

/report
# → Re-runs all tests independently
# → Quality score: 95/100
# → PR #42 created
```
