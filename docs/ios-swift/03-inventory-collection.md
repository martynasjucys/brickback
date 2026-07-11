# S3 — Inventory collection (the core loop)

> The heart of the app: a tap-to-count grid that works fully offline, with live progress,
> per-part step, colour/type/progress grouping, a search sheet, a part-detail sheet, and the
> spares ("extras") section. Every tap writes (debounced) to GRDB — the source of truth.

Flutter reference: [`../phases/03-inventory-collection.md`](../phases/03-inventory-collection.md).
Sources to mirror: [`rebuild_screen.dart`](../../apps/mobile/lib/features/rebuild/rebuild_screen.dart),
[`rebuild_repository.dart`](../../apps/mobile/lib/features/rebuild/rebuild_repository.dart)
(`detail`, `setPartHave`, `setExtraHave`; `setPartStep` is intentionally **not** ported — step is in-memory),
[`rebuild_models.dart`](../../apps/mobile/lib/features/rebuild/rebuild_models.dart) (`RebuildInventory`),
[`rebuild_settings.dart`](../../apps/mobile/lib/core/rebuild_settings.dart),
[`bricklink.dart`](../../apps/mobile/lib/features/rebuild/bricklink.dart).

### Goal
`.rebuild(id)` is the interactive counter, reading and writing the local snapshot only —
**zero network during counting**.

### Scope
**In:** the tap-to-count grid (image-forward tiles, colour-coded neutral → amber → green,
tap = +step capped at needed, haptics); live `ProgressRing`; **"Remaining only"** toggle;
visible **step selector** {1, 5, 10, 25} + a per-part step remembered **in memory for the
open set only** (not persisted — see below); **sectioned** layout
with the view-settings sheet (**group by** Color / Type / Progress / None, **show extras**);
in-set **search sheet**; **part-detail sheet** (manual +/- stepper, clear, BrickLink deep
link, disabled price/3D "coming soon" slots); the **Extras** section (device-local bonus
tracking, excluded from completion). Force-quit safety: flush pending writes on
background/leave.
**Out:** review/verification (S4), party (S6), cloud sync (S5 — `nudge()` stays a no-op).

### Deliverables

**`BrickBackKit/Rebuild`**
- `RebuildInventory` value type with the progress getters ported verbatim: `haveTotal`
  (`Σ min(have, needed)`), `progress`, `complete`, `remainingPartTypes`, `missingParts`
  (Phase-4 use), `minifigs*` — and the `extras`/`extraHave` fields excluded from the build
  totals. This math is **identical** to [`rebuild_models.dart`](../../apps/mobile/lib/features/rebuild/rebuild_models.dart);
  it is the single source of the completion number the whole app trusts.
- `RebuildRepository.detail(id:)` — reads parts (ordered by `needed` desc), the `have` map,
  minifigs, and extras from GRDB into `RebuildInventory`. **No `step` map is read** — the
  per-part step is UI state, not persisted (see the "Per-part step" note below). So
  `RebuildInventory` carries **no `step` field** either (a divergence from the Flutter
  `RebuildInventory`, which reads step from the DB).
- Writers: `setPartHave` (absolute, clamped `0…100000`, marks `dirty`, bumps `updatedAt`) and
  `setExtraHave` (device-local). Port the exact dirty/updatedAt conventions — they're what
  keeps sync consistent. **There is no `setPartStep` DB writer** — the Flutter method is
  intentionally dropped; step lives only in the view model.

**`BrickBackKit/Support`**
- `BrickLink.url(...)` + `hasBrickLink(...)` — port [`bricklink.dart`](../../apps/mobile/lib/features/rebuild/bricklink.dart)
  (nullable `partNum` handling).

**App target (`Features/Rebuild`)**
- `RebuildView` — `@Observable RebuildViewModel` holds the live `have` map (session source of
  truth, debounced-written to GRDB) **and the in-memory `step` map** (`[partKey: Int]`,
  default 1, never written to GRDB — discarded when the view model is torn down). Layout:
  `ScrollView` + `LazyVGrid` per section (replaces the Flutter `CustomScrollView` +
  `SliverGrid`), section headers with per-section progress and a colour swatch for the Color
  grouping.
