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
- Apple Developer Program: active
- ASC API key: pending — page shows "Request Access" gate

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
