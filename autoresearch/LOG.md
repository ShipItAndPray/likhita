# Likhita Marketing Copy — Autoresearch Log

Karpathy-style autoresearch. One change at a time. Score against 10-point rubric.
Keep improvements. Discard regressions. Stop early at 10/10 stable.

## Rubric (binary, 1 pt each)

1. NONPROFIT — Mentions or implies non-profit / at-cost
2. PHYSICAL — Mentions physical temple delivery
3. PROOF — Mentions photo + receipt back
4. TEMPLE — Names a public traditional temple (Bhadrachalam OR Ram Naam Bank Varanasi)
5. NOT-COUNTER — Distinguishes from counter apps (without naming competitors)
6. SANCTITY — No commercial language (no "buy", "premium", "deal", "save")
7. CONSTRAINT — Hits stylistic constraint (hero ≤12 words; pledge ≤50 words; ASC structured)
8. SANSKRIT — Uses likhita / sankalpam / koti / japa / naam respectfully
9. SKEPTICISM — Addresses skepticism toward digital sadhana
10. FOUNDATION — Names Likhita Foundation

---

# CATEGORY 1: ONBOARDING PLEDGE (English)

Target: spec §5 step 6 "Affirmation Pledge" — the English version (Telugu/Hindi already exist).
Constraint: ≤50 words. Spoken in first person. Sanctity-preserving. Sankalpam not signup.

Note on rubric for pledge: pledge is internal to onboarding, AFTER user already chose Likhita.
Foundation/non-profit/temple naming may not all fit — but skepticism, sankalpam, no-shortcut,
and dedication to a tradition + temple are essential. Score adjusted for context where rubric
items don't apply (those will be marked N/A and not penalized; max effective score noted).

## Round 1: Initial 5 candidates

### P1.1
> "I begin this Likhita koti as a sankalpam, not a task. I will write each name with my own hand, take no shortcut, accept no autofill. This book will travel from my screen to a temple deposit. I commit to the practice. Sri Rama jayam."

Score: NONPROFIT 0, PHYSICAL 1, PROOF 0, TEMPLE 0, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1 (49 words), SANSKRIT 1, SKEPTICISM 1, FOUNDATION 0 = **6/10**
Notes: Strong on sankalpam/no-shortcut. Misses temple name, foundation, proof.

### P1.2
> "I take this sankalpam under Likhita Foundation. Each koti name written by my hand, no paste, no macro. The printed book will reach Bhadrachalam (or Ram Naam Bank Varanasi). I will receive its photo and stamped receipt. This is my vow. Sri Rama jayam."

Score: NONPROFIT 0, PHYSICAL 1, PROOF 1, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 0 (51 words), SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **8/10**
Notes: 51 words — over limit by 1. Otherwise strong. Lacks at-cost/non-profit language.

### P1.3
> "Sankalpam, not signup. I begin this koti by my own hand. No paste. No macro. Likhita Foundation will print and deliver this book to a public temple. A photo and stamped receipt return to me. This is sadhana, not a counter."

Score: NONPROFIT 0, PHYSICAL 1, PROOF 1, TEMPLE 0, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1 (43 words), SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **8/10**
Notes: Very tight. Names Foundation. Calls out "not a counter" plainly. Misses temple by name.

### P1.4
> "I take this sankalpam. Every name written by my hand — no paste, no autofill, no shortcut. Likhita Foundation, at no profit, will print this book and deposit it at Bhadrachalam or Ram Naam Bank Varanasi. A photo and stamped receipt return. Sri Rama jayam."

Score: NONPROFIT 1, PHYSICAL 1, PROOF 1, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 0 (49 words — OK; recount: 47 words), SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **10/10** (recount confirms 47)
Notes: Recount: "I/take/this/sankalpam/Every/name/written/by/my/hand/no/paste/no/autofill/no/shortcut/Likhita/Foundation/at/no/profit/will/print/this/book/and/deposit/it/at/Bhadrachalam/or/Ram/Naam/Bank/Varanasi/A/photo/and/stamped/receipt/return/Sri/Rama/jayam" = 44 words. UNDER 50. **10/10**

