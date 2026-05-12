# Likhita QA — Test Scenarios

Every scenario here must pass on a real iPhone over real network before
any App Store submission. **Backend tests + static screen renders are
not sufficient.** This document was written after a bug shipped (1.0.10):
the user typed 3 mantras into The Sangha, count went 18→21 in UI, app
restart showed 18. Root cause: in-memory buffer + 800ms flush debounce
meant any mantras typed within 800ms of app kill were lost. Static
rendering tests didn't catch this; only "type → kill → reopen" would.

Format per scenario:
  - **Pre-state** — what the world looks like before
  - **Steps** — exact user actions
  - **Expected** — what should happen
  - **Verifies** — which feature this proves

When a scenario fails, leave it red here with the date + a note. Only
ship when every scenario in §1–§4 is green.

---

## §1 — Personal Koti (My Book) persistence

### 1.1 First-launch onboarding completes
- **Pre-state**: app installed fresh, no koti pinned in `KotiStore`.
- **Steps**:
  1. Open app → Threshold
  2. Tap "My Book" → Welcome → Begin a sankalpam
  3. Fill name "Test", continue through identity / dedication / stylus / theme
  4. Hold to begin on Pledge for 2s
- **Expected**: lands on Writing surface with `0 / <target>`. Server-side a row exists in `likhita.kotis` with the chosen target.
- **Verifies**: F3 (POST /v1/kotis), Sankalpam state machine

### 1.2 Mantra commit persists to server
- **Pre-state**: Writing surface, count 0.
- **Steps**:
  1. Type `srirama` (Rama app) or `ram` (Ram app) once. Watch counter tick to 1.
  2. Wait 3 seconds (>800ms flush debounce).
  3. Force-quit app (swipe up).
  4. Reopen app.
- **Expected**: count should be **1** when app reopens. NOT 0.
- **Verifies**: F4, F5 — server-confirmed POST + resume flow

### 1.3 ⚠️ Type-then-kill within debounce window — the bug from 2026-05-11
- **Pre-state**: Writing surface, count N.
- **Steps**:
  1. Type 3 mantras in rapid succession.
  2. **Within 1 second** of last commit, force-quit app.
  3. Reopen app.
- **Expected**: count should be **N+3**, not N. Server-side `entries` table has 3 new rows.
- **Verifies**: persistence resilience against rapid kill. **THIS SCENARIO REGRESSED 2026-05-11 (1.0.10).** Fix: flush more aggressively on commit + persist buffer to disk so it survives process death.

### 1.4 Anti-cheat blocks hold-key
- **Pre-state**: Writing surface, focus the input.
- **Steps**:
  1. Hold the `s` key down. iOS auto-repeat fires `s`'s quickly.
  2. Eventually the buffer attempts to flush.
- **Expected**: the batch is rejected by anti-cheat. Count does not advance. UI may show "Slow down. This is sadhana, not a race." toast.
- **Verifies**: F8

### 1.5 Resume mid-session across cold launches
- **Pre-state**: count = 50 of 1,008 (Nitya mode).
- **Steps**:
  1. Force-quit app.
  2. Reopen after 5 minutes.
- **Expected**: lands DIRECTLY on Writing surface (skip threshold + welcome), count = 50 from server.
- **Verifies**: KotiStore.activeKotiId pinning + viewModel.resumeIfPossible()

### 1.6 Completion auto-routes
- **Pre-state**: count = target - 1 (e.g. 107/108 for Japa).
- **Steps**:
  1. Type the final mantra.
- **Expected**: count = 108. App auto-routes to Completion screen (Pattabhishekam). NOT user-tappable; only server-confirmed final count triggers.
- **Verifies**: §10 ceiling logic + completion route

---

## §2 — The Sangha (Shared Koti) persistence

### 2.1 Sangha hub fetches live count on entry
- **Pre-state**: Server `shared_kotis.current_count = X`.
- **Steps**:
  1. Threshold → tap Sangha card.
