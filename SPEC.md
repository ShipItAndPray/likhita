# Likhita Rama + Likhita Ram — Product Spec

**Two iOS apps. One backend. One non-profit foundation. One devotional engine.**

A digital seva, not a business. Two iOS apps under the **Likhita Foundation** that reimagine the Hindu practice of writing Rama's name 1 lakh / 1 crore times. Completed books are professionally printed and physically deposited at temples (Bhadrachalam for the Telugu app, Ram Naam Bank Varanasi for the Hindi app). A photo of *the user's specific book at the temple* + a temple-stamped receipt is mailed back as proof of deposit.

**This is not a startup. It is a digital extension of an ancient practice, run as a non-profit, with every rupee accounted for and every shipping fee at-cost.**

**Status:** v1 spec — pre-build, ready for design + scaffolding
**Platforms:** iOS only in v1 (SwiftUI). Android + web later.
**Owner:** Srini Somepalli (`shipitandpray`) — founder + trustee, Likhita Foundation
**Date:** 2026-05-05
**Org type:** Section 8 Company (India) + 501(c)(3) (US) — registration in progress

---

## Table of Contents

0. [Foundation & Mission (Non-Profit)](#0-foundation--mission)
1. [Core Concept](#1-core-concept)
2. [The Two Apps](#2-the-two-apps)
3. [Tradition + Mantra Matrix](#3-tradition--mantra-matrix)
4. [Competitive Landscape & Differentiation](#4-competitive-landscape--differentiation)
5. [Sankalpam Onboarding](#5-sankalpam-onboarding)
6. [Stylus + Input Model](#6-stylus--input-model)
7. [Writing Experience + Anti-Cheat](#7-writing-experience--anti-cheat)
8. [Progress Path — Ramayana Journey](#8-progress-path--ramayana-journey)
9. [Modes & Counts](#9-modes--counts)
10. [Book Themes](#10-book-themes)
11. [Audio Library](#11-audio-library)
12. [Completion Flow](#12-completion-flow)
13. [Temple Shipping Pipelines](#13-temple-shipping-pipelines)
14. [Cost-Recovery Pricing Model](#14-cost-recovery-pricing-model)
15. [Trust, Transparency & Audit](#15-trust-transparency--audit)
16. [iOS Architecture](#16-ios-architecture)
17. [Backend Architecture](#17-backend-architecture)
18. [Data Model](#18-data-model)
19. [API Surface](#19-api-surface)
20. [Design Briefs (for Claude Code)](#20-design-briefs-for-claude-code)
21. [v1 Scope](#21-v1-scope)
22. [Success Metrics (Mission, Not Revenue)](#22-success-metrics)
23. [Risks & Mitigations](#23-risks--mitigations)
24. [Open Questions](#24-open-questions)
25. [Next Steps](#25-next-steps)

---

## 0. Foundation & Mission

### Likhita Foundation

A non-profit organization established to serve practitioners of *Likhita Japa* — the ancient Hindu practice of devotional writing — in the digital age, while honoring its physical, sacramental tradition.

**"Likhita"** (लिखित / లిఖిత) is the Sanskrit word meaning *"that which is written."* It is the canonical term for written japa — a 2,000-year-old practice that asked the devotee to *write* the divine name with the same focus another might give to *speaking* or *thinking* it.

### Mission

> *To preserve the practice of Likhita Japa for the global Hindu diaspora, by combining the discipline and presence of digital practice with the sanctity and finality of a physical book deposited at a holy temple — at no profit to anyone.*

### Why non-profit

- This practice is **sacred**, not a market segment. Charging "what the market will bear" for sadhana is wrong.
- Existing apps in this space (RamaKoti, Ramnaam Book) are commercial products with paywalls, in-app purchases, and Apple-tax markups. Devotees pay 47% more on iOS for the same digital book that's cheaper elsewhere — because Apple takes 30% on top of margins.
- Likhita Foundation charges **only what it costs us** — printing, transport, temple coordination, server costs. Audited. Published. Zero profit.
- Any surplus (e.g. exchange-rate gains, donation overflow) is donated to the partner temples' maintenance funds.
- This isn't anti-business — it's *seva*. It is the right structure for the work.

### Legal structure (in progress)

| Jurisdiction | Form | Purpose |
|---|---|---|
| **India** | **Section 8 Company** under Companies Act 2013 | Operations, ops team, print partners, temple liaisons |
| **United States** | **501(c)(3) public charity** | Diaspora donations (tax-deductible), App Store account, payment receipts |

Section 8 Company is preferred over Public Charitable Trust for institutional credibility, structured governance, and easier banking with diaspora donations. 501(c)(3) is required for US-based donors to claim tax deductions.

### Founding principles (in the bylaws)

1. **No advertising.** Ever. The writing surface is sacred.
2. **No data sales.** Ever. We do not sell or share user practice data.
3. **No engagement gamification.** No streaks UI to manipulate, no "you're #4,872 in the world" leaderboards. Practice is private.
4. **Cost recovery only.** Every fee published, audited annually, broken down to the rupee.
5. **Open books.** Annual audit + financial reports published at `likhita.org/transparency`.
6. **No ownership.** No founder takes equity, salary above market for non-profit role, or surplus distribution.
7. **Temple respect.** No photo or content shared from temple grounds without temple authority approval.

---

## 1. Core Concept

A digital reimagining of two parallel Hindu devotional traditions:

- **South Indian — Rama Koti (రామ కోటి):** writing `శ్రీరామ` repeatedly. Completed books deposited at the **Sri Sita Ramachandra Swamy Temple, Bhadrachalam** (Telangana), in the Rama Koti Mandapam.
- **North Indian — Ram Naam Lekhan (राम नाम लेखन):** writing `राम` (or `सीताराम`) repeatedly. Completed books deposited at the **Ram Naam Bank, Varanasi** (est. 1926, Ramanandacharya tradition) — or optionally Ayodhya.

Users complete a koti (1 lakh / 1 crore / custom count) digitally on iPhone/iPad. The completed work is professionally printed as a cloth-bound book and physically deposited at the temple of their tradition. A photo of *their specific book at the temple* + a temple-stamped receipt is mailed/emailed back within 60 days.

**Every entry is typed**, not handwritten in v1. Each user's entries render in their unique **personal stylus** — a one-time calibration that locks color + cadence signature for the entire koti. **No copy-paste. No autofill. No macros.** Real practice, real commitment.

**One foundation. Two apps. Two pilgrimages. Zero profit.**

---

## 2. The Two Apps

| | 📱 **Likhita Rama** | 📱 **Likhita Ram** |
|---|---|---|
| **Audience** | Telugu / South Indian Hindu diaspora | Hindi / North Indian Hindu diaspora |
| **Bundle ID** | `org.likhita.rama` | `org.likhita.ram` |
| **App Store Name** | Likhita Rama — Rama Koti | Likhita Ram — Ram Naam Lekhan |
| **Practice (subtitle)** | Rama Koti (రామ కోటి) | Ram Naam Lekhan (राम नाम लेखन) |
| **Domain** | likhitarama.org | likhitaram.org |
| **Foundation site** | likhita.org (cross-app, transparency, donations) | likhita.org |
| **Default UI Language** | తెలుగు | हिन्दी |
| **Locked Tradition** | `.telugu` | `.hindi` (with Ram/Sitaram sub-choice) |
| **Mantra** | `శ్రీరామ` (typed as `srirama`) | `राम` (typed as `ram`) *or* `सीताराम` (typed as `sitaram`) |
| **Default Theme** | Bhadrachalam Classic | Banaras Pothi |
| **Temple Destination** | Bhadrachalam | Ram Naam Bank Varanasi (or Ayodhya, +₹300) |
| **Audio Library** | Tyagaraja, Annamayya, Bhadrachalam dhwani | Tulsidas Ramcharitmanas, Hanuman Chalisa, Raghupati Raghav |
| **Splash Visual** | Bhadrachalam temple silhouette + Godavari river | Varanasi ghats silhouette + Ganga aarti |
| **Icon** | Red cloth + gold "శ్రీ" | Saffron cloth + gold "श्री" |

### What's shared (one engine)

- Backend (Next.js + Vercel + Neon Postgres)
- Auth (Clerk; one account works in both apps)
- Anti-cheat engine (per-keystroke validation, server-authoritative)
- Stylus rendering engine
- Writing surface UX
- Sankalpam onboarding flow (skin/strings differ; logic shared)
- Ramayana progress path (labels swap by language)
- Completion ceremony engine
- Payment + shipping pipeline
- Print/ship logistics (one operations team, two temple destinations)

### What's different (white-label config)

- Bundle ID, app name, icon, splash, default theme
- Locked tradition + mantra
- Default UI language + audio library
- App Store keywords/screenshots/description
- Marketing landing page

**Pattern:** one Xcode project, two targets, ~95% shared code via Swift Packages. Standard white-label architecture (Lyft Driver/Rider model).

---

## 3. Tradition + Mantra Matrix

| Tradition | App | Mantra (rendered) | Typed (Romanized v1) | Sub-choice | Temple |
|---|---|---|---|---|---|
| Telugu | Rama Koti | `శ్రీరామ` | `srirama` | none | Bhadrachalam |
| Hindi — Ram | Ram Naam Lekhan | `राम` | `ram` | "Ram" path | Ram Naam Bank |
| Hindi — Sitaram | Ram Naam Lekhan | `सीताराम` | `sitaram` | "Sitaram" path | Ram Naam Bank |

**v2 expansion (post-launch):** Tamil (`ஸ்ரீராம`, Rameshwaram), Kannada (`ಶ್ರೀರಾಮ`, Bhadrachalam), Marathi (`राम` Devanagari, Ayodhya/Pandharpur), Bengali (`শ্রীরাম`, TBD).

---

## 4. Competitive Landscape & Differentiation

We are **not first to market.** Three apps already exist in this space. We must be **demonstrably better** along the right dimensions, while honoring the practice. Here is the honest landscape:

### Existing apps

#### A. RamaKoti (PRAMANAM INC) — `apps.apple.com/us/app/ramakoti/id1566105925`
- **What it does:** Digital "Sri Rama" writing in multiple languages. iOS + macOS + visionOS.
- **Strengths:** First mover (since 2021), multi-platform, multilingual.
- **Gaps:** No temple deposit, no physical printed book, no shipping pipeline, paywalled features, modest user base, no non-profit framing.
- **Our advantage:** Physical book + temple delivery + receipt + photo. They are a counter; we are a complete pilgrimage.

#### B. Ramnaam Book (Sadguru Aniruddha lineage) — `apps.apple.com/us/app/ramnaam-book/id1450926531`
- **What it does:** Structured 220-page book with mantras across pages, deposited to *"Aniruddha's Universal Bank of Ramnaam"* — their organization's internal repository, not a public temple.
- **Strengths:** Established brand within Aniruddha Bapu followers, structured book format, has its own bank.
- **Gaps:** **Documented user complaints** — frequent iOS crashes, "Loading" errors mid-writing, exits during writing, small fonts/buttons, no accessibility, password reset broken. Charges **₹399 on iOS for 9 books vs ₹270 elsewhere** — 47% Apple-tax markup passed to user.
- **Sect-specific:** Tied to Aniruddha lineage, not universally accepted across Sanatan Hindu traditions.
- **Our advantage:** Stable SwiftUI app, accessible (Dynamic Type, VoiceOver), transparent at-cost pricing (no Apple-tax markup hidden), open to all Hindu traditions, deposits at *public, traditional* temples (Bhadrachalam, Ram Naam Bank Varanasi est. 1926) — not a private organizational bank.

#### C. Likhita Japa (recent, multi-deity) — `apps.apple.com/us/app/likhita-japa/id6478656535`
- **What it does:** Multi-deity counter — pick Rama, Krishna, Shiva, Lakshmi, Sai, Murugan, Jesus, Allah, set target count, write mantras with on-screen reference script.
- **Strengths:** Pan-religious, simple UX, recently updated.
- **Gaps:** Pure counter app — no physical book, no temple deposit, no shipping, no completion ceremony, no anti-cheat, no traditional binding aesthetic.
- **Our advantage:** Same as RamaKoti above. We are the only app that makes the practice *complete* by depositing the physical artifact at a sacred site.

### Differentiation matrix

| Feature | Likhita Rama / Likhita Ram | RamaKoti | Ramnaam Book | Likhita Japa |
|---|---|---|---|---|
| Digital writing surface | ✅ | ✅ | ✅ | ✅ |
| **Personal stylus signature** | ✅ unique | ❌ | ❌ | ❌ |
| **Anti-cheat (cadence, no paste, server-authoritative)** | ✅ rigorous | ❌ | ❌ | ❌ |
| **Physical printed book mailed** | ✅ | ❌ | ✅ paid | ❌ |
| **Deposited at public traditional temple** | ✅ Bhadrachalam / Ram Naam Bank Varanasi | ❌ | ❌ private org bank | ❌ |
| **Photo of YOUR book at temple** | ✅ | ❌ | ❌ | ❌ |
| **Temple-stamped receipt** | ✅ | ❌ | ❌ | ❌ |
| **Sankalpam onboarding (vow ritual)** | ✅ | ❌ | ❌ | ❌ |
| **Ramayana journey progress** | ✅ | ❌ | ❌ | ❌ |
| **Beautiful traditional binding (cloth, gold foil)** | ✅ | ❌ | ❌ | ❌ |
| **Non-profit, audited, transparent pricing** | ✅ | ❌ commercial | ❌ commercial | ❌ commercial |
| **Open to all Hindu traditions** | ✅ | ✅ | ❌ Aniruddha-tied | ✅ |
| **Apple-tax markup transparency** | ✅ disclosed | ❌ | ❌ hidden | ❌ |
| **Sect-neutral** | ✅ | ✅ | ❌ | ✅ |
| **iOS UX quality** | ✅ SwiftUI, accessible | unknown | ❌ crashes reported | ✅ |
| **Free app, free default theme** | ✅ | partial | ❌ paid | ✅ |
| **Zero ads, zero data sales (in bylaws)** | ✅ enforceable | unknown | unknown | unknown |

### Our positioning (one sentence)

> *"The only app that completes the practice — from your screen to the steps of Bhadrachalam, with proof in your hands — run as a non-profit so every rupee goes where it belongs."*

### Marketing copy (sanctity-preserving)

- **Hero (Likhita Rama):** *"శ్రీరామ. Written by you. Delivered to Bhadrachalam."*
- **Hero (Likhita Ram):** *"राम. लिखा आपने। पहुँचा बनारस।"*
- **Foundation:** *"A digital seva. Not a startup. Not for profit. For Rama."*
- **Trust line:** *"At-cost. Audited. Open books. likhita.org/transparency."*

---

## 5. Sankalpam Onboarding

Onboarding is a **sankalpam** (vow-taking ceremony), not a signup form. **3 minutes. Cannot be skipped. Cannot be redone for the current koti.**

Tradition is **locked by which app the user installed** — no "pick your tradition" screen. Likhita Rama users get Telugu path (Rama Koti practice). Likhita Ram users get Hindi path (Ram Naam Lekhan practice, with Ram/Sitaram sub-choice in step 0).

### Step 0: Mantra Sub-choice (Likhita Ram app only)

Hindi app users pick between two mantras at start. Locked.

| Choice | Mantra | Typed | Description |
|---|---|---|---|
| **Ram** *(default)* | `राम` | `ram` | Most common. Short, fast, foundational. |
| **Sitaram** | `सीताराम` | `sitaram` | Vaishnava preference. Honors Sita-Ram together. |

Telugu app skips this step — `శ్రీరామ` is the only mantra.

### Step 1: Identity

- **Full name** (as it should appear printed in the book — supports Telugu/Devanagari/Roman)
- **Gotra** (optional)
- **Native place** (optional, for the colophon page)
- **Email + phone** (for shipping confirmation, OTP)

### Step 2: Sankalpam (Dedication)

- *Why are you doing this koti?* (free text, max 280 chars — printed on book's first page)
- *Dedicate this koti to:* (optional — self / parent / child / departed soul / deity / community / family / cause)
- The dedication is printed on **page 1** of the final book in the user's script + English.

### Step 3: Mode Selection

| Mode | Count | Pages (~150/pg) | Typical Duration |
|---|---|---|---|
| Trial | 1,000 | 7 | 1 hour |
| Daily Practice | 11,000 | 73 | 1–2 weeks |
| Sankalpa | 51,000 | 340 | 1–3 months |
| **Lakh** *(default)* | **100,000** | **666** | **3–12 months** |
| Maha Sankalpa | 1,16,000 | 773 | 4–14 months |
| **Crore** | **10,000,000** | **66,666** | **lifetime / family** |

Crore mode requires consent screen ("This is a lifetime sadhana. The book will be printed in multi-volume format. Continue?").

Mode is **locked** once the koti begins.

### Step 4: Input Mode + Stylus Calibration

**4a. Input mode** (locked, v1 = romanized only):
- **Romanized (default, v1)** — types on iOS native keyboard. `srirama` / `ram` / `sitaram`. Easiest, works anywhere, no IME setup.
- *Native script (v2)* — on-screen keyboard with mantra syllable buttons. More authentic, slower.

**4b. Stylus calibration** (locked):
- User picks a stylus from a pre-set palette of **12 traditional inks**:
  - Vermillion `#E34234`, Kumkum red `#DC143C`, Saffron `#FF7722`, Marigold `#FFA500`, Indigo `#4B0082`, Lamp-black `#1C1C1C`, Sandalwood brown `#A0522D`, Gold `#D4AF37`, Tulsi green `#5F8A3F`, Peacock blue `#005A82`, Earthen red `#8B4513`, Royal purple `#3F1A52`
- User performs a **5-stroke calibration**: types the mantra five times. The system samples typing rhythm + cadence + per-key dwell time and binds it as the **stylus signature** (a hash, not raw biometrics).
- Each entry renders in user's stylus color, in the script of their tradition, with subtle organic variation (slight ink bleed, micro-jitter on baseline, randomized character spacing within ±2px) — feels handwritten, not robotic.
- Stylus is **locked** for the koti. Cannot change.

### Step 5: Theme Selection

User picks 1 theme from their app's available set (see §9). Locked for the koti.

### Step 6: Affirmation Pledge

A short on-screen pledge in the user's UI language. User must tap-and-hold a "Begin / आरंभ / ఆరంభించు" button for 2 seconds to commit (deliberate friction).

**Telugu pledge:**
> *"నేను ఈ రామ కోటిని భక్తితో ఆరంభిస్తున్నాను. shortcuts ఉపయోగించను. ప్రతి శ్రీరామను శ్రద్ధతో వ్రాస్తాను. ఈ సాధనను [dedication]కి అంకితం చేస్తున్నాను. శ్రీరామ జయం."*

**Hindi pledge (Ram):**
> *"मैं यह राम नाम लेखन श्रद्धा से आरंभ करता/करती हूँ। मैं कोई shortcut नहीं लूँगा/लूँगी। प्रत्येक राम-नाम को मन से लिखूँगा/लिखूँगी। यह साधना [dedication] को समर्पित है। जय श्री राम।"*

**Hindi pledge (Sitaram):**
> *"मैं यह सीताराम नाम लेखन श्रद्धा से आरंभ करता/करती हूँ ... यह साधना [dedication] को समर्पित है। सीताराम सीताराम।"*

User taps Begin. Counter starts at 0. Koti is now active.

---

## 6. Stylus + Input Model

### Stylus signature

A stylus signature is a tuple:
```
{
  ink_color: hex,
  base_cadence_ms: number,        // avg ms between keystrokes
  cadence_variance_ms: number,    // std deviation
  per_key_dwell_ms: object,       // avg dwell time per character
  stroke_pressure_curve: float[]  // sampled from calibration (iOS reports key-press intensity on supported hardware)
}
```

Stored as a hash in `kotis.stylus_signature_hash`. Used for:
1. **Rendering** — each entry rendered in the user's ink with their cadence-correlated micro-variation.
2. **Anti-cheat** — incoming entries that deviate >3σ from the user's signature are flagged for soft review (not blocked, just observed).

### Input rules (v1, romanized)

User types one of these strings, exactly:
- Telugu app: `srirama` (7 chars) → renders `శ్రీరామ`
- Hindi-Ram: `ram` (3 chars) → renders `राम`
- Hindi-Sitaram: `sitaram` (7 chars) → renders `सीताराम`

On exact match → entry committed, counter increments, page renders entry, input clears.
On deviation → input shakes, line is voided, no progress. **No backspace mid-word.**

### Why romanized in v1

- Zero IME friction — works on every iPhone instantly
- Faster onboarding for diaspora users who may not have native keyboards installed
- v2 native script keyboard adds authenticity for purists; gracefully ships later

### What renders in the book

Regardless of input method, **the printed/displayed mantra is always in the user's chosen script** (Telugu or Devanagari). The input method is a means; the rendered glyph is the practice.

---

## 7. Writing Experience + Anti-Cheat

### Visual: the book spread

The screen looks like an open bound book.

- **iPhone (portrait):** single page view with subtle binding shadow on the left edge; pages turn like a book, not a list.
- **iPad (landscape):** two-page spread with center binding; entries fill the right page first, then the left, then turn.
- Each page holds a grid of **150 entries** (15 cols × 10 rows on iPad page; 8 cols × 19 rows on iPhone page; configurable per theme).
- Currently-being-written line is highlighted with a thin ink-color underline.

### Chrome (minimal)

- **Top bar:** counter (current/target, e.g. `42,317 / 1,00,000`), milestone badge (current Ramayana location)
- **Side rail (iPad only):** Ramayana progress path SVG
- **Bottom:** input field (the only interactive element), audio toggle, tiny pause button
- **No notifications, no ads, no badges, no gamification beyond the path itself.** This is a sacred space.

### Anti-cheat (non-negotiable)

| Defense | Implementation |
|---|---|
| **Block paste** | iOS: disable paste menu on input field, suppress UIKit paste callback, ignore `UIPasteboard.changedNotification`-driven inserts |
| **Block autofill** | `textContentType = .none`, disable Smart Punctuation, disable Predictive Text, disable Spell Check |
| **Block dictation** | Disable `keyboardType = .default` mic button via `enablesReturnKeyAutomatically + smartQuotesType = .no` and dictation suppression where supported |
| **Per-keystroke validation** | Each character logged client-side with timestamp + dwell + intensity; batched to server every 5 entries |
| **Server-side cadence entropy check** | Reject batches with sub-50ms variance OR sub-30ms inter-key gaps (humans aren't robots) |
| **Macro detection** | If 10 consecutive entries arrive with identical cadence pattern → soft 5-min lockout: *"Slow down. This is sadhana, not a race."* |
| **Hold-key suppression** | iOS `UIKeyInput.insertText` only fires once per key press; no autorepeat capture |
| **No backspace mid-word** | Input field overrides `deleteBackward()` mid-mantra to void the entry |
| **Session continuity** | Server tracks contiguous session windows; large gaps (>30 days) require re-affirmation pledge |
| **Server is source of truth** | Client cannot increment counter; only successful server commit increments |
| **Rate limit** | Hard cap: max 4 entries/second per user (way above human max ~2/sec for `srirama`) |

### What we DON'T do

- ❌ Track location (privacy)
- ❌ Track other apps the user is using
- ❌ Track screen recording / mirroring (would punish accessibility)
- ❌ Hard-ban suspect users (false-positive risk too high; soft lockouts only)

---

## 8. Progress Path — Ramayana Journey

The progress visualization is a **map of Sri Rama's journey through the Ramayana**, not a bar. The journey is universal across both traditions (the Ramayana is shared canon) — milestone *labels* render in the user's UI language.

### Milestones (1 lakh = baseline; 1 crore scales 100x)

| # | Milestone | Telugu label | Hindi label | Lakh count | Crore count | Visual |
|---|---|---|---|---|---|---|
| 1 | Ayodhya (start) | అయోధ్య | अयोध्या | 0 | 0 | Palace gates open at dawn |
| 2 | Chitrakoot | చిత్రకూటం | चित्रकूट | 10,000 | 10,00,000 | Forest ashram, deer grazing |
| 3 | Panchavati | పంచవటి | पंचवटी | 25,000 | 25,00,000 | Riverside hut, golden deer |
| 4 | Kishkindha | కిష్కింధ | किष्किंधा | 50,000 | 50,00,000 | Hanuman meets Rama |
| 5 | Setu | సేతు | सेतु | 75,000 | 75,00,000 | Bridge to Lanka built across the sea |
| 6 | Lanka | లంక | लंका | 90,000 | 90,00,000 | Battle, Ravana's fortress |
| 7 | Pattabhishekam (return) | పట్టాభిషేకం | राज्याभिषेक | 100,000 | 1,00,00,000 | Coronation in Ayodhya, Sita beside Rama |

### Behavior

- Side rail SVG (iPad) or full-screen takeover (iPhone tap) shows the path.
- Current location is animated (gentle pulse, not flashing).
- Each milestone unlock plays a short shloka audio (skippable):
  - **Telugu app:** South Indian intonation, Tyagaraja kriti or Telugu Ramayana parayanam.
  - **Hindi app:** Tulsidas chaupai from Ramcharitmanas, in classical Awadhi/Hindi.
- Numerical progress bar shown beneath path for users who want a precise number.
- Crore mode shows the same 7 milestones at 100x scale; an additional thin horizontal bar shows progress within the current Ramayana segment.

---

## 9. Modes & Counts

### Standard counts (offered in onboarding)

- **Trial:** 1,000
- **Daily:** 11,000
- **Sankalpa:** 51,000
- **Lakh:** 1,00,000 *(default)*
- **Maha Sankalpa:** 1,16,000
- **Crore:** 1,00,00,000

### Custom counts (v2)

Any positive integer ≤ 10 crore. UI converts to lakh/crore notation.

### Daily-streak mode (v2)

No total count. User commits to N entries per day (e.g. 108 daily for life). Streak tracker. Missed day → optional "atonement" of 2× the next day.

### Family / multi-user koti (v2)

One koti shared across multiple family members. Each member's entries rendered in their own stylus color → final book is multi-colored, showing each contributor's contribution.

---

## 10. Book Themes

Themes define cover, page texture, ornaments, milestone art, font choice, and ink rendering style. **Locked at koti start.** Each app has its own default + premium themes.

### Likhita Rama themes (Telugu app)

#### 1. Bhadrachalam Classic *(default, free)*
- **Cover:** Deep red `#8B0000` cloth binding, gold-leaf foil "శ్రీరామ కోటి" + Sri Rama yantra
- **Pages:** Cream `#FFF8DC` interior, subtle Telugu palm-leaf watermark
- **Ornaments:** Gold corner motifs, lotus borders
- **Font:** Tiro Telugu (designed for sacred texts)
- **Ink rendering:** Slight bleed, vermillion `#E34234` default

#### 2. Palm-leaf Manuscript / Ola *(₹199)*
- **Cover:** Brown ola-leaf texture, etched-style Telugu lettering (no gold)
- **Pages:** Aged tan, palm-leaf vein texture
- **Ornaments:** Hand-etched style flourishes
- **Font:** Tiro Telugu condensed
- **Ink rendering:** Heavier dark ink, slight smudge

#### 3. Tirupati Saffron *(₹199)*
- **Cover:** Saffron `#FF7722` + maroon `#800000`, Tirumala namam motif
- **Pages:** Cream with saffron borders
- **Ornaments:** Vaishnava nama markings, conch-discus subtle accents
- **Font:** Anek Telugu (modern but devotional)

### Likhita Ram themes (Hindi app)

#### 1. Banaras Pothi *(default, free)*
- **Cover:** Saffron `#FF7722` cloth binding, gold "श्री राम नाम" + Ganga ghat motif
- **Pages:** Handmade-paper cream `#F5E6D3`, subtle deckle edges, OM watermark
- **Ornaments:** Marigold (`#FFA500`) garland borders, peepal leaf accents
- **Font:** Tiro Devanagari Hindi (designed for sacred manuscripts)
- **Ink rendering:** Lamp-black `#1C1C1C` default, slight ink bleed

#### 2. Ayodhya Sandstone *(₹199)*
- **Cover:** Pink sandstone (`#E5A189`) — Ram Mandir aesthetic, gold "श्री राम"
- **Pages:** Cream with lotus motif borders, Saryu river accents
- **Font:** Mukta (clean modern Devanagari)

#### 3. Tulsidas Manuscript *(₹199)*
- **Cover:** Aged parchment `#D4B896`, hand-stitched binding feel
- **Pages:** Avadhi-script feel, marigold accent on page numbers
- **Ornaments:** Tulsidas Ramcharitmanas-style chaupai dividers
- **Font:** Tiro Devanagari Hindi italic variant

### Universal themes (both apps, ₹199)

#### 4. Parchment
- Aged cream `#F5E6D3`, ink-bleed heavy, minimalist border, no religious iconography. Renders in Telugu OR Devanagari per app.

#### 5. Modern Minimalist
- Clean white `#FAFAFA`, single accent color (saffron or kumkum), sans-serif font (Anek Telugu / Mukta), generous whitespace. For younger users.

---

## 11. Audio Library

Tradition-aware. **Off by default.** All audio uses **AVAudioSession.playback** category so it ducks for calls/Siri.

### Likhita Rama (Telugu app)

| Track | Description | Length |
|---|---|---|
| Bhadrachalam Dhwani | Continuous "Sri Rama Sri Rama" chant from Bhadrachalam temple recordings | Loop |
| Tyagaraja — Endaro Mahanubhavulu | Classical Carnatic kriti | 8 min |
| Annamayya — Adivo Alladivo | Telugu padam | 5 min |
| Telugu Ramayana Parayanam | Ranganatha Ramayana selections | 30 min |
| Soft Bell + Bhadrachalam Bell | Ambient temple bells | Loop |
| Silence | Subtle white noise + breath | Loop |

### Likhita Ram (Hindi app)

| Track | Description | Length |
|---|---|---|
| Raghupati Raghav Raja Ram | Classic bhajan loop | Loop |
| Tulsidas Ramcharitmanas — Sundar Kand | Awadhi parayanam | 30 min |
| Hanuman Chalisa | 40 verses | 9 min |
| Sri Ram Jai Ram Jai Jai Ram | Mantra loop | Loop |
| Varanasi Ganga Aarti | Ambient ghat recording | Loop |
| Silence | Subtle white noise + breath | Loop |

### Settings: Off / Soft (low volume) / Full (normal volume)

---

## 12. Completion Flow

When user hits target count:

### Step 1: Pattabhishekam Ceremony (full-screen takeover, ~30s)

- Full-screen animation: Rama returns to Ayodhya, gates open, coronation scene unfolds
- User's name + dedication + total count + duration appear in elegant lower-third
- Final shloka plays (Telugu app: Ranganatha Ramayana mangala shloka; Hindi app: Tulsidas's Vinay Patrika mangalacharan)
- Haptic: long, slow rumble (UIImpactFeedbackGenerator .heavy + 3 .soft pulses)

### Step 2: Book Preview

Scrollable preview of the user's full bound book:
- Cover (theme-rendered with their name)
- Frontispiece (theme art)
- Dedication page (sankalpam text)
- Sample 4-page spread of their entries
- Colophon page (start date, end date, total count, location of completion, "Submitted to [temple]")

### Step 3: Ship Decision

Three options (presented as ornate cards):

| Option | Price (INR) | Price (USD) |
|---|---|---|
| **a) Ship to temple** *(primary CTA)* — Bhadrachalam (Likhita Rama) or Ram Naam Bank Varanasi (Likhita Ram) | ₹740 | $9 |
| **b) Ship to your home** — premium printed bound book to user's address | ₹1,499 | $19.99 |
| **c) Both** | ₹1,999 | $26.99 |

Hindi app shows additional option:
- *Optional Ayodhya alternative:* +₹300 / $4.99 — book delivered to designated mandir near Ram Janmabhoomi

After payment: confirmation screen with estimated dates (printing 3 weeks → batched quarterly → delivered → photo back within 60 days).

### Step 4: Future Ritual

User is offered the option to:
- Start another koti (new sankalpam)
- Switch to daily-practice mode (v2)
- Share completion (no leaderboards — only a beautiful shareable card with their name + completion date + dedication, *count is private by default*)

---

## 13. Temple Shipping Pipelines

### Pipeline A: Bhadrachalam (Likhita Rama app)

1. Completion → backend marks koti `pending_print`
2. Quarterly batch (Jan/Apr/Jul/Oct) → batch sent to **Hyderabad print partner** (cloth-bound, gold foil "శ్రీరామ కోటి")
3. Books bundled, transported to **Sri Sita Ramachandra Swamy Temple, Bhadrachalam** by our representative
4. Books placed in the **Rama Koti Mandapam**
5. Photographer captures *each individual book* with the Mandapam visible in frame
6. Temple-stamped receipt obtained per book (or per batch with names listed — depends on temple's process)
7. Photos + receipt scanned, uploaded to backend
8. User receives email + push notification: *"Your Rama Koti has reached Bhadrachalam. Sri Rama Jayam."* with photo + receipt PDF

### Pipeline B: Ram Naam Bank Varanasi (Likhita Ram app)

1. Completion → backend marks koti `pending_print`
2. Quarterly batch → Hyderabad partner prints (or Varanasi/Delhi partner — TBD cost optimization)
3. Books transported to **Ram Naam Bank, Varanasi**
4. Books deposited as ledgers with the bank office (Ramanandacharya tradition)
5. Bank issues a stamped receipt per book (this is their existing tradition — they've issued receipts since 1926)
6. Photographer captures each book with bank/temple visible
7. Photos + receipt → backend → user notification

### Optional: Ayodhya (Hindi app, +₹300)

- Same pipeline, but final destination is a partner mandir near **Ram Janmabhoomi** (TBD partner; validate before launch)
- May involve longer logistics chain

### Operational reality

- **One ops team** handles both pipelines
- **One quarterly trip** can hit Bhadrachalam → Hyderabad → Delhi → Varanasi → Ayodhya in ~7 days
- **One representative** documents everything with photo + receipt
- Cost: representative travel ~₹15K–25K per quarterly trip; print cost ~₹250–400 per 666-page book

---

## 14. Cost-Recovery Pricing Model

**The foundation makes zero profit.** Every fee charged is at our actual cost, plus the unavoidable platform/payment processing overhead, plus a tiny buffer (≤5%) for ops contingency. Every line item is broken down publicly at `likhita.org/transparency`.

### Free forever

| Item | Price |
|---|---|
| App download (both apps) | **Free** |
| All themes (in v1: Bhadrachalam Classic + Banaras Pothi) | **Free** |
| Stylus calibration | **Free** |
| Writing surface, all features | **Free** |
| Anti-cheat, sankalpam, ceremony | **Free** |
| Past kotis archive | **Free** |

### At-cost services (printed book + temple delivery)

These are the only paid services. Each price is the *true cost*, audited annually.

#### Ship to temple (the core service)

| Component | Cost (INR) | Notes |
|---|---|---|
| Print: 666-page cloth-bound book with gold foil | ₹350 | Hyderabad press partner; quote validated quarterly |
| Materials: cloth, gold foil, archival paper | ₹120 | |
| Inland transport (Hyderabad → Bhadrachalam OR Varanasi) | ₹80 | Bundled quarterly; per-book share |
| Temple coordination + photographer + receipt | ₹100 | Representative travel + camera + paperwork |
| Payment processing (Razorpay 2% / Stripe 2.9% + $0.30) | ₹40 | Pass-through |
| Server costs allocated (Vercel + Neon, per-koti share) | ₹15 | Pass-through |
| Inflation/currency buffer (5% max) | ₹35 | If unused, donated to temple |
| **Total: Ship to temple** | **₹740** | **(~$9 USD at current exchange)** |

**Published price:** `₹740 / $9` *(or current audited cost — see likhita.org/transparency)*

This is **₹260 cheaper than the original commercial spec** of ₹999, because the foundation takes zero margin.

#### Ship to home (optional premium binding)

| Component | Cost (INR) |
|---|---|
| Premium 666-page book (thicker cloth, hand-stitched binding) | ₹650 |
| Materials | ₹180 |
| Domestic India shipping (Speed Post Tracked) | ₹180 |
| International shipping (US/UK/Canada/AU) | ₹950 |
| Packaging (archival box, satin pouch) | ₹120 |
| Payment processing | ₹50 |
| Server share | ₹15 |
| Buffer | ₹55 |
| **Total: India** | **₹1,250** | (~$15) |
| **Total: International** | **₹2,200** | (~$26) |

#### Both (temple + home)

Discounted because we print one extra copy in the same batch:

| Region | Cost |
|---|---|
| Both — India recipient | ₹1,750 (~$21) |
| Both — International recipient | ₹2,700 (~$32) |

#### Ayodhya destination upgrade (Hindi app only)

Additional logistics cost:
- Extra inland transport (Varanasi or Hyderabad → Ayodhya) + Ayodhya partner mandir coordination: **+₹250 (~$3)**

#### Crore-mode multi-volume binding *(v2)*

A 1-crore koti = ~66,666 pages = ~10 volumes of 6,666 pages each. Premium hand-bound multi-volume set:

- Per-volume cost ~₹400 × 10 = ₹4,000 print
- Custom slipcase + boxed set: ₹600
- Materials uplift: ₹400
- **Total estimate: ₹5,000–6,000** *(refined when first crore koti completes)*

### Apple-tax transparency

Apple takes **30%** (or 15% Small Business Program) on in-app purchases. To avoid this premium being borne by users:

- **All paid services use external web checkout via Safari (Razorpay/Stripe direct)** for users in regions where Apple's anti-steering rules permit (post-Epic ruling US, EU per DMA, India)
- **Where Apple IAP is required by Apple's regional rules**, we display a **disclosure banner** clearly: *"This purchase via Apple Pay carries a 30% / 15% Apple platform fee that we cannot avoid in this region. Total: ₹X. To avoid this fee, complete the purchase at likhita.org/checkout."*
- We will **not silently mark up** like commercial competitors do.

### Donations (optional, not required)

Users may *optionally* donate via:
- One-time donations: any amount
- Recurring monthly: ₹100 / ₹500 / ₹1,000 / custom
- 100% goes to: temple maintenance funds, free shipping for low-income users, or app development (in that priority order)

Donations are **never** prompted during writing or onboarding. Available only from the Settings → "Support the Foundation" link.

US donors get 501(c)(3) tax receipts. Indian donors get 80G tax certificates (after registration completes).

### What we will not do

- ❌ Ads (anywhere)
- ❌ Paid themes that gate sanctity (default theme is always free and traditionally beautiful)
- ❌ "Premium" tiers that gate practice features
- ❌ Loot boxes, gacha, surprise mechanics — even framed as "auspicious random ink colors," no
- ❌ Affiliate links to third-party religious products
- ❌ Sponsored shlokas, sponsored milestones, sponsored audio
- ❌ "Donate to unlock" messaging
- ❌ Any UX dark pattern

---

## 15. Trust, Transparency & Audit

The foundation's credibility is built on radical transparency. This is non-negotiable; it is the structural difference from commercial competitors.

### Public transparency portal: `likhita.org/transparency`

This single page, updated quarterly, shows:

#### Financials (live)
- **Revenue YTD** (broken down by category: temple shipping, home shipping, donations)
- **Costs YTD** (broken down: print, materials, transport, server, payment processing, ops, audit)
- **Surplus / deficit** for the year
- **Every disbursement** of any surplus (which temple, what amount, with public temple acknowledgment letter)
- **Annual independent audit report** (PDF download)
- Per-book unit economics breakdown (live spreadsheet)

#### Operations (live)
- Number of kotis completed YTD
- Number of books shipped to each temple this quarter
- Photos of each quarterly batch arriving at the temple (consented, anonymized at user level)
- Temple acknowledgment receipts (sample + aggregate count)

#### Governance
- Trustees / directors (names, bios, conflict of interest disclosures)
- Bylaws (full PDF)
- 80G certificate, 12A registration, 501(c)(3) determination letter (when available)
- Board meeting minutes (redacted as needed for individual privacy)

### Privacy (also published)

- We collect: name, email, phone, dedication text, koti entries, payment records.
- We do NOT collect: location, device sensors beyond keyboard input, contacts, browsing.
- We do NOT share data with: advertisers (we have none), data brokers (refused), third-party analytics that resell.
- We DO share data with: print partner (name + address for shipping), temple representative (name + dedication for the book), payment processor (mandatory for fraud).
- All data deleted within 90 days of user account deletion request, except completed-koti records (kept for the book's permanence).

### What annual audit checks

Independent CA firm in India + 990 filing in US:
1. Are all collected fees within published cost-recovery margins?
2. Is the surplus disbursement schedule honored?
3. Are no related-party transactions occurring?
4. Are trustees compensated within sector norms (and disclosed)?
5. Are donor restrictions honored?
6. Is the privacy policy actually being followed?

### Temple co-trust

Where possible, we structure the relationship with each partner temple as a **co-trust arrangement** — the temple receives a small standing endowment from any annual surplus, in their name, used for upkeep of the Rama Koti Mandapam (Bhadrachalam) or the Ram Naam Bank repository (Varanasi). Their names are on the bylaws.

---

## 16. iOS Architecture

### One Xcode project, two targets

```
Likhita.xcworkspace
├── Likhita.xcodeproj
│   ├── Targets
│   │   ├── LikhitaRama           (Telugu app)
│   │   │   ├── Info.plist        (CFBundleName: Likhita Rama)
│   │   │   ├── AppConfig.swift   (.telugu, .bhadrachalamClassic, "srirama")
│   │   │   ├── Assets.xcassets   (red+gold icon, Bhadrachalam splash)
│   │   │   └── LikhitaRamaApp.swift (@main)
│   │   └── LikhitaRam            (Hindi app)
│   │       ├── Info.plist        (CFBundleName: Likhita Ram)
│   │       ├── AppConfig.swift   (.hindi, .banarasPothi, mantra: .ramOrSitaramSubchoice)
│   │       ├── Assets.xcassets   (saffron+gold icon, Banaras splash)
│   │       └── LikhitaRamApp.swift (@main)
│   └── (no shared sources — all in packages below)
│
├── Packages/
│   ├── KotiCore/                  Swift Package — pure Swift, no UI
│   │   ├── Models/                Koti, Entry, User, Stylus, Theme, Tradition
│   │   ├── APIClient/             URLSession + async/await; X-App-Origin header
│   │   ├── AntiCheat/             cadence validation, dwell tracking, signature hashing
│   │   ├── StylusEngine/          ink rendering math, color math, jitter
│   │   └── PersistenceLayer/      SwiftData — offline cache + queue
│   │
│   ├── KotiUI/                    Swift Package — SwiftUI views, themable
│   │   ├── Sankalpam/             onboarding flow (steps 1–6)
│   │   ├── WritingSurface/        the book spread + input field
│   │   ├── ProgressPath/          Ramayana journey SVG renderer
│   │   ├── BookPreview/           full-book scrollable preview
│   │   ├── Completion/            Pattabhishekam ceremony
│   │   ├── ShipFlow/              ship-to-temple flow
│   │   └── Settings/              account, audio, notifications
│   │
│   ├── KotiThemes/                Swift Package — theme assets
│   │   ├── BhadrachalamClassic/
│   │   ├── PalmLeafOla/
│   │   ├── TirupatiSaffron/
│   │   ├── BanarasPothi/
│   │   ├── AyodhyaSandstone/
│   │   ├── TulsidasManuscript/
│   │   ├── Parchment/
│   │   ├── ModernMinimalist/
│   │   └── Fonts/
│   │       ├── TiroTelugu/
│   │       ├── TiroDevanagariHindi/
│   │       ├── AnekTelugu/
│   │       └── Mukta/
│   │
│   └── KotiL10n/                  Swift Package — strings + localizations
│       ├── te.lproj/              Telugu strings
│       ├── hi.lproj/              Hindi strings
│       └── en.lproj/              English fallback
│
└── project.yml                    (xcodegen — committed; .xcodeproj generated)
```

### Tech stack (iOS)

| Concern | Choice |
|---|---|
| UI framework | **SwiftUI** (iOS 17+) |
| State | `@Observable` (iOS 17 macro) |
| Async | `async/await`, `AsyncSequence` |
| Networking | `URLSession` + custom decoder |
| Local storage | **SwiftData** (offline entry queue + sync) |
| Auth | **Clerk iOS SDK** (Sign in with Apple primary; email magic-link fallback) |
| Payments | **StoreKit 2** for IAP; Razorpay SDK for India web flows |
| Animations | SwiftUI native + Lottie for ceremony scenes |
| Fonts | Bundled Noto/Tiro fonts via `UIFontDescriptor` registration |
| Haptics | `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator` |
| Audio | `AVAudioEngine` (gapless looping for chant); `AVAudioSession.playback` category |
| Telemetry | **PostHog iOS SDK** (privacy-respecting; no third-party tracking on writing surface) |
| Crash reporting | **Sentry iOS SDK** |
| Build | **xcodegen** + **Xcode Cloud** (per `ios-deployment` skill memory) |
| Min iOS version | **iOS 17.0** (covers ~95% of devices in 2026; SwiftData requires 17) |
| Devices | iPhone (portrait primary) + iPad (landscape, two-page spread) |

### Build configuration

Each target sets `APP_TRADITION` and `APP_DEFAULT_THEME` as build settings, exposed in `AppConfig.swift`:

```swift
// LikhitaRama/AppConfig.swift
enum AppConfig {
    static let tradition: Tradition = .telugu
    static let defaultTheme: Theme = .bhadrachalamClassic
    static let mantra: Mantra = .srirama
    static let allowMantraSubchoice = false
    static let templeDestination: TempleDestination = .bhadrachalam
    static let appName = "Likhita Rama"
    static let practiceName = "Rama Koti"
    static let bundleId = "org.likhita.rama"
    static let foundationURL = "https://likhita.org"
}

// LikhitaRam/AppConfig.swift
enum AppConfig {
    static let tradition: Tradition = .hindi
    static let defaultTheme: Theme = .banarasPothi
    static let mantra: Mantra = .ramOrSitaramSubchoice
    static let allowMantraSubchoice = true
    static let templeDestination: TempleDestination = .ramNaamBank
    static let appName = "Likhita Ram"
    static let practiceName = "Ram Naam Lekhan"
    static let bundleId = "org.likhita.ram"
    static let foundationURL = "https://likhita.org"
}
```

The shared packages read from `AppConfig` to skin behavior. No conditionals scattered through code.

---

## 17. Backend Architecture

### Stack

| Layer | Choice |
|---|---|
| Hosting | **Vercel** |
| Framework | **Next.js 16** (App Router, Route Handlers) |
| Runtime | **Vercel Functions** (Node.js for most; Edge for stateless lookups) |
| Database | **Neon Postgres** (serverless, free tier OK for v1) |
| ORM | **Drizzle ORM** (lightweight, TS-native) |
| Object storage | **Vercel Blob** (book PDFs, completion photos, receipt scans) |
| Cache | **Vercel Runtime Cache** (theme metadata, milestone art) |
| Auth | **Clerk** (Vercel Marketplace integration) — Sign in with Apple primary |
| Payments | **Stripe** (USD, Apple IAP via StoreKit 2 server validation) + **Razorpay** (INR for direct purchases) |
| Email | **Resend** (transactional: confirmations, completion notifications) |
| Push | **Apple Push Notification service** via Vercel Function + APNs HTTP/2 |
| Queue | **Inngest** (Vercel Marketplace) — print/ship pipeline orchestration |
| Analytics | **PostHog** (server-side events for funnels) |
| Monitoring | **Sentry** + Vercel Observability |

### Subdomains

```
likhita.org                    → foundation home, transparency portal, donations
likhita.org/transparency       → live audited financials + ops reports
likhitarama.org                → marketing landing (Telugu app)
likhitaram.org                 → marketing landing (Hindi app)
api.likhita.org                → shared API (X-App-Origin distinguishes callers)
admin.likhita.org              → ops dashboard (print/ship management)
account.likhita.org            → web account dashboard (cross-app history)
```

### Domains owned by the foundation

All registered to **Likhita Foundation** (Section 8 Co. India + 501(c)(3) US):

| Domain | Purpose |
|---|---|
| `likhita.org` `likhita.app` `likhita.com` | Foundation primary (`.org` = canonical) |
| `likhitarama.org` `likhitarama.app` | Telugu app marketing |
| `likhitaram.org` `likhitaram.app` | Hindi app marketing |
| `likhitafoundation.org` | Redirect to likhita.org |
| `likhitatrust.org` | Defensive registration |

### Key API behavior

- All requests require `X-App-Origin` header (`rama-koti` or `ram-naam-lekhan`)
- Auth via Clerk JWT in `Authorization` header
- Idempotency via client-generated `Idempotency-Key` on entry submissions (handles retries safely)
- All write endpoints are server-authoritative — counter never trusts client state
- Rate limiting: 4 entries/sec per user, 100 entries/sec per IP

---

## 18. Data Model

```sql
-- USERS
users (
  id              UUID PK
  clerk_id        TEXT UNIQUE NOT NULL
  name            TEXT NOT NULL
  gotra           TEXT
  native_place    TEXT
  email           TEXT NOT NULL
  phone           TEXT
  ui_language     TEXT  -- 'te' | 'hi' | 'en'
  primary_app     TEXT  -- 'rama_koti' | 'ram_naam_lekhan'
  linked_apps     TEXT[]  -- both, if user installed both
  created_at      TIMESTAMPTZ
)

-- KOTIS (one user can have many; only one active per app at a time in v1)
kotis (
  id                       UUID PK
  user_id                  UUID FK -> users.id
  app_origin               TEXT  -- 'rama_koti' | 'ram_naam_lekhan'
  tradition_path           TEXT  -- 'telugu' | 'hindi_ram' | 'hindi_sitaram'
  mantra_string            TEXT  -- 'srirama' | 'ram' | 'sitaram'
  rendered_script          TEXT  -- 'telugu' | 'devanagari'
  input_mode               TEXT  -- 'romanized' (v1)
  mode                     TEXT  -- 'trial' | 'lakh' | 'crore' | etc.
  target_count             BIGINT
  current_count            BIGINT DEFAULT 0
  stylus_color             TEXT  -- hex
  stylus_signature_hash    TEXT
  theme                    TEXT  -- theme key
  dedication_text          TEXT
  dedication_to            TEXT
  started_at               TIMESTAMPTZ
  completed_at             TIMESTAMPTZ
  locked                   BOOLEAN DEFAULT TRUE
  ship_temple              BOOLEAN DEFAULT FALSE
  temple_destination       TEXT  -- 'bhadrachalam' | 'ram_naam_bank' | 'ayodhya'
  ship_home                BOOLEAN DEFAULT FALSE
  shipping_address         JSONB
  payment_id               TEXT  -- Stripe/Razorpay reference
  printed_at               TIMESTAMPTZ
  shipped_at               TIMESTAMPTZ
  delivered_at             TIMESTAMPTZ
  photo_url                TEXT
  receipt_url              TEXT
)

-- ENTRIES (every individual mantra commit)
entries (
  id                  UUID PK
  koti_id             UUID FK -> kotis.id
  sequence_number     BIGINT  -- 1..target_count
  committed_at        TIMESTAMPTZ
  cadence_signature   TEXT  -- hash of keystroke timing
  client_session_id   UUID
  flagged             BOOLEAN DEFAULT FALSE  -- soft anti-cheat flag
  CONSTRAINT unique_seq UNIQUE (koti_id, sequence_number)
)

-- INDEXES
CREATE INDEX entries_koti_seq ON entries(koti_id, sequence_number);
CREATE INDEX kotis_user ON kotis(user_id);

-- SHIP BATCHES (quarterly ops batches)
ship_batches (
  id                     UUID PK
  batch_quarter          TEXT  -- '2026-Q3'
  temple_destination     TEXT
  status                 TEXT  -- 'pending' | 'printed' | 'in_transit' | 'delivered' | 'photographed' | 'closed'
  representative_id      UUID
  trip_started_at        TIMESTAMPTZ
  trip_completed_at      TIMESTAMPTZ
  photos_url             TEXT  -- group photo of batch
  receipt_url            TEXT  -- batch receipt
)

koti_ship_batches (
  koti_id                UUID FK -> kotis.id
  batch_id               UUID FK -> ship_batches.id
  position_in_batch      INT
  individual_photo_url   TEXT
  individual_receipt_url TEXT
  PRIMARY KEY (koti_id, batch_id)
)

-- PAYMENTS
payments (
  id              UUID PK
  user_id         UUID FK
  koti_id         UUID FK
  provider        TEXT  -- 'stripe' | 'razorpay' | 'apple_iap'
  provider_id     TEXT
  amount_cents    INT
  currency        TEXT  -- 'usd' | 'inr'
  type            TEXT  -- 'ship_temple' | 'ship_home' | 'ship_both' | 'theme' | 'stylus_pack' | 'ayodhya_upgrade'
  status          TEXT  -- 'pending' | 'completed' | 'refunded'
  created_at      TIMESTAMPTZ
)

-- DEVICES (for push notifications)
devices (
  id              UUID PK
  user_id         UUID FK
  apns_token      TEXT
  app_origin      TEXT  -- which app this token is for
  created_at      TIMESTAMPTZ
)
```

---

## 19. API Surface

All endpoints under `https://api.likhita.org/v1/`. Auth: `Bearer <clerk_jwt>`. Required header: `X-App-Origin: likhita-rama | likhita-ram`.

### Auth
- `POST /v1/auth/sync` — sync Clerk user → upsert into `users` table

### Kotis
- `POST /v1/kotis` — create new koti (sankalpam complete)
- `GET /v1/kotis` — list current user's kotis (filtered by X-App-Origin in v1)
- `GET /v1/kotis/:id` — fetch single koti with progress
- `POST /v1/kotis/:id/affirm` — re-affirmation pledge after long gap

### Entries
- `POST /v1/kotis/:id/entries` — submit batch of entries (5–25 at a time)
  - Body: `{ entries: [{ sequence_number, committed_at, cadence_signature }], idempotency_key }`
  - Returns: `{ accepted: N, current_count, milestone_unlocked: bool, milestone_label }`
- Server validates: cadence entropy, sequence continuity, rate limit, signature drift

### Stylus
- `POST /v1/stylus/calibrate` — submit 5-stroke calibration → returns signature hash

### Themes
- `GET /v1/themes` — list themes available for X-App-Origin
- `POST /v1/themes/:key/purchase` — purchase premium theme

### Shipping
- `POST /v1/kotis/:id/ship` — initiate ship flow with payment intent
- `GET /v1/kotis/:id/ship/status` — current pipeline status

### Payments
- `POST /v1/payments/stripe/webhook` — Stripe webhooks
- `POST /v1/payments/razorpay/webhook` — Razorpay webhooks
- `POST /v1/payments/apple/verify` — Apple StoreKit 2 server validation

### Admin (admin.likhita.org, separate auth)
- `GET /admin/v1/batches` — pending shipments
- `POST /admin/v1/batches/:id/print` — mark batch as printed
- `POST /admin/v1/batches/:id/photograph` — upload photo + receipt
- `POST /admin/v1/batches/:id/close` — finalize, trigger user notifications

---

## 20. Design Briefs (for Claude Code)

This section is the design contract for Claude Code to build the visual app.

### 20.1 Visual language

**Both apps share these principles:**
- Sacred space, not gamified — no XP bars, no badges, no streaks UI on the writing surface
- Generous whitespace — the practice is the focus, the chrome is invisible
- Slow, considered animations — nothing snappy or playful
- Indian aesthetic, not generic "spiritual" — temple architecture, palm-leaf manuscripts, cloth bookbinding
- Dignified typography — serif/manuscript fonts for rendered mantras; sans for UI chrome
- Haptics: rare and meaningful (entry commit = single soft tap; milestone = long warm rumble; completion = sustained complex pattern)

### 20.2 Color palettes

**Likhita Rama (Bhadrachalam Classic):**
```
Primary brand:     #8B0000  Deep red (cloth)
Accent:            #D4AF37  Gold foil
Surface:           #FFF8DC  Cream page
Surface alt:       #F5E6C8  Aged cream
Ink default:       #E34234  Vermillion
Text primary:      #2C1810  Dark sepia
Text secondary:    #6B4423  Medium sepia
Success:           #5F8A3F  Tulsi green
Error:             #8B2500  Brick red
```

**Likhita Ram (Banaras Pothi):**
```
Primary brand:     #FF7722  Saffron
Accent:            #D4AF37  Gold foil
Surface:           #F5E6D3  Handmade paper cream
Surface alt:       #EDD9B8  Aged tan
Ink default:       #1C1C1C  Lamp-black
Text primary:      #2C1810  Dark sepia
Text secondary:    #5C4033  Brown
Success:           #FFA500  Marigold
Error:             #8B2500  Brick red
```

### 20.3 Typography

| Use | Telugu app | Hindi app |
|---|---|---|
| Display (large headings) | Tiro Telugu | Tiro Devanagari Hindi |
| Body (UI chrome) | Anek Telugu | Mukta |
| Mantra rendering (in book) | Tiro Telugu | Tiro Devanagari Hindi |
| English fallback | Inter | Inter |

Tiro fonts are designed by Indian Type Foundry / Google specifically for sacred manuscripts — palm-leaf-friendly proportions.

### 20.4 Screen-by-screen brief

#### S1. Splash (~2s)
- Full-bleed temple silhouette (Bhadrachalam / Varanasi ghats)
- App logotype centered, fading in
- A single distant temple bell sound (optional, off if user has audio off in iOS settings)
- No tagline; the visual is enough

#### S2. Auth (Sign in with Apple primary)
- Centered Sign in with Apple button
- Below: small "Other ways to sign in" link → email magic-link
- Background: subtle theme-default cover texture, blurred
- Privacy + Terms links at footer

#### S3. Sankalpam — Identity (Step 1)
- Header: "Begin your sankalpam" / "अपना संकल्प आरंभ करें" / "మీ సంకల్పాన్ని ఆరంభించండి"
- Form: name, gotra (optional), native place (optional), email, phone
- Footer: "Continue" button, full-width, gold accent
- Visual: a thin gold line separates header from form (like a temple banner)

#### S4. Sankalpam — Dedication (Step 2)
- Header: "Why are you writing this koti?" (translated)
- Large multi-line input (max 280 chars, char counter)
- Below: "Dedicate to..." picker (self / parent / child / departed / deity / community)
- Bottom: "Continue"

#### S5. Sankalpam — Mode (Step 3)
- 6 cards in a vertical scrolling list
- Each card: mode name + count + estimated duration + small glyph (lakh = lotus; crore = cosmic chakra)
- "Lakh" highlighted as default with a subtle gold border
- Crore tap → consent confirmation sheet

#### S6. Sankalpam — Stylus Calibration (Step 4)
- Top half: 12 ink swatches in a 4x3 grid; tap to select; selected one pulses
- Bottom half: input field with prompt "Type your mantra 5 times to calibrate"
- After each successful entry, a small checkmark appears (5 dots filling)
- Animated preview of how the user's stylus will render shown above input

#### S7. Sankalpam — Theme (Step 5)
- Horizontal carousel of theme cards with cover art previews
- Each card: theme name, "Free" or "₹199" badge, full cover preview
- Tap to select; locked-in indicator below
- "Continue" appears once selected

#### S8. Sankalpam — Affirmation (Step 6)
- Full-screen, dimmed
- Pledge text in elegant theme font, centered
- User's dedication interpolated into the pledge
- Bottom: a long horizontal "Hold to begin" button — must press for 2s; haptic builds during press; on release with full hold, pledge fades and writing surface appears
- Below the button: small "Read again" link

#### S9. Writing Surface (the core experience)
- **iPhone:**
  - Top bar (44pt): counter `42,317 / 1,00,000` left; current Ramayana milestone badge right (tappable → full path view)
  - Center: book page filling most of the screen, entries grid filling top-down
  - Bottom (~120pt): single input field, tiny audio toggle button, tiny pause button
- **iPad:**
  - Two-page spread filling 80% of screen
  - Right rail: Ramayana progress path SVG (always visible)
  - Bottom: input field
- Page-turn animation: subtle, ~600ms, with paper flutter sound (off by default)
- Idle state: gentle ink pulse on the cursor, page texture slightly breathes

#### S10. Ramayana Path (full-screen, modal on iPhone, side rail on iPad)
- SVG illustrated map of Rama's journey: 7 nodes connected by a curved path
- Nodes are stylized icons (palace, forest, river, bridge, fortress)
- Current node pulses; passed nodes are gold-filled; future nodes are outlined
- Tap a node → shloka audio + brief description
- Bottom: progress bar `42% complete`

#### S11. Milestone Unlock (transient overlay, ~5s)
- Half-screen takeover from bottom
- Milestone illustration animates in
- Label in user's language: "You have reached Chitrakoot / చిత్రకూటం / चित्रकूट"
- Shloka audio plays (skippable with tap)
- Auto-dismisses; user returns to writing surface

#### S12. Completion — Pattabhishekam (full-screen, ~30s)
- Lottie animation: gates open, Rama returns, coronation
- User's stats overlay in elegant lower-third
- Final shloka plays
- "Continue to your book →" button at end

#### S13. Completion — Book Preview
- Scrollable, vertical, full-screen
- Cover → frontispiece → dedication → 4-page sample → colophon
- Each page rendered with theme + actual user entries
- Header: "Your completed Rama Koti" with name
- Footer button: "Choose what's next →"

#### S14. Ship Decision
- 3 large ornate cards in a vertical list (or horizontal carousel on iPad)
- Each card: option name, price (INR + USD shown side by side), illustration
- Tap → confirmation sheet with full pricing breakdown + estimated dates
- Apple Pay / StoreKit 2 sheet for purchase

#### S15. Ship Status (post-purchase)
- Timeline visual: "Printing → In Transit → At Temple → Photographed → Receipt Mailed"
- Current step glows in gold; passed steps are filled
- Estimated date next to each step
- Push notification preview: "When your book reaches the temple, we'll let you know."

#### S16. Settings
- Account (name, email, sign out)
- Notifications (push + email toggles)
- Audio (Off / Soft / Full + track picker)
- Themes (purchased + lock indicator on locked-in koti theme)
- Past kotis (list of completed kotis with dates)
- About (version, privacy, terms, contact)

### 20.5 Animation principles

- Page turns: 600ms easeInOut, with subtle vertical jitter
- Mantra entry commit: 200ms ink-bleed + scale 1.0 → 0.98 → 1.0
- Milestone unlock: 1.2s reveal with shloka audio start
- Completion ceremony: 30s Lottie, prefer a hand-illustrated style (commission an Indian illustrator)
- Loading states: a slowly rotating chakra or trishul (theme-appropriate)

### 20.6 Accessibility

- Dynamic Type supported on all UI chrome
- Mantra glyphs scale with Dynamic Type
- VoiceOver labels for all interactive elements
- High contrast mode override (cream → white, ink darkens)
- Audio always optional; never required
- Haptics can be disabled in iOS Settings (system-level honored)

---

## 21. v1 Scope

### Backend v1 (3 weeks)

✅
- Auth (Clerk Sign in with Apple)
- User + koti + entries CRUD with full anti-cheat
- Theme + payment + shipping endpoints
- Admin dashboard (basic — list batches, mark statuses, upload photos)
- Webhooks for Stripe + Razorpay + Apple IAP
- Push notifications (APNs)
- Ops queue for print/ship pipeline (Inngest)

❌ Not in v1
- Family koti, daily-streak mode, custom counts
- Native script input
- Cross-app analytics dashboards

### Likhita Rama app v1 (4 weeks, parallel to backend)

✅
- Full sankalpam flow (steps 1–6, no Step 0)
- Bhadrachalam Classic theme only
- Romanized input (`srirama` → `శ్రీరామ`)
- Modes: Trial, Lakh, Crore
- Writing surface + anti-cheat client-side
- Ramayana progress path (Telugu labels)
- Completion ceremony + book preview
- Ship to Bhadrachalam OR home OR both
- Settings, account, past kotis

❌ Not in v1
- Other Telugu themes (Palm-leaf, Tirupati)
- Audio library
- Native script keyboard
- iPad-optimized layout (universal app, but iPhone-first; iPad gets identical layout v1)

### Likhita Ram app v1 (4 weeks, parallel)

✅
- Step 0 mantra sub-choice (Ram / Sitaram)
- Full sankalpam flow
- Banaras Pothi theme only
- Romanized input (`ram` / `sitaram` → `राम` / `सीताराम`)
- Modes: Trial, Lakh, Crore
- Writing surface + anti-cheat
- Ramayana progress path (Hindi labels)
- Completion ceremony + book preview
- Ship to Ram Naam Bank Varanasi OR home OR both
- Settings, account, past kotis

❌ Not in v1
- Other Hindi themes (Ayodhya Sandstone, Tulsidas Manuscript)
- Ayodhya destination upgrade
- Audio library
- Native script keyboard

### Total v1 ship target: 6 weeks from kickoff

Week 1: Backend skeleton, Xcode project + targets, design system, theme assets
Week 2: Backend API complete, sankalpam flow built shared
Week 3: Writing surface + anti-cheat, progress path, theme rendering
Week 4: Completion + ship flow, payments, admin dashboard
Week 5: Polish, accessibility, internal testing, TestFlight beta to 50 users
Week 6: Bug fixes, App Store submission for both apps

---

## 22. Success Metrics (Mission, Not Revenue)

We are a non-profit. We do not measure success in revenue. We measure it in **practice supported and books delivered.**

### Primary mission metrics (90 days post-launch)

| Metric | Likhita Rama | Likhita Ram | Combined | Why it matters |
|---|---|---|---|---|
| **Books deposited at temple** | 60 | 90 | **150** | The end-to-end mission is complete only when a book reaches the temple |
| **Mantras written across all users** | 40M | 60M | **100M** | The aggregate sadhana enabled by the foundation |
| **Completed kotis** | 80 | 120 | 200 | Practitioners who finished what they started |
| **Active practitioners (30-day)** | 800 | 1,200 | 2,000 | Daily/weekly users actually practicing |
| **Free users served (no payment)** | — | — | majority | We exist for them |

### Secondary health metrics

| Metric | Target |
|---|---|
| App Store rating (both apps) | 4.7+ |
| NPS | 60+ |
| 30-day retention | 40% |
| Avg daily entries (active user) | 200 |
| Anti-cheat false-positive rate | <2% |
| Crash-free sessions | 99.5%+ |

### Financial transparency metrics

These are **published**, not targets — we do not optimize for them, just disclose them.

| Disclosure | Cadence |
|---|---|
| Total cost-recovery revenue collected | Monthly on transparency portal |
| Total costs incurred | Monthly |
| Surplus disbursed to temples | Quarterly with temple acknowledgment |
| Any deficits and how covered (donations / founder loans / loss carry) | Quarterly |
| Audited annual report | Annually, by April 30 of following FY |

### Anti-metrics (we explicitly do NOT optimize)

- ❌ Average revenue per user (ARPU)
- ❌ Lifetime value (LTV)
- ❌ Conversion rate to paid tiers (we have no paid tiers)
- ❌ Engagement minutes (we want users to write the mantra and put the phone down)
- ❌ Push notification open rate
- ❌ Streaks held / maintained (we don't gamify practice)

---

## 23. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| "Digital writing isn't real sadhana" backlash | Lead with stylus calibration + anti-cheat narrative; show physical book outcome; get formal endorsement from Bhadrachalam priests + a Varanasi mahant before launch |
| Anti-cheat false positives frustrate elderly users | Generous thresholds; only soft lockouts (no hard bans); human review queue with 24hr SLA |
| Bhadrachalam temple won't accept printed digital books | **VALIDATE BEFORE BUILDING.** Get written approval from temple authorities. If rejected, pivot to ship-to-home only and seek alternate Telangana/AP Rama temple. |
| Ram Naam Bank won't accept printed digital books | Same — validate before launch. Ram Naam Bank is the primary diaspora destination but Ayodhya partner is a backup. |
| Apple rejects either app | Likely concerns: religious content (low risk — Apple allows this), in-app purchases for "religious services" (frame as printing service, not religious commerce), localization quality (test thoroughly). Have clear App Review notes ready. |
| Print quality complaints | Use top-tier Hyderabad press; preview before print; full refund if defective; build a feedback loop with first 50 books |
| Two apps means 2x marketing effort | Start with Telugu app launch (smaller, easier audience); learn; launch Hindi app 4-8 weeks later if warranted |
| Crore mode users never complete | Family mode (v2) lets households share the load; lifetime stat is meaningful even if incomplete; we don't punish non-completion |
| Cross-cultural concerns about commercializing devotion | All temple shipping fees pass through cost transparently; offer fee waivers for verified low-income users; donate a portion of theme purchases to temple maintenance funds |
| Scale: 1 crore entries × 1000 users = 10 billion rows | Use Postgres partitioning by `koti_id`; archive completed kotis to cold storage; v1 is fine on Neon free tier (~10M rows max realistic v1) |

---

## 24. Open Questions

1. **Bhadrachalam approval** — has anyone formally checked with the temple that printed digital Rama Koti books are accepted in the Mandapam? **Action item before any code.**
2. **Ram Naam Bank approval** — same question for Varanasi. Need to identify the right contact (Sri Satua Baba Ashram / Ramanandacharya office). **Action item before any code.**
3. **Foundation registration timeline** — Section 8 Co. takes 2–4 weeks in India; 501(c)(3) takes 3–12 months in US. Can apps launch under "Likhita Foundation (registration in progress)" disclosure? *Likely yes; consult lawyer.*
4. **Founder/trustee structure** — minimum 2 directors for Section 8; 3 for 501(c)(3). Who else joins as trustees?
5. **Print partners** — Hyderabad press for both apps initially? Or split? Need quotes for 666-page book and 66,666-page multi-volume crore book. **Should select non-profit-friendly partners willing to accept thin-margin work.**
6. **Native-script input (v2)** — when do we add the on-screen syllable keyboard? Likely after we see what % of users complain about romanized input.
7. **Cross-app accounts** — should signing in to Likhita Rama automatically pull a user's Likhita Ram kotis into the account view, or keep them strictly separate per app? *Decision: separate within each app's UI, unified in web account dashboard at account.likhita.org.*
8. **Apple IAP vs direct payment for shipping** — Apple may classify shipping as digital good (IAP, 15-30% cut) or physical good (out-of-app, 0% cut). Get App Review pre-approval. Likely physical good → can use Razorpay/Stripe web checkout to avoid Apple cut, but must comply with anti-steering rules per region.
9. **Crore mode multi-volume binding** — at 66,666 pages, this is multi-volume. Pricing? Storage at temple? Likely 10 volumes of ~6,666 pages each. Re-validate with temple authorities (does Bhadrachalam Mandapam have shelf space?).
10. **Refunds** — if temple rejects a book post-print, full refund + we keep book record. If user requests refund mid-koti, no refund (work was done, cost was incurred). Documented in Terms.
11. **Donation legal** — are voluntary donations subject to GST (India) or sales tax (US states)? Likely no for registered non-profits, but confirm with CA + tax counsel.
12. **Trademark** — file "Likhita Foundation," "Likhita Rama," "Likhita Ram" with USPTO and Indian Trademark Registry before public launch.
13. **Apple Developer account ownership** — should be in Likhita Foundation's name, not founder's personal name, once 501(c)(3) registers (Apple supports non-profit developer accounts with discount). Until then, founder personal account with assignment-on-formation clause.

---

## 25. Next Steps

### Phase 0 — Foundation formation (Weeks -4 to 0, before any code)

0a. **Engage non-profit attorneys** — one in India (Section 8 Co.), one in US (501(c)(3)).
0b. **File Section 8 Company** with MCA India — Likhita Foundation. Identify 2+ directors, draft MOA + AOA. ~2–4 weeks for incorporation; 80G/12A registration follows over 1–3 months.
0c. **File 501(c)(3)** with IRS (Form 1023 or 1023-EZ if eligible) — Likhita Foundation Inc. Identify 3+ directors. ~3–12 months for determination letter.
0d. **Open foundation bank accounts** — India (after Section 8 reg) and US (after EIN, before determination letter).
0e. **Trademark filings** — USPTO + Indian Trademark Registry: "Likhita Foundation," "Likhita Rama," "Likhita Ram," and the foundation logo.

### Phase 1 — Validation (parallel with Phase 0)

1. **Validate Bhadrachalam temple acceptance** — formal written approval from temple trust office, on letterhead. Visit in person if possible.
2. **Validate Ram Naam Bank Varanasi acceptance** — identify the right office (Sri Satua Baba Ashram / Ramanandacharya lineage), get written approval.
3. **Scope print costs** — quotes from 3 Hyderabad presses + 1 Varanasi press, with a "non-profit pricing" ask (most presses honor this for religious org). Cover: (a) 666-page cloth-bound gold-foil book, (b) 66,666-page multi-volume crore version.
4. **Apple Developer registration** — open Apple Developer account in **Likhita Foundation Inc.** (US) name once 501(c)(3) is filed (Apple's Non-Profit Developer Discount available). Until then, founder personal account with formal written assignment to foundation upon registration. Reserve `org.likhita.rama` and `org.likhita.ram` bundle IDs.
5. **Domain registration** — purchase `likhita.org`, `likhita.app`, `likhita.com`, `likhitarama.org`, `likhitaram.org`, plus defensive registrations (`likhitafoundation.org`, `likhitatrust.org`). Total cost ~$80–120/year. Register under foundation name once incorporated; founder name temporarily, with assignment.

### Phase 2 — Design (Weeks 0–1)

6. **Claude Code designs the two themes** (Bhadrachalam Classic + Banaras Pothi) — full SwiftUI theme packages: covers, page textures, ornaments, milestone illustrations, app icons, splash screens.
7. **Lottie animations** commissioned: Pattabhishekam ceremony, milestone unlocks, page turns. Find an Indian illustrator (Behance/Dribbble Hindu art tag).
8. **Marketing landing pages** — `likhita.org` (foundation home + transparency portal), `likhitarama.org`, `likhitaram.org`.
9. **Audio sourcing** — license-free recordings from public domain (most Tyagaraja kritis, Tulsidas Ramcharitmanas are PD); commission temple-recorded background loops (v2; not in v1).

### Phase 3 — Build (Weeks 1–6)

10. Backend skeleton (Vercel + Neon + Clerk + Drizzle + Inngest + Razorpay/Stripe webhooks)
11. Xcode project + 2 targets + 4 Swift packages scaffolded via xcodegen
12. Sankalpam flow (shared package, Hindi sub-choice in LikhitaRam target)
13. Writing surface + anti-cheat (the hardest engineering)
14. Progress path + completion ceremony
15. Ship flow + payments + Apple-tax disclosure banner
16. Admin dashboard (Next.js)
17. **Transparency portal** at `likhita.org/transparency` — live financials, ops reports
18. TestFlight beta with 100 hand-picked users (50 Telugu + 50 Hindi)

### Phase 4 — Launch (Weeks 6–8)

19. App Store submission for both apps under foundation Apple Developer account (parallel)
20. **Soft launch** to mailing lists:
    - Telugu: NATA, ATA, Telugu Association of North Texas, /r/Andhra, US Telugu temples
    - Hindi: BAPS Mandirs, Sanatan groups, /r/India, /r/Hindu, Vishwa Hindu Parishad of America chapters
21. First quarterly Bhadrachalam + Varanasi temple trip planned for ~12 weeks post-launch (allow time for first batch of completions)
22. **First annual transparency report** drafted at end of Year 1; published with audit.

---

### Action items already completed (this session)

✅ **Competitor research** — 3 existing apps identified (RamaKoti, Ramnaam Book, Likhita Japa); weaknesses documented in §4
✅ **Domain availability check** — 14 domains verified available via live whois (recommended set above)
✅ **Naming decision** — "Likhita Foundation" + "Likhita Rama" + "Likhita Ram" — sanctity-preserving, distinct, brandable, non-profit-feeling
✅ **Differentiation matrix** — §4 with feature-level comparison vs all 3 competitors
✅ **Non-profit positioning anchored** — §0 Mission + §14 Cost-Recovery + §15 Trust & Transparency + §22 Mission Metrics
✅ **Legal structure decided** — Section 8 Co. (India) + 501(c)(3) (US)
✅ **Spec rewrite complete** — this document, ready for Claude Code to design from

### Design phase (Week 0–1, before scaffolding)

6. **Claude Code designs** the two themes (Bhadrachalam Classic + Banaras Pothi) — full SwiftUI theme packages: covers, page textures, ornaments, milestone illustrations, app icons, splash screens.
7. **Lottie animations** commissioned: Pattabhishekam ceremony, milestone unlocks, page turns.
8. **Audio sourcing** — license-free recordings from public domain or commission (v2; not in v1).
9. (covered above in Phase 2 step 8 — `likhita.org`, `likhitarama.org`, `likhitaram.org`)

### Build phase (Week 1–6)

10. Backend skeleton (Vercel + Neon + Clerk + Drizzle)
11. Xcode project + targets + Swift packages scaffolded via xcodegen
12. Sankalpam flow (shared package)
13. Writing surface + anti-cheat (the hardest engineering)
14. Progress path + completion ceremony
15. Ship flow + payments
16. Admin dashboard (Next.js)
17. TestFlight beta with 50+50 hand-picked users

### Launch (Week 6–8)

18. App Store submission for both apps (parallel)
19. Soft launch to mailing lists: Telugu Associations (NATA, ATA), Hindu Mandirs in NJ/CA/TX, /r/Andhra, /r/India, /r/Hyderabad
20. Quarterly Bhadrachalam + Varanasi trip planned for first batch of completions

---

## Appendix A: Glossary

- **Sankalpam** (సంకల్పం / संकल्प): a vow or solemn intent declared at the start of a ritual.
- **Likhit Japa** / **Likhit Naam Jap** (लिखित जप): "written chanting" — reciting a name/mantra by writing it.
- **Rama Koti** (రామ కోటి): "a crore (10 million) of Ramas" — South Indian written-japa tradition.
- **Ram Naam Lekhan** (राम नाम लेखन): "writing of Rama's name" — North Indian equivalent.
- **Ram Naam Bank** (राम नाम बैंक): the institution in Varanasi, est. 1926, that accepts deposits of Ram-name notebooks.
- **Bhadrachalam**: town in Telangana on the Godavari river; site of the Sri Sita Ramachandra Swamy Temple, with a famous Rama Koti Mandapam.
- **Pattabhishekam** (పట్టాభిషేకం / पट्टाभिषेक): coronation ceremony; in the Ramayana, refers to Rama's coronation upon return to Ayodhya.
- **Pothi** (पोथी): traditional bound religious manuscript.
- **Mandapam** (మండపం / मंडप): pillared hall at a temple where rituals are performed.

---

## Appendix B: References

- Bhadrachalam temple — https://bhadrachalarama.org
- Ram Naam Bank Varanasi — search "Ram Naam Bank Varanasi" for news articles (Times of India, The Hindu have covered it)
- Tiro fonts — https://github.com/googlefonts/tiro
- Likhit Japa tradition — Hindu manuscript culture references in Indology literature
- Anti-cheat patterns — keystroke biometrics literature (KeyTrac, BehavioSec papers)

---

*Sri Rama Jayam. राम राम राम. శ్రీరామ జయం.*