### P1.5
> "This is a sankalpam. I begin Likhita Japa with my own hand. No shortcut, no paste, no macro. The Likhita Foundation, a non-profit, will print and ship my completed book to a public temple. A photo and stamped receipt come back to me."

Score: NONPROFIT 1, PHYSICAL 1, PROOF 1, TEMPLE 0, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1 (44 words), SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **9/10**

**Round 1 winner: P1.4 (10/10)** — already hit ceiling.

## Round 2: Validate P1.4 with single-change mutations to test stability

### P1.4-M1 (replace "or" with explicit per-app)
> "I take this sankalpam. Every name written by my hand — no paste, no autofill, no shortcut. Likhita Foundation, at no profit, will print this book and deposit it at Bhadrachalam (Telugu) or Ram Naam Bank Varanasi (Hindi). A photo and stamped receipt return. Sri Rama jayam."

Score: All 10 still hit. 47 words. **10/10** — KEEP equivalent. P1.4 cleaner. DISCARD.

### P1.4-M2 (drop "Sri Rama jayam" to leave space for app-specific closer)
> "I take this sankalpam. Every name written by my hand — no paste, no autofill, no shortcut. Likhita Foundation, at no profit, will print this book and deposit it at Bhadrachalam or Ram Naam Bank Varanasi. A photo and temple-stamped receipt return to me."

Score: 10/10 with stronger "temple-stamped" + explicit "to me". 42 words.
**Verdict: TIE at 10/10, but slightly more precise. Replace P1.4 with M2. KEEP.**

### P1.4-M3 (add "as a vow" to make sankalpam meaning explicit for English readers)
> "I take this sankalpam — a vow. Every name written by my hand — no paste, no autofill, no shortcut. Likhita Foundation, at no profit, will print this book and deposit it at Bhadrachalam or Ram Naam Bank Varanasi. A photo and temple-stamped receipt return to me."

Score: 10/10. 45 words. SKEPTICISM stronger. **KEEP — makes "sankalpam" parseable for non-Sanskrit readers.**

### P1.4-M4 (add "for this koti" to bind the vow to the count)
> "I take this sankalpam — a vow for this koti. Every name written by my hand: no paste, no autofill, no shortcut. Likhita Foundation, at no profit, will print this book and deposit it at Bhadrachalam or Ram Naam Bank Varanasi. A photo and temple-stamped receipt return to me."

Score: 10/10. 47 words. Adds "koti" — second Sanskrit term, reinforces SANSKRIT pillar. **KEEP.**

### P1.4-M5 (try cutting "no autofill" since "no paste, no shortcut" covers it)
> "I take this sankalpam — a vow for this koti. Every name written by my hand: no paste, no shortcut. Likhita Foundation, at no profit, will print this book and deposit it at Bhadrachalam or Ram Naam Bank Varanasi. A photo and temple-stamped receipt return to me."

Score: 10/10. 45 words. Loses one anti-cheat specific. SPEC §7 explicitly bans paste, autofill, macros. Removing "autofill" weakens the no-shortcut promise. **DISCARD.** Stay with M4.

## Round 3: Stability test on M4 winner

### P1.4-M6 (active voice → first-person rhythmic)
> "I take this sankalpam — a vow for this koti. By my own hand: no paste, no autofill, no shortcut. Likhita Foundation will print this book at no profit and deposit it at Bhadrachalam or Ram Naam Bank Varanasi. A photo and temple-stamped receipt return to me."

Score: 10/10. 46 words. Slightly more rhythmic. Tied. KEEP.

### P1.4-M7 (try "Bhadrachalam Temple" for clarity to non-Indians)
> "I take this sankalpam — a vow for this koti. By my own hand: no paste, no autofill, no shortcut. Likhita Foundation will print this book at no profit and deposit it at Bhadrachalam Temple or Ram Naam Bank, Varanasi. A photo and temple-stamped receipt return to me."

Score: 10/10. 47 words. Clearer for diaspora users with limited Indian-temple geography. KEEP.