- Header: live `ProgressRing`, title, **Remaining only** toggle, step selector, and four
  header actions (**search · party · review · settings**) — party/review wired in S6/S4.
- Sheets: `PartSearchSheet`, `PartDetailSheet`, `ViewSettingsSheet` (group-by picker + show-extras
  toggle, disabled with "This set has no extra parts" when the set ships none).
- `Features/Home` — the **"Continue rebuilding"** horizontal strip (in-progress = started &
  not complete, newest first).

**Preferences**
- `RebuildViewSettings { grouping, showExtras }` persisted via `UserDefaults`/`@AppStorage`,
  degrading to defaults (port [`rebuild_settings.dart`](../../apps/mobile/lib/core/rebuild_settings.dart)).
  Groups are computed **at render time** (needed for the dynamic Progress split), same as the
  Flutter refactor.

### Swift specifics
- **Debounced persistence:** the view model keeps the authoritative `have` map in memory and
  schedules a `~350 ms` `Task`-based debounce per key → `setPartHave`. On `.background`/leave,
  `await` a final flush before navigating (mirrors the Flutter awaited-flush-in-back-handler),
  then the `ValueObservation`-backed Home refreshes on its own (no manual `invalidate`
  needed — a small win over Flutter).
- **Haptics:** `UISelectionFeedbackGenerator` per tap, `UIImpactFeedbackGenerator(.medium)`
  on completing a part, `.light` when tapping an already-done part — the exact Flutter
  haptic map.
- **Tap cap:** `newHave = min(current + step, needed)` — never over-count; tapping a
  completed part can't exceed `needed`. Reproduce as a pure function so it's unit-tested
  directly.
- **Grouping:** an enum `PartGrouping { color, type, progress, none }`; a `groups(for:)`
  function over the live `have` (Progress = Remaining/Complete split) — port `_PartGroup` +
  `_buildGroups`.
- **Per-part step is in-memory, session-scoped (adjustment from the Flutter app).** When the
  user changes a part's tap increment via the step selector / part-detail sheet, store it in
  the view model's `step` map only. It is remembered while the set stays open, and **reset to
  the default (1) when the set is left or the app relaunches** — nothing is written to GRDB.
  The tap math still reads the current step (`min(current + step[key] ?? 1, needed)`); only
  the *durability* changes. (The Flutter app persisted this in a `step_qty` column; we drop
  that column and its `setPartStep` writer — see [00 §5](00-architecture.md#5-local-store--grdb-schema-parity-with-drift-v3).)

### Acceptance (parity vs. Flutter Phase 3)
Port `test/phase3_counting_test.dart` to `BrickBackKitTests` over an in-memory DB:
tap = +1; **step +5 caps at needed**; tapping a completed part can't exceed needed;
**Remaining only** hides done parts; **live progress** total is right; **debounced write lands
in GRDB** (`have["10:1"] == 2`); a **fresh mount restores counts** from the snapshot. Plus a
new test that the settings sheet's four groupings and the extras toggle behave (extras never
affect build completion; `setExtraHave` clamps + persists). **Per-part step is session-only:**
a test that setting a part's step changes the tap increment while the view model lives, but a
re-created view model (fresh set open) reports the default step of 1 — and that **no row in
GRDB records the step** (there is no `step_qty` column). Live sim: search 3931 → counting
screen renders from the snapshot with colour sections, step selector, "0 of 43 parts";
counting works offline; screenshot-confirm the visual.

### Risks
- **Grid performance** on huge sets: use `LazyVGrid` and stable `id`s; avoid recomputing
  groups off the main actor's hot path. Test scroll on a 1000+ part set.
- **Write coalescing:** ensure rapid taps on the same part collapse to one debounced write,
  and that a leave-flush can't race a pending debounce (await the flush; cancel the timer).
