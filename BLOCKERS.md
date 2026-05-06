# Likhita — Human-Required Blockers

**Date:** 2026-05-06
**Project:** Likhita Foundation (Likhita Rama + Likhita Ram iOS apps)
**Status:** Code scaffolds complete (backend + iOS + autoresearch); Apple Dev access cached. These are the things only you can do.

---

## 🟢 Already done (cached, no action)

- ✅ Apple Developer Program ($99) — active, Team ID `WS486NY2HV` cached in memory
- ✅ Vercel auth — logged in as `beno83459-9497`, team `shipitandprays-projects`
- ✅ GitHub auth — `gh` CLI ready
- ✅ xcodegen — installed and verified working
- ✅ Spec written, autoresearch complete, iOS scaffold compiles, backend scaffold in progress

---

## 🔴 Blocking — do these to unblock autonomous deployment

### 1. ASC API key (5 min) — unblocks autonomous TestFlight + bundle ID reservation

**Why:** Without this `.p8` key, I cannot programmatically reserve bundle IDs, create app records, trigger Cloud builds, or submit to TestFlight. The skill will need to fall back to Playwright clicks against ASC web.

**How:**
1. Open https://appstoreconnect.apple.com/access/integrations/api
2. Click **Keys** tab → **+** → **Generate API Key**
3. Name: `Likhita Autonomous`
4. Access: **Admin** (App Manager is too restrictive for build triggers)
5. Click **Generate**
6. Download the `.p8` file **immediately** (only chance — Apple won't show it again)
7. Save to `~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8`
8. Tell me the **Key ID** (10 chars, top of the keys list page) and **Issuer ID** (UUID in the page header)

I'll persist these to memory once given.

---

### 2. Bundle IDs (3 min — I do via API once #1 is done)

Two bundle IDs to reserve:
- `org.likhita.rama` (Likhita Rama — Telugu)
- `org.likhita.ram` (Likhita Ram — Hindi)

**You don't need to do this manually.** Once #1 (ASC API key) is resolved, I'll reserve both via:

```bash
curl -X POST https://api.appstoreconnect.apple.com/v1/bundleIds \
  -H "Authorization: Bearer $JWT" -d '{...}'
```

If you'd rather do it via UI: https://developer.apple.com/account/resources/identifiers/list → **+** → App IDs → register both with Push Notifications capability.

---

### 3. App Store Connect app records (5 min — I do via API once #1 is done)

Two app records to create:
- **Likhita Rama** (Bundle: `org.likhita.rama`, SKU: `likhita-rama-ios-1`)
- **Likhita Ram** (Bundle: `org.likhita.ram`, SKU: `likhita-ram-ios-1`)

Will be done via ASC API. If you'd rather: https://appstoreconnect.apple.com/apps → **+** → New App.

---

### 4. Domain registration ($80–120 total, 10 min)

All 14 domains were verified available via whois on 2026-05-05. Register through Vercel Domains (cleanest, since hosting is on Vercel) or Namecheap.

| Domain | Priority | Cost | Purpose |
|---|---|---|---|
| `likhita.org` | **must** | ~$12/yr | Foundation home, transparency portal, donations |
| `likhita.app` | **must** | ~$15/yr | Foundation modern site |
| `likhitarama.org` | **must** | ~$12/yr | Telugu app marketing |
| `likhitaram.org` | **must** | ~$12/yr | Hindi app marketing |
| `likhita.com` | should | ~$12/yr | Defensive |
| `likhitarama.app` | should | ~$15/yr | Defensive |
| `likhitaram.app` | should | ~$15/yr | Defensive |
| `likhitafoundation.org` | nice | ~$12/yr | Redirect to likhita.org |
| `likhitatrust.org` | nice | ~$12/yr | Defensive |

**How (via Vercel CLI, cleanest):**
```bash
vercel domains buy likhita.org
vercel domains buy likhita.app
# (etc.)
```

After purchase, add DNS to point to Vercel project. Will be automatic once backend is deployed.

---

### 5. Foundation legal entity (weeks; no autonomous path)

Required for the non-profit anchor in the spec (§0). Two parallel filings:

**India — Section 8 Company under Companies Act 2013:**
- Engage a CS (Company Secretary) or non-profit legal firm in India
- 2+ directors required
- Draft MOA + AOA
- Filing fee ~₹15,000 + professional fee ~₹25,000
- Timeline: 2–4 weeks for incorporation; 80G + 12A registration follows over 1–3 months
- Once registered, transfer foundation domain registrations + Apple Developer to entity name

**United States — 501(c)(3) public charity:**
- Use Form 1023-EZ if revenue projected < $50K/yr first 3 years (simpler, faster, $275 fee)
- Otherwise Form 1023 (full, $600 fee)
- 3+ directors required
- Timeline: 3–12 months for IRS determination letter
- Apply for **Apple Non-Profit Developer Discount** post-determination at https://developer.apple.com/programs/non-profit/ (waives the $99/yr fee)

**Recommended firms (research yourself):**
- India: Vakilsearch, ClearTax, IndiaFilings (cheap), Khaitan & Co (premium)
- US: Sandler Reiff (DC), TGI Law (CA non-profit specialists), Pro Bono Partnership

---

### 6. Temple authority approvals (weeks; physical visits needed)

The single biggest assumption in the spec: that **Bhadrachalam temple** and **Ram Naam Bank Varanasi** will accept printed digital Rama Koti / Ram Naam books.

**Bhadrachalam (Sri Sita Ramachandra Swamy Temple):**
- Contact: temple trust office in Bhadrachalam, Telangana
- Visit in person if possible — non-profit framing helps
- Get **written approval** on temple letterhead before any user pays a shipping fee
- Negotiate: quarterly book delivery, Rama Koti Mandapam shelf placement, individual book photography permission, stamped receipt issuance

**Ram Naam Bank, Varanasi:**
- Contact: Sri Satua Baba Ashram (Ramanandacharya tradition lineage)
- This bank has been accepting handwritten Ram-naam ledgers since 1926; printed digital should be in scope but get explicit written confirmation
- Same negotiation: bundling, photography, receipt protocol

**Until both approvals are in hand, do not enable the "Ship to temple" payment flow in the apps.** Ship-to-home only.

---

### 7. Print partner contracts (1–2 weeks)

Get quotes from 3 Hyderabad presses (and 1 Varanasi if cost-competitive) for:

- **Standard book:** 666-page cloth-bound, gold-foil "శ్రీరామ కోటి" or "श्री राम नाम" cover, archival paper interior, target ₹350 print + ₹120 materials = ~₹470 unit cost
- **Crore multi-volume:** 10 volumes × 6,666 pages each, target ~₹400/volume = ₹4,000 set + ₹600 slipcase = ~₹4,600

Frame as **non-profit, recurring quarterly volume**. Many Hyderabad religious presses (e.g. Bharath Press, Sri Vaishnava Press) honor non-profit pricing.

---

## 🟡 Optional but recommended

- [ ] Trademark filings (USPTO + Indian Trademark Registry): "Likhita Foundation," "Likhita Rama," "Likhita Ram." Cost: ~$350 USPTO each, ~₹4,500 IPI each. Timeline: 6–18 months.
- [ ] Logo design (commission Indian illustrator on Behance/Dribbble Hindu art tag)
- [ ] Lottie animations: Pattabhishekam ceremony, milestone unlocks, page turns

---

## What I will do once you complete the blocking items

After you provide ASC API key (Item 1) and confirm domain purchases (Item 4), I will:

1. Reserve both bundle IDs via ASC API
2. Create both app records via ASC API (note APP_IDs)
3. Set up first Xcode Cloud workflow (one-time OAuth — I'll guide you through Xcode menu)
4. Deploy backend skeleton to Vercel preview, then production
5. Configure DNS for the 4 must-have domains pointing to Vercel
6. Build first iOS Internal TestFlight build (your iPhone gets it in ~10 min)
7. Add yourself + 2–3 friends to Internal Testing
8. Continue iterating — every `git push origin release` ships a new build to your phone

Apple Review (24–48 hr) and Apple's $99 verification gates are unavoidable platform constraints; everything else is now scriptable.

---

## TL;DR — minimum unlock to keep building autonomously

Just do **#1** (ASC API key, 5 min). That alone unblocks:
- ✅ Bundle ID reservation
- ✅ App record creation
- ✅ Cloud build triggers
- ✅ TestFlight Internal/External submission
- ✅ Beta tester invites
- ✅ Build status polling

**Domains (#4) and legal (#5–6) can run in parallel with TestFlight Internal builds.**
