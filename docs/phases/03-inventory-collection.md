# Phase 3 — Inventory Collection (the core loop)

**Goal:** the heart of BrickBack — a fast, tap-to-count inventory screen. This is where a
user spends 95% of their time, so it must feel instant, work fully offline, and never lose
progress. Product workflow step 2 ("Collect the inventory").

MVP: ✅ — **this is the make-or-break screen.**

---

## Scope

**In:**
- The counting screen (`/rebuild/:id`): grid of parts grouped into manageable sections, tap-to-increment, live progress.
- Per-part detail (manual +/- stepper, clear, jump to BrickLink).
- Search/filter within the rebuild ("remaining only", text search).
- Fully local persistence with debounced writes; pause/resume; haptics.
- Continue-strip on Home.

**Out:** review/missing-parts/verification ([04](04-review-and-verification.md)); minifig *verification UI* (data snapshotted in [02](02-catalog-and-set-selection.md), verified in [04](04-review-and-verification.md)); party mode ([06](06-party-mode.md)); cloud sync ([05](05-auth-and-cloud-sync.md)).

---

## Deliverables

1. `/rebuild/:id` renders the snapshotted checklist as an image-forward grid.
2. Tapping a part increments its count (with step 1/5/10, capped at needed); part turns "done" at needed qty.
3. Progress ring updates live; killing and reopening the app restores exact counts.
4. "Remaining only" filter + in-set part search work.
5. Zero network calls during counting (verified in airplane mode).

---

## Tasks

### 3.1 Rebuild inventory model + provider (reuse)
Port `rebuild_models.dart` (`ExpandedPart`, `RebuildInventory`) and the read path from
`rebuild_repository.dart`:
- `inventoryProvider(rebuildSetId)` (`FutureProvider.autoDispose.family`) → `detail()` reads **entirely from Drift** (`rebuild_parts` rows). `have` map keyed `'$partItemId:$colorId'`.
- Derived getters: `haveTotal`, `progress`, `remainingParts`, `complete`.

### 3.2 The counting screen (reuse `set_inventory_screen.dart`, wireframe-skinned)
The whatabrick screen (~848 lines) is the reference; keep its interaction model:
- **Grid of `_PartTile`s**, image-forward, color-coded neutral → amber → green by fill ratio. Wireframe skin: boxes with `[img]` placeholder, part name, `have/needed` label, a fill bar.
- **Tap = +current step**, capped at `needed`. Step selector {1, 5, 10, 25}. Haptics: `selectionClick` per tap, `mediumImpact` when a part completes.
- **Grouping into sections:** product says "grouped into manageable sections." Group by **part category** (`part_cat_id` from the snapshot) or by color — pick one for MVP (category is more intuitive for sorting). Section headers with per-section progress. (whatabrick used a flat grid; adding sections is the one genuine UI addition here.)
- **Header:** `ProgressRing` (overall), in-set text search (`_PartSearchSheet`), "Remaining only" toggle.
- **Part detail sheet** (long-press): manual +/- stepper, "clear", BrickLink deep link (`bricklink.dart`), placeholders for "price/3D — coming soon" (omit in MVP wireframe or show disabled).

### 3.3 Local persistence (reuse the debounce path, drop the cloud nudge)
- `setPartHave(rebuildSetId, partItemId, colorId, qty)` writes **absolute** `have_qty` + `dirty=true` to Drift. Session keeps a local `_have` map as source of truth; writes **debounced ~350 ms**.
- In MVP, skip `syncController.nudge()` (or keep it as a no-op behind the premium gate). The debounce-to-Drift path is unchanged from whatabrick.
- **Never block the UI on a write** — optimistic local map, persist in background.

### 3.4 Home continue-strip
- Port the "continue rebuilding" horizontal strip from `home_screen.dart`: most-recent in-progress rebuilds, tap → `/rebuild/:id`.

### 3.5 Robustness
- Restore-on-open: `_have` initialized from Drift every time the screen mounts.
- App-lifecycle: flush the debounce on pause/inactive (via `app.dart` hooks) so nothing is lost if the OS kills the app mid-sort.
- Big-set performance: virtualized grid (`GridView.builder`), `cached_network_image`, avoid rebuilding the whole grid on each tap (tile-local state + a targeted invalidation).

---

## Schema / code specifics

- Everything reads/writes **Drift only**. No catalog call after the set is added (the snapshot has all metadata). No user-project call in MVP.
- Key convention (must match [02](02-catalog-and-set-selection.md) & [04](04-review-and-verification.md)): part identity `'$partItemId:$colorId'`; `have_qty` stored **absolute**, not as deltas.
- `total_parts` (denominator) is the snapshot from add-time; per-part `needed` is on each `rebuild_parts` row.

---

## Acceptance criteria

- [ ] A 500-part set scrolls at 60fps while tapping; no jank on increment.
- [ ] Force-quit mid-count, reopen → counts exact, progress ring matches.
- [ ] Airplane mode for the entire counting session → no errors, everything persists.
- [ ] Tapping past `needed` caps at `needed` (can't over-count).
- [ ] "Remaining only" hides completed parts; clearing a part re-shows it.
- [ ] Overall progress = Σ min(have, needed) / total_parts, updating live.

---

## Dependencies & risks

- Depends on Phase 2 (snapshotted checklist in Drift).
- **Risk (highest in the app):** performance on very large sets. Mitigate with builder grids, tile-local state, batched Drift writes. Profile on a mid-range device, not just the simulator.
- **Risk:** debounce + force-quit race — ensure the lifecycle flush is synchronous enough to win. whatabrick's `pushNow` pattern handles this; reuse it.
- **UX risk:** sectioning adds complexity; if it fights performance or clarity in testing, fall back to whatabrick's flat grid for MVP and revisit in Phase 9.
