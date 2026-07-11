# S2 — Catalog & set selection

> Search the LEGO catalog, view a set's detail (with tappable unique-parts and minifig
> lists), and **add a set** — snapshotting its expanded part list, minifigs, and spares into
> GRDB so everything downstream works offline.

Flutter reference: [`../phases/02-catalog-and-set-selection.md`](../phases/02-catalog-and-set-selection.md).
Sources to mirror: [`catalog_repository.dart`](../../apps/mobile/lib/features/catalog/catalog_repository.dart),
[`catalog_models.dart`](../../apps/mobile/lib/features/catalog/catalog_models.dart),
[`rebuild_repository.dart`](../../apps/mobile/lib/features/rebuild/rebuild_repository.dart) (`addSet`),
[`set_detail_screen.dart`](../../apps/mobile/lib/features/catalog/set_detail_screen.dart),
[`set_parts_screen.dart`](../../apps/mobile/lib/features/catalog/set_parts_screen.dart),
[`set_minifigs_screen.dart`](../../apps/mobile/lib/features/catalog/set_minifigs_screen.dart).

### Goal
The read-only catalog path + the one online write of the whole app: `addSet` → local
snapshot.

### Scope
**In:** debounced search over `sets`; set detail (image, set_num · theme · year, num_parts
caption, unique-parts + minifig stat blocks); the two list screens; `expand_set_parts`;
`setMinifigs`; `getSetSpares`; image resolution (CDN webp → rebrickable fallback); `addSet`
snapshot into GRDB (batched, one transaction).
**Out:** interactive counting (S3); the free-tier cap enforcement on "Start sorting" (added
in S5).

### Deliverables

**`BrickBackKit/Catalog`**
- `Models`: `CatalogKind`, `CatalogSet`, `CatalogResult`, `CatalogMinifig`, `SetDetail`,
  `ExpandedPart` (with the `key` = `"\(partItemId):\(colorId)"` and `fromCatalogRow`
  decoding — port [`catalog_models.dart`](../../apps/mobile/lib/features/catalog/catalog_models.dart)
  + `ExpandedPart` in [`rebuild_models.dart`](../../apps/mobile/lib/features/rebuild/rebuild_models.dart)).
- `protocol CatalogReader` (`setsByIds`, `expandSetParts`, `setMinifigs`, `getSetSpares`) +
  `SupabaseCatalogRepository: CatalogReader` on `catalogClient`, **read-only**. Port every
  query verbatim:
  - `search`: `.or("name.ilike.%q%,set_num.ilike.q%").gt("num_parts", 0).limit(25)`, with the
    same `_sanitize` (strip `,()%*`) and CDN image join.
  - `expandSetParts`: `rpc("expand_set_parts", ["p_set_item_id": id])`.
  - `setMinifigs`: latest inventory → `inventory_minifigs` with the nested `minifigs(...)` embed.
  - `getSetSpares`: `inventory_parts` where `is_spare = true` with the nested
    `parts(...part_categories(name))` + `colors(...)` embeds.
  - `setDetail`: set row + `items.theme_id → themes(name)` + minifig count.

**`BrickBackKit/Rebuild`**
- `RebuildRepository.addSet(setItemId:) async throws -> String` — fetch set + parts +
  minifigs + spares, compute `totalParts = Σ neededQty`, generate a `UUID`, and insert
  everything in **one GRDB transaction** with batched inserts (big sets are thousands of
  rows). Rows are `dirty = true` for the future cloud mirror. Exact port of `addSet`.
- `listSummaries()` (Home) with the **#N duplicate-copy numbering** and capped progress; and
  `remove()` (tombstone). Port from `rebuild_repository.dart`.

**App target (`Features`)**
- `Search` — debounced (~300 ms) search field → result rows → `.setDetail(itemId)`.
- `Catalog/SetDetailView` — image, name, `set_num · theme · year`, num_parts caption, two
  tappable stat blocks (**Unique parts** → parts list, **Minifigs** → minifig list), and the
  **Start sorting** CTA → `addSet` → `.rebuild(newId)`.
- `Catalog/SetPartsView`, `Catalog/SetMinifigsView` — the two lists (image, name, colour
  swatch, `×qty`), parts sorted by colour.
- `Home` — the real rebuild list (ProgressRing + `SetThumb` + have/total + %), swipe-to-remove
  (`.swipeActions`), empty-state "Add a set".

### Swift specifics
- **Decoding:** define `Codable` DTOs for the PostgREST rows and decode with
  `.execute().value` instead of hand-reading `Map<String,dynamic>`. Nested embeds
  (`minifigs(...)`, `parts(...)`, `colors(...)`) become nested `Decodable` structs — cleaner
  than the Dart `is Map ? … : {}` guards.
- **Search debounce:** a `.task(id: query)` with a `try await Task.sleep` gate, or an
  `AsyncStream` debounced in the view model — replaces the Riverpod `FutureProvider.family` +
  external debounce.
- **Images:** `SetThumb` uses `LazyImage` (Nuke) with the resolved URL; `ImageResolver`
  batches the `item_images` lookup exactly like `_imageUrls`.
- **`addSet` transactionality:** `try await dbQueue.write { db in … }` with a single write
  block; insert parts/minifigs/extras in a loop inside it (GRDB batches within the transaction).

### Acceptance (parity vs. Flutter Phase 2)
Reproduce the Flutter e2e: empty Home → **Add set** → search "3931" finds *Emma's Splash
Pool* → set detail shows **43 parts / 26 unique / 1 minifig** → **Start sorting** snapshots
into GRDB → the rebuild screen renders the checklist **from the local snapshot** → back to
Home → the rebuild lists at **0%**. Then kill the network and confirm the snapshot still
reads (offline-capable). Unit test: `addSet` writes the expected row counts and totals into
an in-memory DB using a fake `CatalogReader`.

### Risks
- **PostgREST embed shapes** must match the catalog exactly; probe them live once (they're
  documented in [STATUS Phase 2 verifications](../phases/STATUS.md#verifications-performed-phase-2))
  before trusting the Codable models.
- **Large snapshots** (thousands of parts): keep the insert inside one transaction; test with
  a big set (e.g. a 1000+ part set) for write latency.
