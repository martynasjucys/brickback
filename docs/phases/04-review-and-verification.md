# Phase 4 — Review & Verification

**Goal:** close the loop and deliver BrickBack's signature payoff — the review of what's
missing, separate minifig verification, and a shareable **Inventory Verification** report /
certificate. Product workflow steps 3 ("Review results") + 4 ("Finish"). This is the
feature that distinguishes BrickBack from whatabrick's plain rebuild tracker.

MVP: ✅ — **this completes the MVP.**

---

## Scope

**In:**
- Review screen: completion %, parts found, exact missing-parts list.
- **Minifig verification** (separate check-off list, using the snapshot from [02](02-catalog-and-set-selection.md)).
- Missing-parts export to **BrickLink** (Wanted List XML — reuse).
- **Mark as verified** → generate an Inventory Verification report (set info, completion, found/missing, minifig status, date, notes, flags for box/instructions/stickers).
- Share the verification as an **image** and export as a **printable PDF**.

**Out:** professional/branded certificate design ([09](09-design-polish-and-future.md) — MVP is a wireframe report); in-app BrickLink checkout (we export XML, user imports); cloud storage of reports ([05](05-auth-and-cloud-sync.md)).

---

## Deliverables

1. Review screen shows completion %, found count, and every missing part with shortfall qty.
2. Minifig checklist lets the user tick figures present/absent.
3. "Export missing" produces a valid BrickLink Wanted List XML and shares it.
4. "Mark verified" saves a `verifications` record locally and renders a report.
5. Report exports as a shareable image and a printable PDF.

---

## Tasks

### 4.1 Review / missing-parts screen (reuse)
Port `missing_parts_screen.dart` + `rebuild_repository.dart` `allMissingParts()`, scoped to
a single rebuild (MVP) rather than aggregated across all:
- Compute per-part shortfall `max(0, needed - have)` from Drift. List missing rows with thumb, name, color, "need N".
- Header stats: completion % = `Σ min(have,needed) / total_parts`, parts found = `Σ min(have,needed)`.
- `missingPartsProvider(rebuildSetId)`.

### 4.2 Minifig verification
- New screen/section reading `rebuild_minifigs` (snapshotted in [02](02-catalog-and-set-selection.md)). Each fig: image, name, needed qty, a present/absent (or have-count) toggle. Writes `have_qty` to the Drift `rebuild_minifigs` row (same debounce pattern as parts).
- Minifig completion rolls into the overall verification status separately from parts (product: "Verify minifigures separately").

### 4.3 BrickLink export (reuse verbatim)
- Port `wanted_list.dart` (`buildWantedListXml`, `wantedListXml(inv)`) and `bricklink.dart`. XML shape: `<INVENTORY><ITEM><ITEMTYPE>P</ITEMTYPE><ITEMID>blPartId</ITEMID><COLOR>blColorId</COLOR><MINQTY>shortfall</MINQTY>…`.
- Needs `bl_part_id` + `bl_color_id` — already in the snapshot (from `item_external_ids` / `color_bricklink_ids` at add time). If a part lacks a BL mapping, list it in a "not exportable" footnote.
- Export mechanics (reuse): write XML to `getTemporaryDirectory()`, `SharePlus.share(ShareParams(files:[XFile(..., mimeType:'application/xml')]))`.

### 4.4 Verification record (new)
Local Drift table `verifications` (mirrored to cloud in [05](05-auth-and-cloud-sync.md)):

```
verifications
  id            uuid  (client-generated)
  rebuild_set_id uuid (fk local rebuild_sets)
  set_item_id   int
  completion_pct real       -- parts
  parts_needed  int
  parts_found   int
  minifigs_needed int
  minifigs_found  int
  flags         json         -- { box, instructions, stickers, all_parts, minifigs }
  notes         text
  verified_at   timestamptz
  -- sync cols: updated_at, dirty, deleted
```
- "Mark as verified" screen: summary + toggles for the certificate flags (Box included / Instructions / Stickers applied) + optional notes → write a `verifications` row, set `rebuild_sets.verified_at`.

### 4.5 Report / certificate rendering (new)
- A `VerificationReport` widget (wireframe layout): set image + name + number, completion badge (e.g. "100% Complete" / "96% — 42 parts missing"), parts found/missing summary, minifig status, flags checklist, verification date, notes, a "verified with BrickBack" mark.
- **Share as image:** wrap the widget in `RepaintBoundary` → `toImage` → PNG → `share_plus`.
- **Printable PDF:** add `pdf` + `printing` packages; render the same content to an A4/Letter PDF (`Printing.sharePdf` / save). This is the "printable certificate that goes in the box" from the product's future list — MVP delivers a functional wireframe version.

### 4.6 Wire into the flow
- On the counting screen ([03](03-inventory-collection.md)), a "Review / Finish" action → review screen → (optionally) minifig verify → "Mark verified" → report.
- Home rebuild cards show a "Verified ✓" badge when `verified_at` is set.

---

## Schema / code specifics

- All math is local, off the Drift snapshot — consistent with [03](03-inventory-collection.md). No catalog or user-project calls except (later) cloud sync.
- Completion has **two axes** kept separate: parts % and minifigs present. The certificate can say "100% parts, minifigs included, box included."
- Reuse the `'$partItemId:$colorId'` key so missing-parts and wanted-list line up exactly with the counting screen.

---

## Acceptance criteria

- [x] Review completion % matches the counting screen's progress ring exactly. *(both read `inventoryProvider.progress` = Σ min(have,needed)/total; unit-tested `1/6`.)*
- [x] Missing list shows correct shortfall for every incomplete part; complete → empty list + "100%". *(unit-tested: shortfall per part, sorted desc; fully-counted → empty + 100%.)*
- [~] Exported XML imports cleanly into BrickLink's Wanted List uploader. *(XML **shape** validated by test — `<ITEMTYPE>P</ITEMTYPE>`, BL id / part-num `<ITEMID>`, `<COLOR>`, `<MINQTY>`; **not yet** round-tripped through BrickLink's live uploader — do before public launch.)*
- [x] Parts without a BL mapping are surfaced, not silently dropped. *("not exportable" footnote on the review screen + `MissingPart.exportable` test; unmapped item is absent from the XML.)*
- [x] "Mark verified" persists; report renders; force-quit/reopen → report still there. *(awaited Drift txn writes the `verifications` row + `verified_at`; `latestVerificationProvider` re-reads it on `/report/:id`; live e2e recorded + rendered a report.)*
- [~] Share-as-image produces a legible PNG; PDF opens and prints to A4/Letter. *(capture path implemented — `RepaintBoundary → toImage(3×) → PNG`; PDF embeds that PNG in an A4 page via `Printing.sharePdf`. The automated test stops before invoking the native share sheet, so **do a manual share/print pass** to confirm the exported files.)*

---

## Dependencies & risks

- Depends on Phases 2–3 (snapshot + counts).
- **Risk:** BL id coverage — some parts/colors have no BrickLink mapping in the catalog. Handle explicitly (footnote), don't crash the export.
- **Risk:** PDF/image rendering of large missing lists — paginate the PDF; cap the on-image list with "+N more".
- **This is the differentiator** — invest the review/verification UX even at wireframe fidelity so the *information* is right; visual polish comes in [09](09-design-polish-and-future.md).