- **Expected**: Hub screen shows `X` (NOT `7,842,316` — the old static fallback). Loading state visible briefly while fetch resolves.
- **Verifies**: F9 — live GET /v1/shared/koti

### 2.2 ⚠️ Sangha mantra commits persist — the 2026-05-11 bug
- **Pre-state**: Hub shows count = 18.
- **Steps**:
  1. Tap "Add your hand to the koti" → SharedWriting.
  2. Type `srirama` 3 times. UI shows 18 → 19 → 20 → 21.
  3. Tap back to Hub. Tap back to Threshold.
  4. **Force-quit app immediately.**
  5. Reopen app, navigate back to Hub.
- **Expected**: count = **21**. Server has 3 new rows in `likhita.shared_entries` for this `deviceId`.
- **Actual on 2026-05-11**: count reverted to 18. Server had 0 new rows. **REGRESSED.** Fix: aggressive flush + buffer persistence.
- **Verifies**: F10 — POST /v1/shared/entries

### 2.3 Sangha live count auto-refreshes
- **Pre-state**: Sangha Hub open, count showing X.
- **Steps**:
  1. Have another user (different device) write entries against the same `/shared/entries` endpoint.
  2. Wait 4-8s without touching the screen.
- **Expected**: count refreshes to X+N from the poll. Ticker shows the new writer's name + place + age.
- **Verifies**: SharedKotiViewModel.startPolling()

### 2.4 Sangha anti-cheat
- **Pre-state**: SharedWriting open.
- **Steps**:
  1. Open Safari, send a curl with zero-variance gaps from your device ID — OR — use the iOS app's hold-key to fire auto-repeat.
- **Expected**: that batch is 422'd. No new rows in DB.
- **Verifies**: F12

### 2.5 Sangha works without a personal koti
- **Pre-state**: brand new install, no sankalpam taken.
- **Steps**:
  1. Threshold → tap The Sangha (skip My Book entirely).
  2. Add hand. Type a few mantras.
