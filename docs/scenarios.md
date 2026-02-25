# Expedition Scenarios

How Pathfinder adapts to different project contexts.

## Greenfield Project (Building from Scratch)

Full expedition with heavy emphasis on survey. No existing code means every architectural decision happens upfront.

### Survey (Heavy)
- No existing context to read — agent asks more questions (5-10)
- Architecture decisions happen here: stack, patterns, data model
- Design approval locks in foundational choices that are expensive to change later

### Plan
- First checkpoints are foundational: project scaffold, core data types, basic rendering
- Dependencies flow vertically: setup → core → features → polish
- Example dependency chain:
  ```
  PROJ-01 (scaffold) → PROJ-02 (data model) → PROJ-03 (core UI)
                                              → PROJ-04 (API layer)
                        PROJ-02 + PROJ-04 → PROJ-05 (integration)
  ```

### Scout
- Tests define the contract before any code exists
- E2e tests describe what the user sees
- Unit tests describe how the internals behave
- The project's shape gets locked in at this phase

### Build
- Start from the bottom of the dependency tree
- After FEAT-01, the app does *something*
- After the last checkpoint, it does everything
- No regression risk (there's nothing to regress)

### Report
- PR is against an empty main
- Quality score should be 90+ since there's no legacy to fight

---

## New Feature in Existing Project

Most common case. The codebase already has conventions, patterns, and tests.

### Survey (Light)
- Agent reads existing code, tests, and docs first
- Questions focus on *how this feature fits*, not architecture
- "Should this follow the same pattern as the wells module?" not "What framework should we use?"
- Design approval is usually faster — conventions are established

### Plan
- Checkpoints integrate with existing structure
- Task files reference real paths: `src/features/reports/`, `e2e/reports.spec.ts`
- Dependencies might include existing code that needs modification
- Example:
  ```
  FEAT-01 (API endpoint) → FEAT-02 (UI component)
  FEAT-01 → FEAT-03 (error handling)
  FEAT-02 + FEAT-03 → FEAT-04 (integration test)
  ```

### Scout
- Tests are written alongside existing test suites
- Must verify existing tests still pass before marking scout complete
- Failure evidence must distinguish "feature doesn't exist yet" from "broke something"

### Build
- Full suite runs after every checkpoint — catches regressions immediately
- Dependency checker prevents building on broken foundations
- Follow existing code conventions (patterns, naming, file structure)

### Report
- PR diff is focused — only the new feature
- Quality score penalizes regressions (-20 pts for "no regressions")
- Reviewer sees exactly what changed and why

---

## Improving/Refactoring Existing Features

Trickiest case. You're changing behaviour that already works and has tests.

### Survey (Medium)
- Focus on *why* the current implementation is insufficient
- What's the problem? Performance? UX? Maintainability?
- Agent reads the existing feature code, its tests, and related issues/bugs
- Design approval means agreeing on what "better" looks like

### Plan
- Checkpoints are often *modifications* rather than additions
- "FEAT-01: Refactor connection query to use window function" not "FEAT-01: Create connection page"
- Dependencies map to refactoring order — change the API before updating its consumers
- Must document which existing tests will be modified vs which are new
- Example:
  ```
  REFAC-01 (extract shared util) → REFAC-02 (update module A)
                                  → REFAC-03 (update module B)
  REFAC-02 + REFAC-03 → REFAC-04 (remove old code)
  ```

### Scout
- **This is where it gets interesting**
- Some existing tests may need updating (behaviour is intentionally changing)
- New tests cover the improved behaviour
- Scout must clearly document:
  - "These 3 existing tests will be modified"
  - "These 5 tests are new"
  - "These 20 existing tests must still pass unchanged"
- Existing tests that should still pass MUST still pass

### Build
- **Highest regression risk** — every checkpoint runs the FULL suite
- If changing a shared utility, blast radius could be wide
- Dependency checker is critical: refactor the foundation before the layers above
- `builderNotes` should explain what changed and why

### Report
- "No regressions" criterion is hardest to hit (you're intentionally changing behaviour)
- PR description must explain what changed AND why the old way was wrong
- Quality score typically 70-90 due to complexity

---

## Comparison

| | Greenfield | New Feature | Improvement |
|---|---|---|---|
| **Survey weight** | Heavy (5-10 questions) | Light (2-3 questions) | Medium (3-5 questions) |
| **Test strategy** | All new | New + existing suite | Modify some + add new |
| **Regression risk** | None | Medium | High |
| **Dependency shape** | Vertical (setup→features) | Mixed | Refactoring order |
| **Typical score** | 90-100 | 80-95 | 70-90 |
| **Common pitfall** | Over-engineering survey | Ignoring conventions | Breaking existing tests |

## Tips by Scenario

### Greenfield
- Don't rush survey — bad foundations are expensive
- First checkpoint should be "app runs and shows something"
- Resist the urge to add features not in the plan (YAGNI)

### New Feature
- Read existing tests first — they document the conventions
- Match the existing code style exactly
- If the existing codebase has no tests, scouting creates the testing pattern for the whole project

### Improvement
- Before scouting, run the existing full suite and capture the baseline
- Tag existing tests that will change in the plan (so reviewers understand the intent)
- If the refactoring breaks >5 existing tests, consider splitting into smaller expeditions
