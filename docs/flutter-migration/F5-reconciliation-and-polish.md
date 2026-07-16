# F5 — Reconciliation & polish (close parity)

> Burn down the **reconciliation backlog** from F1 — the small behavioural refinements the Swift
> app folded into Phases 1–6 after the Flutter freeze — plus the accessibility and i18n items that
> round the app up to "shipped, first-party" in both languages. After F5, the Flutter app matches
> the current Swift build and Swift can be retired.

Swift oracle: `apps/ios` (per-item file:line from the F1 backlog). Flutter target: the specific
files named in `reconciliation-backlog.md`.

### Goal

Zero open **port**-tagged items in `reconciliation-backlog.md`; every screen passes a side-by-side
parity check with Swift in **light + dark, en + lt**, at large text sizes, with a screen reader.

### Tasks

1. **Work the backlog.** Implement each F1 **port** item against its Swift reference. Expected set
   (confirm/adjust from F1):
   - **Set lifecycle stage** (upcoming / retiring / retired) on set detail.
   - **BrickLink price guide / market value** on set detail.
   - **Device-locale auto-detect on first launch** + persisted Profile override (Flutter deferred
     this; Swift added it).
   - **Verification report localization + month names** via locale-aware date formatting (Flutter
     "left months English").
   - **Duplicate-set "#N" numbering**, per-part step map + debounce, display-name random default —
     any that F1 found missing.
2. **i18n parity.** Confirm en + lt cover every string including new F2/F3/F4 UI (offline states,
   "Saving for offline…", sidebar labels). Verify Lithuanian **plural** forms (`one/few/other`) on
   part/member counts — a real correctness bug if `few` (2–9) is wrong. The Flutter `intl`/ARB
   pipeline already handles plurals; just cover the new keys.
3. **Accessibility.** Dynamic Type / text-scale across all content (no fixed font sizes);
   `Semantics` labels on count tiles ("Brick 2×4, red, 3 of 5"), the progress ring, and
   missing-parts rows; minimum tap targets; contrast in both themes. Match the S7 accessibility bar.
4. **Dark-mode + orientation final sweep.** Every screen, both themes, phone + tablet, both
   orientations — against Swift screenshots. Fix stragglers.
5. **Contract re-check.** Re-verify the character-level contracts flagged in F1 (`flags` JSON keys,
   party identity key, sync payload fields, BrickLink XML/URL) are byte-identical to Swift.
6. **Retire the oracle (gated).** Once parity is signed off: mark `apps/ios` archived (or move it
   out of the default build), update `AGENTS.md` / root docs to name Flutter the shipping client,
   and note the Swift app is kept read-only for reference until launch.

### Acceptance

- `reconciliation-backlog.md` has no open **port** items.
- Boot a Lithuanian-locale device → UI comes up Lithuanian with correct plurals, no manual switch;
  Profile override persists.
- Full side-by-side parity pass (light/dark, en/lt, phone/tablet, large text, screen reader) with
  no clipping, untranslated strings, or contrast failures.
- All F0 tests still green; new logic (offline store, adaptive grid helpers, any ported logic) has
  unit coverage mirroring the Swift `BrickBackKitTests` set.

### Risks

- **Long-tail creep.** "Polish" can absorb unlimited time — the backlog is the boundary. Anything
  not on it and not a regression is a *new feature*, tracked separately (e.g. the 3D preview).
- **Plural correctness.** Lithuanian `few` is the classic miss — test with counts 2, 5, 10, 21.
- **Premature retirement.** Don't archive Swift until the parity pass is signed off and F0 tests are
  green on the Flutter side; keep it as the oracle until then.
