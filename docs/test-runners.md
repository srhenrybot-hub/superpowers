# Supported Test Runners

Pathfinder is test-framework agnostic. Configure which runners to use in `state.json`:

```json
{
  "testRunners": {
    "e2e": "playwright",
    "unit": "vitest"
  }
}
```

Skills read `testRunners` to determine which commands to use. If not specified, defaults to `playwright` + `vitest`.

## E2E Runners

### Playwright (Web)
```json
{ "e2e": "playwright" }
```
| Action | Command |
|--------|---------|
| Run all | `npx playwright test` |
| Run one | `npx playwright test --grep "FEAT-01"` |
| Debug | `npx playwright test --grep "FEAT-01" --debug` |
| Report | `npx playwright show-report` |
| Codegen | `npx playwright codegen` |

**Best for:** Next.js, React, Vue, any web app.

### Maestro (Mobile)
```json
{ "e2e": "maestro" }
```
| Action | Command |
|--------|---------|
| Run all | `maestro test e2e/flows/` |
| Run one | `maestro test e2e/flows/feat-01.yaml` |
| Record | `maestro record` |
| Studio | `maestro studio` |

**Best for:** React Native, Expo, Flutter, native iOS/Android.
**Note:** Requires a running simulator/emulator or connected device.

### XCUITest (iOS Native)
```json
{ "e2e": "xcuitest" }
```
| Action | Command |
|--------|---------|
| Run all | `xcodebuild test -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Run one | `xcodebuild test -scheme App -only-testing:AppUITests/FEAT01` |

**Best for:** Native Swift/SwiftUI apps.
**Note:** Requires Xcode + simulator.

### Espresso (Android Native)
```json
{ "e2e": "espresso" }
```
| Action | Command |
|--------|---------|
| Run all | `./gradlew connectedAndroidTest` |
| Run one | `./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.app.FEAT01Test` |

**Best for:** Native Kotlin/Java Android apps.
**Note:** Requires Android emulator or connected device.

### Cypress (Web)
```json
{ "e2e": "cypress" }
```
| Action | Command |
|--------|---------|
| Run all | `npx cypress run` |
| Run one | `npx cypress run --spec "cypress/e2e/feat-01.cy.ts"` |
| Open UI | `npx cypress open` |

**Best for:** Web apps preferring Cypress over Playwright.

### Detox (React Native)
```json
{ "e2e": "detox" }
```
| Action | Command |
|--------|---------|
| Build | `npx detox build --configuration ios.sim.debug` |
| Run all | `npx detox test --configuration ios.sim.debug` |
| Run one | `npx detox test --configuration ios.sim.debug e2e/feat-01.test.ts` |

**Best for:** React Native apps preferring Detox over Maestro.

## Unit Test Runners

### Vitest (JS/TS)
```json
{ "unit": "vitest" }
```
| Action | Command |
|--------|---------|
| Run all | `npx vitest run` |
| Run one | `npx vitest run --testNamePattern "FEAT-01"` |
| Watch | `npx vitest` |
| Coverage | `npx vitest run --coverage` |

### Jest (JS/TS)
```json
{ "unit": "jest" }
```
| Action | Command |
|--------|---------|
| Run all | `npx jest` |
| Run one | `npx jest --testNamePattern "FEAT-01"` |
| Watch | `npx jest --watch` |
| Coverage | `npx jest --coverage` |

### pytest (Python)
```json
{ "unit": "pytest" }
```
| Action | Command |
|--------|---------|
| Run all | `pytest` |
| Run one | `pytest -k "FEAT_01"` |
| Verbose | `pytest -v` |
| Coverage | `pytest --cov` |

### Go test
```json
{ "unit": "gotest" }
```
| Action | Command |
|--------|---------|
| Run all | `go test ./...` |
| Run one | `go test -run "FEAT01" ./...` |
| Verbose | `go test -v ./...` |
| Coverage | `go test -cover ./...` |

### Swift Testing / XCTest
```json
{ "unit": "xctest" }
```
| Action | Command |
|--------|---------|
| Run all | `swift test` or `xcodebuild test -scheme App` |
| Run one | `swift test --filter "FEAT01"` |

## Common Configurations

### Next.js Web App
```json
{ "e2e": "playwright", "unit": "vitest" }
```

### React Native (Expo)
```json
{ "e2e": "maestro", "unit": "jest" }
```

### FastAPI Backend
```json
{ "e2e": "pytest", "unit": "pytest" }
```

### Native iOS
```json
{ "e2e": "xcuitest", "unit": "xctest" }
```

### Native Android
```json
{ "e2e": "espresso", "unit": "gotest" }
```

### Full-Stack (Web + API)
```json
{ "e2e": "playwright", "unit": "vitest", "api": "pytest" }
```

## Auto-Detection

During survey, the agent should detect the project type and suggest runners:

| File found | Suggested e2e | Suggested unit |
|------------|--------------|----------------|
| `playwright.config.ts` | playwright | — |
| `e2e/.maestro/config.yaml` | maestro | — |
| `cypress.config.ts` | cypress | — |
| `.detoxrc.js` | detox | — |
| `vitest.config.ts` | — | vitest |
| `jest.config.*` | — | jest |
| `pytest.ini` / `pyproject.toml` | — | pytest |
| `go.mod` | — | gotest |
| `Package.swift` | — | xctest |
| `*.xcodeproj` + `*UITests` | xcuitest | xctest |
| `build.gradle` + `androidTest` | espresso | — |