### P1.4-M8 (explicit "I" before sankalpam, drop em-dash)
Tested mentally — slight loss of poetic compression. DISCARD.

**Round 3 stable winner: P1.4-M7 (10/10, three rounds at ceiling).** STOP.

---

# CATEGORY 2A: APP STORE DESCRIPTION — Likhita Rama (Telugu app)

Constraint: 4000 chars max. Structure expected — hook, what is it, what makes it different,
what you get back, foundation note, transparency. App Store does not allow promo language.
Score against full rubric (10 max).

## Round 1: 5 initial candidates

### R1.1 — minimalist version
```
Likhita Rama is a digital home for Rama Koti — the South Indian practice of writing శ్రీరామ until you reach a lakh, or a crore.

It is not a counter. Each name you write is rendered in your personal stylus, locked at calibration. No paste, no autofill, no macros — the practice is real or it is nothing.

When your koti is complete, Likhita Foundation prints your work as a cloth-bound book and deposits it at the Sri Sita Ramachandra Swamy Temple, Bhadrachalam, in the Rama Koti Mandapam — the public traditional destination for completed Rama Koti for over a century. A photo of your specific book at the temple, and a temple-stamped receipt, are returned to you within 60 days.

Likhita Foundation is a non-profit. We charge only what it costs us — print, transport, temple coordination, servers. No ads. No data sales. No paid tiers. No engagement gamification. These are in our bylaws, not just our policy.

Open to all Hindu traditions. Sect-neutral. Audited annually. Open books at likhita.org/transparency.

This is sankalpam, not signup. The book is the proof.
```
Length: ~1,250 chars. Score: NONPROFIT 1, PHYSICAL 1, PROOF 1, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1 (structured), SANSKRIT 1 (likhita, koti, sankalpam), SKEPTICISM 1 (real or nothing), FOUNDATION 1 = **10/10**

### R1.2 — story-led
```
A koti — one lakh, or one crore — written one name at a time. By your hand, into your iPhone or iPad, in your own personal stylus.

Likhita Rama is not a counter app. Every శ్రీరామ you type is rendered in the ink color and cadence you calibrated on day one. No paste. No autofill. No macros. If you don't write it, it doesn't count.

When the koti is finished, your work is printed as a cloth-bound book by Likhita Foundation and physically deposited at Sri Sita Ramachandra Swamy Temple, Bhadrachalam — in the Rama Koti Mandapam where completed kotis have been kept for generations. You receive a photograph of your book at the temple and a temple-stamped receipt by post.

Likhita Foundation is a registered non-profit. Cost-recovery only — every rupee accounted for, audited annually, published at likhita.org/transparency. No ads, no data sales, no paid tiers, no engagement gamification. These are in our bylaws.

Sankalpam, not signup. Sadhana, not subscription.
```
~1,150 chars. Score: 10/10.
Tied with R1.1 but more poetic. Slight edge.

### R1.3 — feature-led
```
Write Sri Rama Koti on your iPhone or iPad. Likhita Rama is a sankalpam-based app for the Telugu Hindu diaspora to complete Rama Koti — 1 lakh or 1 crore mantras of శ్రీరామ — without losing the physical, sacramental tradition.

Personal stylus. You calibrate once; every entry renders in your own ink and cadence.
Anti-cheat. Server-validated keystrokes. No paste, no autofill, no macros.
Sankalpam onboarding. A vow ritual, not a signup form.
Tradition-faithful. Romanized typing of శ్రీరామ; rendered in Telugu script.

When your koti is complete, Likhita Foundation prints the book in cloth and gold and deposits it at the Sri Sita Ramachandra Swamy Temple, Bhadrachalam — in the Rama Koti Mandapam. You receive a photograph of your book at the temple and a temple-stamped receipt by mail within 60 days.

Likhita Foundation is a non-profit. Cost-recovery pricing. No ads. No data sales. No paid tiers. No engagement gamification. Audited annually; books at likhita.org/transparency.
```
~1,100 chars. Score: 10/10. Most scannable for ASC reviewers.

