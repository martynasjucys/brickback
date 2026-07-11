# S4 — Review & verification (closes the MVP)

> The differentiator: completion %, the exact missing-parts list, inline minifig
> verification, a shareable verification **report** (image + PDF certificate), and the
> **BrickLink wanted-list** export. All computed locally off the same snapshot the counting
> screen uses, so the numbers line up exactly.

Flutter reference: [`../phases/04-review-and-verification.md`](../phases/04-review-and-verification.md).
Sources to mirror: [`review_screen.dart`](../../apps/mobile/lib/features/review/review_screen.dart),
[`verification_report.dart`](../../apps/mobile/lib/features/review/verification_report.dart),
[`wanted_list.dart`](../../apps/mobile/lib/features/rebuild/wanted_list.dart),
[`verification_models.dart`](../../apps/mobile/lib/features/rebuild/verification_models.dart),
and `saveVerification` / `latestVerification` / `wantedListXml` in
[`rebuild_repository.dart`](../../apps/mobile/lib/features/rebuild/rebuild_repository.dart).

### Goal
`.review(id)` → verify & finish → `.report(id)`; export missing parts to BrickLink.

### Scope
**In:** completion summary (ring == the counting ring, `inventory.progress`); inline minifig
verification (present/absent toggle for needed×1, +/- stepper for needed>1 → `setMinifigHave`);
the missing-parts list (biggest shortfall first, tap → BrickLink, "not exportable" footnote
for parts with no BL mapping); **share** the wanted-list XML; **Mark as verified** sheet
(box/instructions/stickers flags + notes) → `saveVerification` → report; the report
certificate with **share-as-image** and **printable PDF**.
**Out:** cross-rebuild "shopping list" aggregation (a later feature, as in Flutter);
cloud sync of verifications (transport lands in S5 — the row is already `dirty`).

### Deliverables

**`BrickBackKit`**
- `Models`: `MissingPart` (+ `.exportable`), `VerificationFlags` (box / instructions /
  stickers + derived all_parts / minifigs; JSON-encoded into the `flags` blob) and
  `VerificationRecord`. Port [`verification_models.dart`](../../apps/mobile/lib/features/rebuild/verification_models.dart)
  and the `RebuildInventory.missingParts` getter.
- `Support/WantedList.buildWantedListXML(_:)` — port [`wanted_list.dart`](../../apps/mobile/lib/features/rebuild/wanted_list.dart)
  **verbatim** (`<ITEMID>` = BL part id, else part number; `<COLOR>` = BL colour id, omitted
  when unknown; `<MINQTY>` = shortfall). It's self-contained pure string-building — the
  easiest 1:1 port in the app.
- `RebuildRepository`:
  - `saveVerification(...)` — write a `verifications` row **and** stamp `rebuild_sets.verified_at`
    in **one transaction**, both `dirty`; return the record. Exact port.
  - `latestVerification(id:)`, `wantedListXml(inv:)`.

**App target (`Features/Review`)**
- `ReviewView` — completion ring + stats, the minifig section (toggle/stepper writing straight
  to GRDB), the missing-parts list, a header **share** action (write XML to a temp file →
  `ShareLink`/activity sheet), and the **Mark as verified** sheet.
- `VerificationReportView` + `.report(id)` — the certificate: set image/name, a completion
  badge ("100% COMPLETE" / "0% · 43 parts missing"), parts + minifig stats, the flag
  checklist, date, notes, and a "Verified with BrickBack" mark.

### Swift specifics
- **Report rendering (the one genuinely different port):** replace Flutter's
  `RepaintBoundary → toImage(3×)` + `pdf`/`printing` with **`ImageRenderer`**:
  ```swift
  let renderer = ImageRenderer(content: VerificationReportView(record: record))
  renderer.scale = 3
  let png = renderer.uiImage?.pngData()                         // share-as-image
  let pdf = renderer.renderPDF(pageSize: .a4)                    // via renderer.render { … UIGraphicsPDFRenderer }
  ```
  Render the **same** SwiftUI view to both a @3× PNG and an A4 PDF so the printed certificate
  matches the shared image exactly (the Flutter guarantee). One-page certificate → no
  pagination. Share both via `ShareLink` / `UIActivityViewController`.
- **Share/BrickLink:** `ShareLink` for the XML file + report; `@Environment(\.openURL)` for
  the BrickLink part links.
- **Minifig verify UI:** present/absent as a toggle for needed×1, a `Stepper` for needed>1 —
  both call `setMinifigHave` (absolute, clamped, dirtied) with the same debounce convention.

### Acceptance (parity vs. Flutter Phase 4)
Port `test/phase4_review_test.dart`: missing-parts math (shortfall per part, complete parts
excluded, sorted by shortfall, **completion % == counting ring**, unmapped part surfaced not
dropped); wanted-list XML (BL id or part-num fallback, colour omitted when unknown, unmapped
part absent); a fully-counted rebuild → empty missing list + `100%` + no `<ITEM>`; minifig
verification rolls up **separately** from parts; `saveVerification` writes the row (notes
trimmed) + stamps `verified_at` + `latestVerification` reads it back. Live sim: add a set →
count → **Review** renders missing types + minifig row → **Mark as verified** → the report
certificate renders with **Share image / Share PDF**; screenshot-confirm. **This closes the
MVP** — feature-parity with the Flutter MVP, at higher fidelity.

### Risks
- **`ImageRenderer` off-screen sizing:** the view must lay out at a fixed width (it's not in
  the hierarchy). Give the report an explicit frame; test the PNG/PDF dimensions.
- **Share sheet on iPad:** `UIActivityViewController` needs a `popoverPresentationController`
  anchor — handle both idioms.
