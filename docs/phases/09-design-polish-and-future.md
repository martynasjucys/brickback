# Phase 9 — Design Polish & Future Features

**Goal:** once the MVP flow is validated at wireframe fidelity, invest in the polished,
branded experience — and layer in the deferred "future" features from the product
description. This is the "fully and polished MVP" gate the user asked to hold for.

MVP: — (the polish gate + the future roadmap)

---

## Part A — Wireframe → Branded design

The whole app was built on a **wireframe token set** ([01](01-foundation.md)) using the
same token *names* as whatabrick (`AppColors`, `AppSpacing`, `AppRadius`, `AppText`) and
its primitive widgets. Polishing is therefore mostly a **token + primitive swap**, not a
rewrite.

**Tasks:**
- Produce the real brand: LEGO-flavoured but legally safe (BrickBack's own identity — do
  not use LEGO trademarks/logos; the catalog is fan data via Rebrickable). Playful, bright,
  trustworthy, focused (product's Design Principles).
- Swap `lib/theme/app_theme.dart` from the wireframe tokens to the branded palette +
  `google_fonts` typography (whatabrick used Nunito; pick BrickBack's own). Because
  screens consume tokens, most update automatically.
- Re-skin the primitives (`lib/widgets/*`) to the brand; consider lifting whatabrick's
  polished set (`Pressable`, `AppButton`, `ProgressRing`, `BrickStuds` LEGO-stud CustomPaint,
  Liquid Glass nav) where they fit.
- Design the **verification certificate** properly (the seller-facing card + printable PDF)
  — this is a marketing surface, worth real design. Elevate [04](04-review-and-verification.md)'s wireframe report.
- Motion/haptics polish, empty states, onboarding, app icon, store screenshots.
- Align the marketing site ([08](08-marketing-site.md)) visuals with the app brand.

**Gate:** only start Part A after the MVP loop (1–4) tests well with real users on real
piles. Polishing an unvalidated flow is wasted effort — that's the whole reason for
wireframe-first.

---

## Part B — Future features (product "Future Features")

Sequence by value; each is independent.

### B1 — Set recognition (scan to identify)
Identify a set by scanning the box or instruction booklet, or intelligent search.
- Reuse whatabrick's `features/identify/*` + `set_scan_*` (currently stubbed there) and its
  vision pipeline (`services/pipeline`, `scripts/vision/*`) as the reference. This is a
  large sub-project (camera → cloud recognition → set match) — its own phase set.
- Cheapest first step: OCR the set number off the box/booklet (`image_picker` + on-device
  or cloud OCR) → catalog lookup. Full pile/part vision ID is the deep end.

### B2 — Original Bag Reconstruction
Reorganize collected parts into LEGO's original numbered bags for a new-set build
experience. Needs per-bag inventory data (Rebrickable has some build/step data; assess
coverage). Group the counting checklist by bag number.

### B3 — Printable Certificate (polished)
The professional resale certificate: "100% Complete, minifigs included, stickers applied,
instructions included, box included, verification date." Builds on [04](04-review-and-verification.md)'s PDF with a designed template. A resale-confidence marketing asset.

### B4 — Shared-link open & deep links
Open a set/rebuild directly from a shared link (product workflow step 1 "Open from a shared
link"). Requires universal links + a web resolver (tie into [08](08-marketing-site.md)).

### B5 — Pricing surfaces (if wanted)
whatabrick has `bricklink_price_guides` + a pricing repository. BrickBack deliberately
scoped this out (it "is not a price tracker"), but missing-parts cost estimates could add
value to the export flow. Optional; keep aligned with the product philosophy.

---

## Acceptance criteria (Part A)

- [ ] Branded theme swapped in via tokens with no screen-level rewrites.
- [ ] Verification certificate looks like something a seller would proudly attach to a listing.
- [ ] App icon, onboarding, store screenshots ready for submission.
- [ ] Marketing site and app share one visual language.

---

## Dependencies & risks

- Part A depends on a validated MVP (1–4); Part B items are independent post-launch tracks.
- **Trademark risk:** BrickBack must not use LEGO's marks/branding; be "LEGO-flavoured"
  with its own identity. Catalog data is fan-sourced (Rebrickable) — attribute per their
  terms.
- **Scope risk (B1):** set/part vision recognition is genuinely hard and large — treat it
  as its own multi-phase initiative, not a checkbox. Ship OCR-of-set-number first.