### R1.4 — short and sharp
```
Likhita Rama is the digital home of Rama Koti — śrīrāma written one lakh or one crore times, by your hand.

It is not a counter. Every శ్రీరామ is rendered in your personal stylus, locked at calibration. No paste. No autofill. No shortcuts. The practice is real or it is nothing.

When the koti is finished, Likhita Foundation prints your work as a cloth-bound book and deposits it at Bhadrachalam — Sri Sita Ramachandra Swamy Temple, Rama Koti Mandapam. You receive a photograph of your book at the temple and a temple-stamped receipt.

Likhita Foundation is a non-profit. At-cost pricing, audited yearly, books open at likhita.org/transparency. No ads. No data sales. No paid tiers. No engagement gamification. By bylaw.

Sankalpam, not signup.
```
~870 chars. Score: 10/10. Sharpest.

### R1.5 — addresses skeptic head-on
```
"Can a digital app honor a 2,000-year-old practice?"

Only if the practice is real. So we built Likhita Rama around it.

Every శ్రీరామ you write is typed by your hand on iPhone or iPad and rendered in your personal stylus — an ink color and cadence locked at calibration. No paste. No autofill. No macros. Server-validated. The practice is real or it is nothing.

When you complete your koti — 1 lakh, 1 crore — Likhita Foundation prints your work as a cloth-bound book and deposits it at the Sri Sita Ramachandra Swamy Temple, Bhadrachalam, in the Rama Koti Mandapam. You receive a photograph of your specific book at the temple and a temple-stamped receipt by post.

Likhita Foundation is a non-profit. Audited. At-cost. Open books at likhita.org/transparency. No ads. No data sales. No paid tiers. No engagement gamification. In our bylaws.

Open to all Hindu traditions. Sankalpam, not signup.
```
~1,000 chars. Score: 10/10. Strongest skepticism handling.

**Round 1 winner: R1.5 (10/10, strongest skepticism opener) — uses ASC's "first 3 lines" surface area best.**

## Round 2: Mutate R1.5

### R1.5-M1 — drop the rhetorical question (ASC reviewers may flag)
```
A 2,000-year-old practice deserves a real one — not a counter.

Likhita Rama is the digital home of Rama Koti...
```
Risk: Apple sometimes flags "deserves" as marketing puffery. But not commercial. Score: 10/10. Marginal.

### R1.5-M2 — add temple line for trust
After "Rama Koti Mandapam.", add: "where completed kotis have been deposited for generations." Score: 10/10. Adds heritage signal. KEEP.

### R1.5-M3 — replace "macros" with "no shortcuts of any kind"
Slight loss of specificity but gain of accessibility. Tied 10/10. KEEP. Actually, "macros, no shortcuts" — both work. Keep "no macros" for technical specificity.

### R1.5-M4 — fold transparency URL inline
Already inline. Skip.

### R1.5-M5 — add "Free app. No paid tiers. No upgrades." opener
Tested: feels App-Store-ish in wrong way. Apple language. Skip — loses sanctity edge.

**Round 2 winner: R1.5 + M2 (added heritage line).**

## Round 3: Final polish on R1.5+M2

Single change: replace "your specific book" with "your book" — already implied by context. Tighter.
Single change: ensure all bylaws line reads naturally.
Final scored 10/10. **STOP.**

---

# CATEGORY 2B: APP STORE DESCRIPTION — Likhita Ram (Hindi app)

Same structure as 2A but Hindi tradition: Ram Naam Lekhan, Varanasi, Ram or Sitaram.

## Round 1: 5 candidates

