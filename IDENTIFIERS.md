# Likhita — Apple identifiers (autonomous setup)

Created on 2026-05-06 via persistent-Chrome CDP automation. Both bundle IDs registered at developer.apple.com, both apps created in App Store Connect.

## Bundle IDs

| App | Bundle ID | Status |
|---|---|---|
| Likhita Rama (Telugu) | `org.likhita.rama` | ✅ Registered |
| Likhita Ram (Hindi) | `org.likhita.ram` | ✅ Registered |

## App Store Connect app records

| App | APP_ID | URL |
|---|---|---|
| Likhita Rama | **`6766999832`** | https://appstoreconnect.apple.com/apps/6766999832 |
| Likhita Ram | **`6766999936`** | https://appstoreconnect.apple.com/apps/6766999936 |

## Apple team

- Team ID: `WS486NY2HV` (cached in user memory)
- Team UUID (ASC URL): `264e0e07-1489-4723-867d-f4c65a5e5bc2`
- Apple Developer Program: active
- ASC API key: pending — page shows "Request Access" gate (workaround: drive web UI via persistent Chrome CDP)

## Xcode Cloud workflows (created 2026-05-06)

| App | Workflow | Branch (start condition) | Status |
|---|---|---|---|
| Likhita Rama (`6766999832`) | "Default" | `release` | ✅ Distribution Preparation = TestFlight Internal Only |
| Likhita Ram (`6766999936`) | "Default" | `release` | ✅ Distribution Preparation = TestFlight Internal Only |

**Rule:** only `release` branch pushes trigger Cloud builds. `main` is for development; merge to `release` only when you want a TestFlight build. See SKILL.md §6 for rationale.

To trigger a build: `git push origin release`.

## TestFlight Internal Testing (auto-invite, set up 2026-05-06)

Both apps have an Internal Testing group named **"Self"** with **auto-distribution enabled** and the account holder as the only tester.

| App | Group ID | Auto-distribute | Testers |
|---|---|---|---|
| Likhita Rama (`6766999832`) | `dbfdd59c-3fb0-46dc-aeff-c134b8a8ef8e` | ✅ | 1 (account holder) |
| Likhita Ram (`6766999936`)  | `11ed1571-9258-4da0-ac09-008eb96a2296` | ✅ | 1 (account holder) |

When a Cloud build finishes processing in ASC, it auto-attaches to both groups → TestFlight push notification fires on the user's iPhone — no manual click per build, ever.

Reusable script: `~/.claude/skills/ios-deployment/templates/asc-tf-internal.mjs`

## Capabilities (none yet)

Both bundle IDs registered without capabilities. Add later via developer.apple.com → identifier → Edit → tick Push Notifications, Sign in with Apple, etc.

## Next autonomous steps

1. Open Xcode once → Integrate menu → Create Workflow → bind GitHub OAuth (one-time gate per skill §6)
2. Push to `release` branch → Cloud build for both targets in parallel → uploads to TestFlight
3. Internal Testing groups via ASC web UI (Internal doesn't need Beta Review)
4. Add testers, install via TestFlight on iPhone

## Scripts that did this work

- `~/.claude-playwright/runtime/asc-register-bundle.mjs` — bundle ID registration via wizard
- `~/.claude-playwright/runtime/asc-create-app.mjs` — app record creation via New App modal
- `~/.claude-playwright/runtime/list-apps.mjs` — list ASC apps

Reusable for any future iOS app — change args.
