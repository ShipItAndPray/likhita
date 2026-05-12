# Likhita UI Test Suite — Autoresearch Log

**Started:** 2026-05-12
**Variant:** karpathy (one change at a time, keep or discard, no overthinking)
**Target:** `ios/LikhitaRamaUITests/MandatoryReleaseGateTests.swift` (+ Ram mirror)
**Goal:** Maximize QA-SCENARIOS.md row coverage with every test green on a booted simulator.

## Eval criteria (binary)

| # | Eval | Pass condition |
|---|---|---|
| E1 | All current tests green | `xcodebuild test` exits 0; every method passes |
| E2 | Scenario 2.2 (Sangha persist across kill) covered | A real server count check before+after, asserting delta ≥ 1 |
| E3 | Test isolation: 2.2 passes when run in suite, not just isolation | After running 1.2, 2.1, 2.2, 3.2 in order, 2.2 still green |
| E4 | Both targets pass | LikhitaRamaUITests + LikhitaRamUITests both run green |
| E5 | Test uses production backend (not localhost) | `LIKHITA_API_BASE` env var injected before every launch |

## Experiments

### Experiment 0 — baseline (3/4 green)

- test_1_2 — pass
- test_2_1 — pass
- test_2_2 — **fail** (before=21 after=21, disk queue never drained)
- test_3_2 — pass

**Root cause analysis chain:**

1. Initially thought session-counter probe was false-positive — replaced predicate match with explicit `accessibilityIdentifier`. Still failed (`session=5` from stale disk queue).
2. Discovered `--reset-state` flag had no handler. Added `KotiStore.resetForUITesting()` that wipes UserDefaults keys + `Library/LikhitaSangha/`. Re-ran: `session=0` (typing didn't register).
3. Suspected SwiftUI `@FocusState` race with XCUITest `field.tap()`. Disabled auto-focus under `--ui-testing`. Re-ran: typing worked (session=1) but server count still flat.
4. Confirmed Vercel POST works manually with the device's own ID — `acceptedHere:1, currentCount:23`. So the backend accepts; the app isn't reaching it.
5. Read built Info.plist: `LikhitaAPIBase = http://localhost:3000`. Debug builds point at local dev server, which doesn't exist in CI/test runs.
6. Added env-var override `LIKHITA_API_BASE` in both AppConfig.swift files. Test sets it to `https://likhita-kappa.vercel.app`.

### Experiment 1 — KEEP (test_2_2 green)

**Change:** Bundle of related fixes:
- AppConfig (both apps): read `LIKHITA_API_BASE` env first, fall back to Info.plist
- Test injects `LIKHITA_API_BASE = https://likhita-kappa.vercel.app` before every `app.launch()`
- Added `--simulate-mantras=N` launch arg to bypass XCUITest typeText flakiness
- Added `--reset-state` actual handler via `KotiStore.resetForUITesting()`
- Added test-only hidden probe (`Text("session=\(N)").accessibilityIdentifier("ui-test-session-count")`) for deterministic state checks
- Disabled SwiftUI auto-focus when `--ui-testing` (FocusState races XCUITest's manual tap)
- Second-launch path drops `--reset-state` so the disk queue we just persisted isn't wiped before flush

**Reasoning:** The original failure was multi-layered. Test isolation, XCUITest mechanics, and Debug build pointing at localhost all conspired to mask the real product fix (snake_case → camelCase already shipped in `9b777f6`).

**Result:** `test_2_2_sangha_commit_persists_across_immediate_kill` passes in 26.7s. before=22, after=23, delta=1.

## Open scenarios (next experiments)

QA-SCENARIOS rows not yet covered by an XCUITest:
- 1.3 — rapid commit + kill (the original bug from 2026-05-11) — would need to deterministically simulate 3 mantras fast
- 1.5 — resume mid-session across cold launches
- 3.3 — Past Kotis hidden when empty
- 4.1 — offline queue persists (would need network toggle)
- 4.2 — server 5xx retry behavior
- 4.3 — 429 rate limit toast

Each of those should be added as a separate experiment with binary pass conditions. Currently scope is constrained to the release-gate set.

## What this run validated

- The `9b777f6` snake_case fix actually works in production — server count moves on every queue flush.
- The test infrastructure is now strong enough to catch a regression on this exact scenario, which was the entire point of §25.