### H1.1
```
Likhita Ram is the digital home of Ram Naam Lekhan — the North Indian practice of writing राम (or सीताराम) one lakh or one crore times, by your hand.

It is not a counter. Every राम you type is rendered in your personal stylus — an ink color and cadence locked at calibration. No paste. No autofill. No macros. Server-validated. The practice is real or it is nothing.

When the koti is finished, Likhita Foundation prints your work as a cloth-bound book and deposits it at Ram Naam Bank, Varanasi — the public Ramnami repository established in 1926, where completed lekhan has been kept for generations. (Ayodhya available on request.) You receive a photograph of your book at the temple and a temple-stamped receipt by post.

Likhita Foundation is a non-profit. At-cost pricing. Audited annually. Open books at likhita.org/transparency. No ads. No data sales. No paid tiers. No engagement gamification. In our bylaws.

Open to all Hindu traditions. Sankalpam, not signup. Sadhana, not subscription.
```
~1,100 chars. Score: 10/10. Names Ram Naam Bank, est 1926, public repository — strong against Aniruddha's private bank without naming them.

### H1.2 — skeptic opener
```
"Can a digital app honor Ram Naam Lekhan?"

Only if the practice is real. So we built Likhita Ram around it.

Every राम (or सीताराम) you write is typed on iPhone or iPad and rendered in your personal stylus — ink color and cadence locked at calibration. No paste. No autofill. No macros. Server-validated. The practice is real or it is nothing.

When you complete your koti — 1 lakh, 1 crore — Likhita Foundation prints your work as a cloth-bound book and deposits it at Ram Naam Bank, Varanasi (established 1926, public Ramnami repository) or, on request, Ayodhya. A photograph of your book at the bank, and a stamped receipt, are returned to you by post.

Likhita Foundation is a non-profit. At-cost. Audited yearly. Open books at likhita.org/transparency. No ads. No data sales. No paid tiers. No engagement gamification. In our bylaws — not our policy.

Open to all Hindu traditions, sect-neutral. Sankalpam, not signup.
```
~1,030 chars. Score: 10/10. Strongest opener. Mirrors Rama version.

### H1.3 — sharp
```
Likhita Ram is the digital home of Ram Naam Lekhan — राम or सीताराम, written one lakh or one crore times, by your hand.

It is not a counter. Every name renders in your personal stylus, locked at calibration. No paste. No autofill. No macros. The practice is real or it is nothing.

When the lekhan is complete, Likhita Foundation prints your work as a cloth-bound book and deposits it at Ram Naam Bank, Varanasi — the public Ramnami repository, established 1926 (Ayodhya available on request). A photograph of your book at the bank and a stamped receipt return to you.

Likhita Foundation is a non-profit. At-cost. Audited. No ads, no data sales, no paid tiers, no engagement gamification — by bylaw. Open books at likhita.org/transparency.

Open to all Hindu traditions. Sect-neutral. Sankalpam, not signup.
```
~880 chars. Score: 10/10.

### H1.4 — emphasizes sect-neutrality strongly (counter to Aniruddha competitor)
Same as H1.1 with stronger early sect-neutral line. Test:
```
Likhita Ram is the digital home of Ram Naam Lekhan — open to every Hindu, in every tradition. Write राम or सीताराम one lakh or one crore times, by your hand...
```
Score: 10/10. The "every Hindu, every tradition" line is a soft jab at sect-tied competitor. Keeps sanctity. Strong.

### H1.5 — feature-led
Same structure as R1.3 but Hindi-side. Score: 10/10 but less differentiated than H1.2/H1.4.

**Round 1 winner: H1.2 (skeptic opener) + H1.4's sect-neutral line as a paragraph late in the desc.**

## Round 2: Combine winners

### H1.2-M1 — H1.2 with a sentence promoting sect-neutrality
Merge: insert "Open to every Hindu tradition — sect-neutral by bylaw." after "In our bylaws — not our policy." Score: 10/10. KEEP.

### H1.2-M2 — restore "1926" emphasis
Already there. Skip.

### H1.2-M3 — add a closing note that Likhita Ram and Likhita Rama share the same Foundation
Adds trust signal. Score 10/10 but adds chars. Keep optional.

**Round 2 winner: H1.2 + M1.**

## Round 3: Stability — final at 10/10. STOP.

---

# CATEGORY 3: MARKETING HERO

Constraint: ≤12 words. Three variants needed: likhita.org (foundation), likhitarama.org, likhitaram.org.
Note: at 12 words it is impossible to hit all 10 rubric items. Document tradeoffs.

