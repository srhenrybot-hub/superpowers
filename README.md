# Pathfinder

*Marks the trail before others follow.*

An expedition-based TDD workflow for AI coding agents, built on top of [Superpowers](https://github.com/obra/superpowers).

Pathfinder layers **phase enforcement, task tracking, and quality scoring** on top of Superpowers' composable skill engine. Scouts write failing tests, Builders implement, and git hooks ensure nobody skips steps.

## How It Works

```
/survey  →  /scout  →  /build  →  /report
   │           │          │          │
brainstorm   write      implement   verify
+ design     failing    minimal     + quality
approval     tests      code        score + PR
```

### Phase Gates (Enforced)

| Phase | What happens | Gate file |
|-------|-------------|-----------|
| **Survey** | Understand problem, explore approaches, get design approval | `survey.json` |
| **Plan** | Break design into bite-sized tasks with dependencies | `plan.json` + `tasks/*.json` |
| **Scout** | Write ALL failing tests (TDD RED phase) | `scout.json` |
| **Build** | Implement minimal code to pass tests (TDD GREEN phase) | `build.json` |
| **Report** | Verify independently, compute quality score, create PR | `report.json` |

**You cannot skip phases.** Git hooks enforce this:
- No source code during survey/plan/scout
- No build gate without scout gate
- No push to main (feature branches only)

### Task-Level Tracking

Each checkpoint is a JSON file in `.pathfinder/tasks/`:

```json
{
  "id": "FEAT-01",
  "status": "green",
  "dependencies": ["FEAT-00"],
  "evidence": {
    "red": { "e2e": "FAIL ...", "timestamp": "..." },
    "green": { "e2e": "PASS ...", "fullSuite": "42 passed, 0 failed", "timestamp": "..." }
  }
}
```

Status lifecycle: `planned` → `red` → `green` → `verified`

### Quality Score (0-100)

| Criterion | Points |
|-----------|--------|
| All tests pass | 25 |
| Evidence complete | 20 |
| No regressions | 20 |
| Branch hygiene | 15 |
| PR created | 10 |
| All verified | 10 |

🟢 90-100: Merge-ready | 🟡 70-89: Review carefully | 🔴 <70: Fix first

## Built on Superpowers

Pathfinder keeps ALL of Superpowers' skills and adds expedition structure:

| Pathfinder Skill | Wraps Superpowers Skill |
|-----------------|------------------------|
| `pathfinder:surveying` | `superpowers:brainstorming` |
| `pathfinder:planning` | `superpowers:writing-plans` |
| `pathfinder:scouting` | `superpowers:test-driven-development` |
| `pathfinder:building` | `superpowers:subagent-driven-development` |
| `pathfinder:reporting` | `superpowers:verification-before-completion` + `superpowers:finishing-a-development-branch` |

All Superpowers skills remain available: systematic-debugging, code-review, git-worktrees, parallel-agents, etc.

## Installation

### Claude Code (via Plugin)

```bash
# Register marketplace (if not already)
/plugin marketplace add obra/superpowers-marketplace

# Install Pathfinder
/plugin install pathfinder
```

### Manual (any agent)

```bash
git clone https://github.com/srhenrybot-hub/superpowers.git ~/.pathfinder
cd your-project
git config core.hooksPath ~/.pathfinder/.githooks
```

### OpenClaw

Symlink to skills directory:
```bash
ln -s /path/to/pathfinder ~/.npm-global/lib/node_modules/openclaw/skills/pathfinder
```

## Quick Reference

```bash
# Start expedition
/survey

# Write failing tests
/scout

# Implement
/build

# Verify + PR
/report

# Check expedition status
cat .pathfinder/state.json

# Check dependencies
bash scripts/pathfinder-check-deps.sh FEAT-01

# Run quality verification
bash scripts/verify-expedition.sh
```

## Documentation

- **[Workflow Guide](docs/workflow.md)** — Complete expedition walkthrough with examples
- **[Scenarios](docs/scenarios.md)** — Greenfield, new features, and refactoring
- **[Test Runners](docs/test-runners.md)** — Playwright, Maestro, Cypress, pytest, and more
- **[Architecture](docs/architecture.md)** — How Pathfinder layers on Superpowers
- **[Installation](docs/installation.md)** — Setup for Claude Code, OpenClaw, or any project
- **[Testing](docs/testing.md)** — How to test scripts, hooks, and skills

## Credits

- [Superpowers](https://github.com/obra/superpowers) by Jesse Vincent — the skill engine and workflow foundation
- Expedition metaphor and enforcement layer by [srpadrono](https://github.com/srpadrono)

## License

MIT