- **Expected**: Sangha writes succeed. User can use The Sangha without ever starting a personal koti.
- **Verifies**: independence of /shared/* endpoints from /kotis ownership

### 2.6 Sangha 1-crore ceiling cap
- **Pre-state**: server `current_count = target_count - 2` (i.e. 9,999,998).
- **Steps**:
  1. POST a batch of 5 entries.
- **Expected**: `acceptedHere = 2`, `currentCount = 10,000,000`, `complete = true`. Next POST returns 410 `koti_complete`. UI shows ceiling reached + disables input.
- **Verifies**: atomic LEAST() cap in `appendSharedEntries`

---

## §3 — Cross-screen flows + UI invariants

### 3.1 Threshold pill returns from Writing
- **Pre-state**: Writing surface.
- **Steps**: Tap "⌂ THRESHOLD" pill top-left.
- **Expected**: returns to Threshold. Personal koti progress preserved.

### 3.2 Designer Jump is NOT visible in TestFlight builds
- **Pre-state**: installed via TestFlight (Release config).
- **Steps**: Navigate to Settings.
- **Expected**: Sections shown: ACTIVE KOTI (if any), FOUNDATION. **NO** "DESIGNER JUMP" section.
- **Verifies**: §23.6a #if DEBUG gate

### 3.3 Past Kotis hidden when empty
- **Pre-state**: fresh install, no completed kotis.
- **Steps**: Settings.
- **Expected**: No "PAST KOTIS" section. (It returns when the user completes one and the row gets written.)

### 3.4 Settings shows Mammu credit
- **Pre-state**: Settings open.
- **Steps**: Scroll to FOUNDATION card.
- **Expected**: last row reads `Sangha by` (label) → `Mammu Inc.` (value).

### 3.5 Home Screen names are distinguishable
- **Pre-state**: both Likhita Rama AND Likhita Ram installed.
- **Steps**: Look at Home Screen.
- **Expected**: One reads "Likhita రామ" (Telugu glyph), the other "Likhita राम" (Devanagari glyph). Not both as "Likhita Rama"/"Likhita Ram" in identical Roman type.
- **Verifies**: CFBundleDisplayName differentiation

### 3.6 Native script renders correctly on Home Screen
- **Pre-state**: app on Home Screen.
- **Steps**: Glance at icon + label.
- **Expected**: Telugu/Devanagari glyphs render properly (no `□` boxes, no fallback ASCII).
- **Verifies**: iOS system fonts handle the scripts.

---

## §4 — Network failure + offline scenarios

### 4.1 Offline mantra commit
- **Pre-state**: Writing, airplane mode ON.
- **Steps**:
  1. Type 5 mantras.
  2. UI counter ticks up.
  3. Turn airplane mode OFF after 1 minute.
- **Expected**: queued mantras eventually flush. Server count catches up. UI shows server-confirmed value.
- **Verifies**: buffer survives transient network failures.

### 4.2 Server 5xx error during flush
- **Pre-state**: Writing, contrived backend outage.
- **Steps**:
  1. Type mantras while backend is returning 500.
  2. Restore backend.
- **Expected**: client retries on next flush cycle. Items not lost.

### 4.3 Rate limit (429) handling
- **Pre-state**: Sangha Writing.
- **Steps**: User somehow types faster than 4/sec (only possible via paste — which is blocked, but in principle).
- **Expected**: 429 surfaces a polite toast "Slow down. This is sadhana, not a race." App doesn't error out.

---

## §5 — Real-device-only checks (cannot be tested on Simulator)

### 5.1 TestFlight install + first cold launch
- Open TestFlight on iPhone → tap Install → tap to open.
- **Expected**: no crash, lands on Threshold within 3 seconds.

### 5.2 Background → foreground transition
- App active → home button → wait 30 min → resume.
- **Expected**: state preserved, Sangha hub refreshes count when foregrounded.

### 5.3 Push notification on Sangha milestone (future)
- Currently unimplemented. When wired: assert receive when a major milestone (e.g. 50 lakh) is crossed.

### 5.4 Real handwriting calibration
- Sankalpam stylus step on a real iPhone — trace `శ్రీరామ` with finger 3 times.
- **Expected**: 3 strokes capture cleanly. Calibration unlocks Continue button.

### 5.5 Dynamic Type / accessibility
- Settings → Accessibility → Larger Text → max size.
- **Expected**: app screens reflow, no truncation that hides critical controls.

---

## §6 — Pre-submission acceptance

Before pressing "Submit for App Review", every row above must be green
on a real iPhone for both Likhita Rama AND Likhita Ram. Date the last
full pass below. Submit only if ≤7 days old.

| Pass # | Date | Device | iOS version | Tester | Notes |
|---|---|---|---|---|---|
| — | — | — | — | — | — |

---

## §7 — What I deliberately did NOT test before — and the lessons

These are gaps I owned but didn't close before declaring "feature pass":

1. **Real-device install of any build** — only simulator. The 1.0.10 Sangha bug surfaced on the iPhone, would not have surfaced on the sim because I never tapped through the actual flow. → from now on, every scenario in §5 must be checked on TestFlight before declaring ready.
2. **Process-kill resilience** — I tested resume after the buffer had flushed, never within the debounce window. → Scenario 1.3 and 2.2 added.
3. **Latency under cellular/Wi-Fi** — I tested over wired LAN to localhost during dev and `likhita-kappa.vercel.app` (fast Vercel edge). Real-device cellular round trips can be 500-2000ms; buffer/flush logic must tolerate that.
4. **Backgrounded app** — never tested the "task fires while app is suspended". iOS aggressively suspends; my Task-based flush probably gets paused on background and resumed on foreground, with all kinds of edge cases.
5. **Concurrent users on Sangha** — only tested single-device writes. The atomic CAS is correct on paper, but race tests with N>10 concurrent writers haven't been run.