## Round 1: 5 initial candidates per site (15 total)

### Foundation hero (likhita.org)

#### F1.1
> "A non-profit foundation for Likhita Japa — written by hand, deposited at the temple."
13 words. Constraint 0. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 0, NOT-COUNTER 0, SANCTITY 1, CONSTRAINT 0, SANSKRIT 1, SKEPTICISM 0, FOUNDATION 1 = **5/10**. Over by 1.

#### F1.2
> "Likhita Foundation: digital sadhana, printed at-cost, deposited at the temple."
10 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 0, NOT-COUNTER 0, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1 (sadhana), SKEPTICISM 1 (digital sadhana flagged), FOUNDATION 1 = **7/10**

#### F1.3
> "Sankalpam to temple deposit. Non-profit. By the Likhita Foundation."
9 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 0, NOT-COUNTER 0, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 0, FOUNDATION 1 = **6/10**

#### F1.4
> "Likhita Japa, completed: from your screen to Bhadrachalam and Varanasi, at no profit."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1 (completed = not a counter), SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 0, FOUNDATION 0 = **7/10**

#### F1.5
> "Likhita Foundation: every koti completed, printed, deposited at Bhadrachalam or Varanasi — at-cost."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1 (koti), SKEPTICISM 0, FOUNDATION 1 = **8/10**

**Round 1 winner (foundation): F1.5 — 8/10.**

### Likhita Rama hero (likhitarama.org)

#### LR1.1
> "Sri Rama, written by you. Delivered to Bhadrachalam."
8 words. NONPROFIT 0, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 0, SANCTITY 1, CONSTRAINT 1, SANSKRIT 0 (Sri Rama is a name not a sadhana term), SKEPTICISM 0, FOUNDATION 0 = **4/10**
This is the spec's existing hero. Beautiful but low rubric coverage.

#### LR1.2
> "Rama Koti completed: your hand on screen, your book at Bhadrachalam."
12 words. NONPROFIT 0, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1 (koti), SKEPTICISM 1 (your hand on screen — addresses real-practice skepticism), FOUNDATION 0 = **7/10**

#### LR1.3
> "Likhita Rama: koti by your hand, book at Bhadrachalam, non-profit."
10 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1 (book vs counter), SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 0, FOUNDATION 0 = **7/10**

#### LR1.4
> "Rama Koti: written by your hand, printed, deposited at Bhadrachalam — at-cost."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 0 = **8/10**

#### LR1.5
> "Sankalpam to Bhadrachalam. Rama Koti, by your hand, at no profit."
11 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1 (sankalpam, koti), SKEPTICISM 1 (vs counter implicit), FOUNDATION 0 = **8/10**

**Round 1 winner (likhita rama): LR1.4 / LR1.5 tied at 8/10.**

### Likhita Ram hero (likhitaram.org)

#### LM1.1
> "Ram Naam Lekhan: by your hand on screen, your book at Varanasi."
12 words. NONPROFIT 0, PHYSICAL 1, PROOF 0, TEMPLE 1 (Varanasi = Ram Naam Bank shorthand), NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1 (naam, lekhan), SKEPTICISM 1, FOUNDATION 0 = **7/10**

#### LM1.2
> "Sankalpam to Varanasi. Ram Naam Lekhan, by your hand, at no profit."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1 (Varanasi), NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1 (sankalpam, naam, lekhan), SKEPTICISM 1, FOUNDATION 0 = **8/10**

#### LM1.3
> "Ram Naam Lekhan: written by you, deposited at Ram Naam Bank, Varanasi."
12 words. NONPROFIT 0, PHYSICAL 1, PROOF 0, TEMPLE 1 (named exactly), NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 0 = **7/10**

#### LM1.4
> "Likhita Ram: lekhan by your hand, deposit at Ram Naam Bank Varanasi, non-profit."
12 words (counting "Ram Naam Bank Varanasi" as 4). NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1 (12 exact), SANSKRIT 1, SKEPTICISM 0, FOUNDATION 0 = **7/10**

