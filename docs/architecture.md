# Architecture

## Overview

Pathfinder is a **layer on top of Superpowers**. It doesn't replace Superpowers' skill engine — it extends it with expedition-based TDD enforcement.

```
┌─────────────────────────────────────────┐
│         Pathfinder Layer                │
│  (phase gates, task files, quality)     │
├─────────────────────────────────────────┤
│         Superpowers Engine              │
│  (skill discovery, session hooks,       │
│   brainstorming, TDD, subagents, etc)   │
└─────────────────────────────────────────┘
```

## Directory Structure

```
pathfinder/
├── skills/
│   ├── using-pathfinder/    # Master skill (loaded on session start)
│   ├── surveying/           # Wraps brainstorming + expedition state
│   ├── planning/            # Wraps writing-plans + task files
│   ├── scouting/            # Wraps TDD RED phase + evidence capture
│   ├── building/            # Wraps subagent-driven-dev GREEN phase
│   ├── reporting/           # Wraps verification + quality score
│   │
│   │  # Inherited from Superpowers (the actual work):
│   ├── brainstorming/
│   ├── writing-plans/
│   ├── test-driven-development/
│   ├── subagent-driven-development/
│   ├── executing-plans/
│   ├── requesting-code-review/
│   ├── receiving-code-review/
│   ├── systematic-debugging/
│   ├── verification-before-completion/
│   ├── finishing-a-development-branch/
│   ├── using-git-worktrees/
│   ├── dispatching-parallel-agents/
│   └── writing-skills/
│
├── scripts/
│   ├── verify-expedition.sh          # Quality score computation
│   ├── pathfinder-check-deps.sh      # Dependency checker
│   └── pathfinder-update-state.sh    # Sync state.json from tasks
│
├── .githooks/
│   ├── pre-push       # Block push to main/master
│   ├── pre-commit     # Enforce phase ordering
│   └── post-commit    # Auto-update state.json
│
├── hooks/
│   ├── hooks.json     # Session hook config
│   └── session-start  # Bootstrap script (loads using-pathfinder)
│
├── lib/
│   └── skills-core.js # Skill discovery engine (from Superpowers)
│
└── templates/
    ├── state.json     # Expedition state template
    └── task.json      # Checkpoint task template
```

## Expedition State

When an expedition is active, the target project contains:

```
project/
├── .pathfinder/
│   ├── state.json          # Current phase + checkpoint counts
│   ├── survey.json         # Survey gate (design approved)
│   ├── plan.json           # Plan gate (tasks defined)
│   ├── scout.json          # Scout gate (all tests written)
│   ├── build.json          # Build gate (all tests passing)
│   ├── report.json         # Report gate (quality score + PR)
│   └── tasks/
│       ├── FEAT-01.json    # Individual checkpoint
│       ├── FEAT-02.json
│       └── ...
└── docs/
    └── plans/
        └── YYYY-MM-DD-expedition.md  # Human-readable plan
```

## Phase Flow

```
survey ──→ plan ──→ scout ──→ build ──→ report
  │          │        │         │         │
  │          │        │         │         ├─ verify-expedition.sh
  │          │        │         │         ├─ quality score 0-100
  │          │        │         │         └─ PR creation
  │          │        │         │
  │          │        │         ├─ dependency check per task
  │          │        │         ├─ one checkpoint at a time
  │          │        │         └─ task status: red → green
  │          │        │
  │          │        ├─ write failing tests
  │          │        ├─ capture failure evidence
  │          │        └─ task status: planned → red
  │          │
  │          ├─ create task JSON files
  │          ├─ define dependencies
  │          └─ Mermaid dependency graph
  │
  ├─ brainstorm design
  ├─ create feature branch
  └─ create state.json
```

## Enforcement Layers

### Layer 1: Git Hooks (machine-enforced)
- **pre-push:** Cannot push to main/master
- **pre-commit:** Cannot modify src/ during survey/plan/scout; gate files require predecessors

### Layer 2: State Files (structural)
- `state.json` tracks current phase
- Task files track dependencies — builder can't work on blocked checkpoints
- Gate files must exist before next phase starts

### Layer 3: Skill Instructions (agent-enforced)
- Each skill has `<HARD-GATE>` blocks that refuse to proceed without prerequisites
- Anti-rationalization tables prevent agents from skipping steps
- Evidence capture required — no claims without proof

## Task Lifecycle

```
planned ──→ red ──→ green ──→ verified
   │          │       │          │
   │          │       │          └─ Independent re-verification
   │          │       └─ Tests pass after implementation
   │          └─ Tests written and confirmed failing
   └─ Checkpoint defined in plan
```

## Quality Score

| Criterion | Points | Enforcement |
|-----------|--------|-------------|
| All tests pass | 25 | verify-expedition.sh runs test suite |
| Evidence complete | 20 | Checks task files for evidence.green |
| No regressions | 20 | Full suite, not just new tests |
| Branch hygiene | 15 | Reads state.json branch field |
| PR created | 10 | Queries gh CLI |
| All verified | 10 | Checks task status === verified |

Thresholds: 🟢 90+ merge-ready | 🟡 70-89 review carefully | 🔴 <70 fix first

## Design Decisions

### Why wrap Superpowers instead of building from scratch?
Superpowers has battle-tested skills for brainstorming, TDD, subagent dispatch, and code review. Reimplementing those would be wasted effort. Pathfinder adds the missing piece: structural enforcement that prevents agents from skipping steps.

### Why JSON task files instead of markdown?
Machine-readable. Git hooks and scripts can parse JSON reliably. Markdown parsing is fragile and ambiguous. The human-readable plan still exists in `docs/plans/`.

### Why python3 for JSON parsing in shell scripts?
Available on macOS and Linux by default. No jq dependency. Keeps the install footprint at zero.

### Why phase gates instead of just git hooks?
Hooks catch violations at commit/push time. Phase gates catch them at the moment the agent tries to do something wrong — earlier feedback, clearer error messages.
