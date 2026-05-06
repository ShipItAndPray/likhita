# Likhita

Two iOS apps + one shared backend, run as a non-profit foundation.

A digital reimagining of *likhita japa* — the ancient practice of writing Rama's name 1 lakh / 1 crore times. Completed work is professionally printed as a cloth-bound book and physically deposited at temples (Bhadrachalam for Telugu users, Ram Naam Bank Varanasi for Hindi users). Photo + temple-stamped receipt mailed back as proof.

> *"Only if the practice is real. So we built Likhita Rama around it."*

## Live

| | URL |
|---|---|
| Foundation site | https://likhita-kappa.vercel.app/ |
| Transparency portal | https://likhita-kappa.vercel.app/transparency |
| Privacy | https://likhita-kappa.vercel.app/privacy |

## The two apps

| | Likhita Rama (Telugu) | Likhita Ram (Hindi) |
|---|---|---|
| Practice | Rama Koti — `శ్రీరామ` | Ram Naam Lekhan — `राम` / `सीताराम` |
| Audience | Telugu / South Indian Hindu diaspora | Hindi / North Indian Hindu diaspora |
| Bundle ID | `org.likhita.rama` | `org.likhita.ram` |
| Temple | Sri Sita Ramachandra Swamy Temple, Bhadrachalam | Ram Naam Bank, Varanasi (or Ayodhya) |
| Default theme | Bhadrachalam Classic | Banaras Pothi |

## Repository layout

```
likhita/
├── SPEC.md                product spec (1531 lines, 26 sections)
├── BLOCKERS.md            human-only steps (legal, temple validation, domains)
├── IDENTIFIERS.md         Apple bundle IDs + APP_IDs
├── autoresearch/          differentiation copy (10/10 evals — pledge, ASC, hero)
├── backend/               Next.js 16 + Vercel + Neon + Drizzle + Clerk
└── ios/                   xcodegen — one project, two SwiftUI targets, four Swift packages
```

## Foundation

**Likhita Foundation** — Section 8 Co. (India, in progress) + 501(c)(3) (US, in progress). Cost-recovery pricing only, audited annually. No ads. No data sales. No engagement gamification. See `SPEC.md` §0 + §15.

## Tech

- **Backend**: Next.js 16, TypeScript strict, Drizzle ORM, Neon Postgres, Clerk auth, Stripe + Razorpay payments, Inngest queues. Deployed on Vercel.
- **iOS**: SwiftUI 17.0+, SwiftData, StoreKit 2, xcodegen, one Xcode project with two targets sharing four Swift packages (KotiCore, KotiUI, KotiThemes, KotiL10n).
- **CI**: Xcode Cloud (Apple-hosted, latest Xcode), branch model: `main` for development, `release` for ships.

## Local dev

```bash
# Backend
cd backend && npm install && npm run dev
# → http://localhost:3000

# iOS — generate Xcode project from project.yml
cd ios && xcodegen generate && open Likhita.xcodeproj
```

## Status

Scaffolded 2026-05-06. Not yet shipped to TestFlight; pending Xcode Cloud OAuth and asset/animation production. See `SPEC.md` for v1 scope.

## License

The application code is open-source (license TBD pending Likhita Foundation incorporation). Religious content (mantras, shlokas, temple imagery) is in the public domain. The Likhita Foundation marks are reserved for the foundation's use only.

---

*Sri Rama Jayam.*