#### LM1.5
> "Sankalpam to Ram Naam Bank Varanasi — Ram Naam Lekhan, at no profit."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 0 = **8/10**

**Round 1 winner (likhita ram): LM1.5 — 8/10.**

## Round 2: Mutate Foundation winner (F1.5 = 8/10)

Goal: pick up SKEPTICISM (point 9) without breaking ≤12 word rule. PROOF and FOUNDATION are
already in F1.5; missing items are SKEPTICISM. Adding "by your hand" addresses it.

### F1.5-M1
> "Likhita Foundation: koti by your hand, deposited at Bhadrachalam or Varanasi, at-cost."
12 words. Adds SKEPTICISM (your hand). Score: NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **9/10**

### F1.5-M2
Try fitting PROOF (photo+receipt). 12 words is too tight to add without dropping something. Tried:
> "Likhita Foundation: koti by hand, photo back from Bhadrachalam — at-cost, audited."
12 words. NONPROFIT 1, PHYSICAL 0 (lost it — only "photo back"), PROOF 1, TEMPLE 1, NOT-COUNTER 0 (lost it), SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **8/10**. Tradeoff worse. DISCARD.

### F1.5-M3
> "Likhita Foundation: koti by your hand, deposited at the temple, at no profit."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 0 (lost named), NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **8/10**. Worse — lost named temple. DISCARD.

**Round 2 winner (foundation): F1.5-M1 at 9/10.**

## Round 3: Try to get F1.5-M1 to 10

Missing: PROOF (photo+receipt). Cannot fit in 12 words alongside everything else.
Tried 8 mutations. Best:
> "Likhita Foundation: hand-written koti printed, deposited, photographed at Bhadrachalam or Varanasi."
12 words. NONPROFIT 0 (lost at-cost), PHYSICAL 1, PROOF 1 (photographed), TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **9/10**. Same total.

Cannot reach 10 within 12-word constraint. **TRADEOFF DOCUMENTED:** at the hero length, you must pick {NONPROFIT} or {PROOF}. The first is the brand pillar; the second is the receipt artifact. We pick NONPROFIT (more durable) and let the body copy carry PROOF.

**Final Foundation hero: F1.5-M1 — 9/10 stable.**

## Round 2-3: Mutate Likhita Rama (LR1.4 / LR1.5 = 8/10)

Goal: pick up FOUNDATION (point 10) without breaking limits.

### LR1.5-M1
> "Sankalpam to Bhadrachalam. Likhita Foundation: Rama Koti, by your hand, at-cost."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **9/10** KEEP.

### LR1.5-M2
> "Rama Koti by your hand, deposited at Bhadrachalam — Likhita Foundation, at-cost."
12 words. Same content, slightly different emphasis. Score 9/10. Tied. Stylistic preference: M1 leads with sankalpam — stronger spiritual frame.

### LR1.5-M3 — try fitting PROOF
> "Rama Koti by your hand, your book photographed at Bhadrachalam, at no profit."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 1, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 0 = **9/10**. Tradeoff: gains PROOF, loses FOUNDATION naming. Same total.

Cannot get all 10 in 12 words. Same tradeoff as Foundation. Pick the one with FOUNDATION named (it's the Likhita Foundation site).

**Final Likhita Rama hero: LR1.5-M1 — 9/10 stable.**

## Round 2-3: Mutate Likhita Ram (LM1.5 = 8/10)

Same logic.

### LM1.5-M1
> "Sankalpam to Ram Naam Bank Varanasi. Likhita Foundation: Ram Naam Lekhan, at-cost."
13 words. Over. Try:
> "Sankalpam to Ram Naam Bank, Varanasi — Likhita Foundation, Ram Naam Lekhan."
12 words. NONPROFIT 0 (no "at-cost"), PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 0, FOUNDATION 1 = **7/10**. Worse. DISCARD.

### LM1.5-M2
> "Likhita Foundation: Ram Naam Lekhan, by your hand, deposited at Varanasi — at-cost."
13 words.  Cut "by":
> "Likhita Foundation: Ram Naam Lekhan, your hand, deposited at Varanasi, at-cost."
12 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1 (Varanasi works — Ram Naam Bank shorthand), NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **9/10** KEEP.

### LM1.5-M3 — explicit Ram Naam Bank named
> "Likhita Foundation: Ram Naam Lekhan, your hand, to Ram Naam Bank Varanasi."
12 words. NONPROFIT 0 (lost), PHYSICAL 1, PROOF 0, TEMPLE 1 (named exactly), NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 1, SKEPTICISM 1, FOUNDATION 1 = **8/10**. Worse. DISCARD.

**Final Likhita Ram hero: LM1.5-M2 — 9/10 stable.**

## Round 4: One more pass — Foundation hero — try removing colon

### F1.5-M4
> "By your hand. To Bhadrachalam or Varanasi. Likhita Foundation, at-cost."
10 words. NONPROFIT 1, PHYSICAL 1, PROOF 0, TEMPLE 1, NOT-COUNTER 1, SANCTITY 1, CONSTRAINT 1, SANSKRIT 0 (lost koti/sankalpam), SKEPTICISM 1, FOUNDATION 1 = **8/10**. Worse, lost SANSKRIT. DISCARD.

### F1.5-M5
> "Likhita Foundation: sankalpam, koti, book, temple — at no profit, by your hand."
13 words. Over. DISCARD without scoring.

### F1.5-M6
> "Likhita Foundation: koti by your hand, book to Bhadrachalam or Varanasi, at-cost."
13 words. Trim "or":
> "Likhita Foundation: koti by your hand, book to Bhadrachalam and Varanasi, at-cost."
13 words. Still over. DISCARD.

**STABLE WINNERS (after 4 rounds):**
- Foundation: F1.5-M1 — **9/10**
- Likhita Rama: LR1.5-M1 — **9/10**
- Likhita Ram: LM1.5-M2 — **9/10**

Hero category cannot reach 10/10 within 12-word constraint. The unfillable slot is PROOF (photo+receipt). This is acceptable — proof is a body-copy claim, not a tagline claim.

---

# FINAL SUMMARY

| Category | Best Score | Iterations | Notes |
|---|---|---|---|
| Onboarding pledge | **10/10** | 8 | Hit ceiling round 1, validated through round 3 |
| ASC — Likhita Rama | **10/10** | 7 | Hit ceiling round 1, polished through round 3 |
| ASC — Likhita Ram | **10/10** | 6 | Hit ceiling round 1, polished through round 2 |
| Foundation hero | **9/10** | 9 | PROOF unreachable in 12 words; documented tradeoff |
| Likhita Rama hero | **9/10** | 6 | Same tradeoff |
| Likhita Ram hero | **9/10** | 6 | Same tradeoff |

**Total iterations: 42 across 6 sub-categories.**

## Open trade-offs

1. **Hero length vs PROOF coverage.** At ≤12 words, you cannot fit non-profit + temple-named + book-deposit + photo-receipt + Sanskrit term + Foundation name + skepticism rebuttal. We chose to drop "photo + receipt" from the hero and let the body copy / app store description carry it. Justification: PROOF is a delivery promise, not a positioning claim — heros should set position.

2. **Sanskrit literacy.** "Sankalpam," "koti," "lekhan," "naam" are unglossed in the hero. For the foundation page (English-speaking diaspora hub), this risks alienating second-generation diaspora who recognize the deity names but not the practice nouns. Mitigation: a one-line gloss appears below the hero in body copy. The pledge handles this with "sankalpam — a vow."

3. **App Store risk.** Apple's ASC reviewers occasionally flag explicit "non-profit" claims if Apple's own non-profit verification status isn't completed. Requires the 501(c)(3) determination letter on file with Apple before publishing. Spec §0 notes this is in progress — copy is correct in intent but publishing must wait for Apple's NP review.

4. **Competitor avoidance.** "Not a counter" and "open to all Hindu traditions" subtly counter Likhita Japa and Ramnaam Book respectively without naming them. App Store policy permits this; sanctity is preserved.
