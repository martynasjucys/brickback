# S9 — Offline mode (durable image cache + resilient sync)

> Guarantee that **any set added while online is fully openable offline** — not just its
> metadata (already local) but its **images** — and make the progress-sync flow prompt and
> robust when connectivity returns. The mechanism is a **pinned, deduplicated on-device image
> store** filled by an eager prefetch on add, plus a connectivity trigger that flushes queued
> edits and resumes any unfinished caching.

Flutter reference: none — the Flutter app relied on `cached_network_image`'s **best-effort**
disk cache (HTTP-header/LRU dependent), which is *not* an offline guarantee. This phase is a
deliberate upgrade over the oracle, not a parity port. Sequencing: depends only on **S2/S3**
(add-set snapshot + the counting loop) which are done, so it can be built now; it should land
**before the S8 store submission** — offline resilience is a launch-quality bar, not a
post-launch nicety. Numbered 09 to avoid renumbering existing files.

**Status: implemented (pin-aware store path).** `BrickImageStore` + `OfflineImageService` +
`NetworkMonitor` (BrickBackKit), the Nuke `DataCaching`/prefetch glue (`ImageCache.swift`, app
target), the `v3` migration, and the add/open/reconnect triggers are all in. Verified: 42/42
Kit unit tests pass (4 new — dedup, pin-aware GC across a shared part, complete/stamp,
incomplete→resume); the app builds clean for the simulator in Swift-6 mode; and a live run
confirmed 66 content-addressed WebP files written under `Application Support/Images/` (backup-
excluded) with all sets stamped `images_cached_at`.

### Goal
Add a set on Wi-Fi, go into airplane mode, and the Home list, the rebuild checklist, every
part/minifig thumbnail, the review screen, and the verification report all render — and any
counting done offline syncs the moment the network returns.

### The starting point — metadata is *already* offline
`RebuildRepository.addSet` ([`RebuildRepository.swift:28`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Rebuild/RebuildRepository.swift))
snapshots set + expanded parts + minifigs + spares into GRDB in one transaction, **including
each row's already-resolved, stable `image_url`** (`${cdn}/${storage_key}`, or the rebrickable
URL as fallback — built in
[`SupabaseCatalogRepository.imageUrls`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Catalog/SupabaseCatalogRepository.swift)).
So counting/progress/review/wanted-list math already run fully offline against the local
snapshot. **The only offline gap is the image bytes**, because `SetThumb`
([`Primitives.swift:382`](../../apps/ios/BrickBack/DesignSystem/Primitives/Primitives.swift)) and
`PartTile` ([`PartTile.swift:86`](../../apps/ios/BrickBack/Features/Rebuild/PartTile.swift)) load
via NukeUI `LazyImage` on the **default** `ImagePipeline.shared`, whose only persistence is
URLSession's `URLCache` (capacity-capped, HTTP-header/eviction dependent — not durable) plus a
memory cache wiped on relaunch. That single gap is the whole feature.

### Scope
**In:** a durable **pin-aware** image store (`BrickImageStore`) with inherent URL-dedup;
eager **prefetch on add / on cloud-import**; a `NetworkMonitor` that triggers sync + prefetch
resume on reconnect; pin-aware GC; offline-aware add/search UX; routing the verification
report's image through the store.
**Out:** offline *add-set* / *search* (both require the catalog `expand_set_parts` — inherently
online); prefetching sets the user never added; predownloading the entire catalog.

### Decision (locked)
**Own the store — pin-aware, guaranteed.** We implement Nuke's `DataCaching` over our own
directory + GRDB index and make it the pipeline's `dataCache`. GC is **pin-aware** (an image is
evictable only when *no* live set references its URL), so an added set **never** loses its
images to a blind LRU sweep. (The lean alternative — stock `DataCache` + high `sizeLimit` — was
rejected: LRU could evict a long-untouched set's images, breaking the offline guarantee.)

### Deliverables

**On-device store — `BrickImageStore` (BrickBackKit, SDK-free)**
- Directory `Application Support/Images/` (sibling of `brickback.sqlite`,
  [`AppDatabase.swift:21`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Local/AppDatabase.swift)),
  one file per unique image: filename = `sha256(url)`. **Dedup is inherent** — the same
  part+color has the same resolved URL across every set, so two sets sharing a part share one
  file. Mark the directory `isExcludedFromBackup` (regenerable cache; keep it out of iCloud).
- Plain blob API (no Nuke import — keeps the Kit package SDK-free, mirroring how it never
  imports SwiftUI): `data(forURL:) -> Data?`, `contains(url:)`, `store(_:forURL:)` (atomic
  write), `remove(url:)`, `removeAll()`, plus the pin-aware `gc(livingURLs:)`. A single
  canonical `hash(_ url:)` lives here and is the only place URLs → filenames.
- **Filesystem-authoritative — no separate index table.** The directory of hash-named files
  *is* the index: `contains` = `fileExists`, completeness = "are all a set's URL files present",
  and GC is a directory sweep. This drops a table (and the file/row-divergence class of bugs)
  the earlier draft carried; the store owns bytes, GRDB owns only the per-set marker below.
- **Per-set completeness marker:** device-local `rebuild_sets.images_cached_at DATETIME?` (not
  synced), added in GRDB migration `"v3"`
  ([`AppDatabase.swift`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Local/AppDatabase.swift),
  registered after `"v2"`; the cloud schema is unchanged). `NULL` ⇒ the set's prefetch is
  incomplete ⇒ resume when next online/opened; stamped when every one of the set's live URLs is
  on disk. Caches the answer so the hot path never re-stats a finished set. Safe across sync:
  push uses explicit payloads and pull does targeted column `UPDATE`s, so neither touches it.

**Nuke integration (app target)**
- `NukeDataCacheAdapter: Nuke.DataCaching` — a thin forwarder from Nuke's data-cache key (the
  image URL string, by default) to `BrickImageStore`. Installed once at launch:
  `ImagePipeline.shared = ImagePipeline { $0.dataCache = adapter; $0.dataCachePolicy =
  .storeOriginalData }` (keep the default memory `imageCache`). Nuke checks the data cache
  **before** the network, so once bytes are on disk `LazyImage` renders offline with **zero**
  code change in `SetThumb`/`PartTile`. `.storeOriginalData` persists the original bytes for
  reliable offline re-decode.

**Eager prefetch (protocol-first seam, like `SyncRemote`/`CatalogReader`)**
- Kit: `protocol ImagePrefetching { func prefetch(_ urls: [String]) async }` + an
  `OfflineImageService` that lists a set's distinct live URLs (set image + parts + minifigs +
  extras), drives the prefetcher, and stamps `images_cached_at` on completion.
- App: `NukeImagePrefetcher: ImagePrefetching` wrapping Nuke `ImagePrefetcher` with
  `destination: .diskCache` (fills the store without decoding into memory) and bounded
  concurrency (~6). Because the prefetcher runs on the pipeline whose `dataCache` is our store,
  prefetch **writes straight into `BrickImageStore`** — no separate write path.
- **Triggers:** after `addSet` succeeds (online); after `importFromCloud`
  ([`RebuildRepository.swift:56`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Rebuild/RebuildRepository.swift),
  a new-to-device set arriving via sync pull); on set-open when `images_cached_at IS NULL` and
  online; and on reconnect (below). Fakeable `ImagePrefetching` keeps unit tests deterministic.

**Connectivity trigger — `NetworkMonitor` (Kit)**
- `NWPathMonitor` exposed as `AsyncStream<Bool>` (online transitions), mirroring the existing
  `auth.signInStates()` async-stream pattern. Consume it in `AppEnvironment.startSyncWiring()`
  ([`AppEnvironment.swift:46`](../../apps/ios/BrickBack/AppEnvironment.swift)) alongside the
  auth stream. On a `→ online` edge: (a) `await sync.syncNow()` to flush queued progress
  promptly, and (b) `await offlineImages.resumeIncomplete()` to finish caching for any set with
  `images_cached_at IS NULL`.

**Pin-aware GC**
- `livingURLs = SELECT DISTINCT image_url` across `rebuild_sets ∪ rebuild_parts ∪
  rebuild_minifigs ∪ rebuild_extra_parts` where the owning set's `deleted = 0`. Pinning falls
  out of existing data — **no refcount table**. `store.gc(livingURLs:)` deletes every file +
  `cached_images` row whose hash isn't in that set. Run on set-delete
  ([`RebuildRepository.remove`, :151](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Rebuild/RebuildRepository.swift))
  and occasionally (e.g. launch). Deleting a set unpins its images **only** if no surviving set
  still references them.

**Offline-aware UX**
- Search + Add-set need the catalog network. When `NetworkMonitor` reports offline, show a
  clear "You're offline — searching and adding sets needs a connection" state instead of a
  spinner or raw error.
- Optional non-blocking "Saving for offline…" affordance on a set whose prefetch is in flight.
- **Verification report:** re-route `ReportViewModel`'s raw
  `URLSession.shared.data(from:)` ([`ReportViewModel.swift:47`](../../apps/ios/BrickBack/Features/Review/ReportViewModel.swift))
  through `BrickImageStore` (disk-first, then network) so an offline PNG/PDF export still bakes
  in the set image. The report's part thumbnails are already pinned (same part images), so they
  come for free once the report reads from the store.

### Sync-on-reconnect — mostly already solved
`SyncController` ([`SyncController.swift`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Sync/SyncController.swift))
is already resilient: offline edits stay `dirty` in GRDB; a failed push leaves rows dirty;
last-write-wins on `updated_at`; pulls skip locally-dirty rows; and the 30 s safety-push timer
([`startPeriodic`, :92](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Sync/SyncController.swift))
already flushes within 30 s of reconnect. This phase only adds the **prompt** trigger
(`NetworkMonitor → syncNow`) and reuses the exact same engine. **Image caching is *not* gated
on premium** (unlike sync): free/local users add sets online and must view them offline too, so
the store, prefetch, and GC run for everyone; only the cloud progress-sync stays premium-gated.

### Swift specifics
- `sha256` via `Crypto.SHA256` (already transitively present through `supabase-swift`) — no new
  dependency.
- Keep the **whole store SDK-free in Kit**; Nuke stays an app-target concern behind the
  `DataCaching` adapter + `ImagePrefetching` protocol — the established "protocols in Kit, SDK
  impls injected in the app" seam.
- `NWPathMonitor` on a dedicated queue; publish distinct-value transitions only (don't re-fire
  `syncNow` on every path update).

### Acceptance criteria
- **Offline open (the headline):** add a set online → airplane mode → kill & relaunch → open
  it: Home thumbnail, every part/minifig tile, review, and report render with **real images**,
  no placeholders, no network.
- **Dedup:** add two sets sharing common parts; `Images/` has **one** file per distinct URL
  hash (the shared part is stored once); total bytes ≈ union, not sum.
- **Pin-aware GC:** delete one of two sets that share a part → the shared part's file survives;
  a part unique to the deleted set is removed. (Unit test over the in-memory store + a fake DB.)
- **Reconnect sync:** count offline (premium) → restore network with the app foregrounded and
  no further edits → dirty rows flush within a couple of seconds (not only at the 30 s timer).
- **Interrupted prefetch resumes:** add a set, background/kill mid-prefetch → on next
  online/open the remaining images finish and `images_cached_at` gets stamped.
- **Offline degradation:** search/add while offline show the offline state, not a spinner/error.
- **Report offline:** export a report offline → the shared PNG/PDF includes the set image.

### Risks
- **Cache-key alignment.** GC pins by hashing the stored `image_url`; Nuke writes keyed by its
  data-cache key (the URL string by default). These must hash identically — a future custom
  Nuke `cacheKey` or an image processor in the request would diverge the keys and silently
  orphan/mis-pin files. Keep requests plain, and centralize hashing in `BrickImageStore.hash`.
- **Prefetch burst on add.** A large set is a few hundred distinct part images at once — bound
  concurrency (~6), run off the main actor, and keep it non-blocking (the set is already usable;
  images fill in). Realistic footprint is small (webp thumbs ~5–30 KB; a set ≈ a few MB; shared
  parts collapse hard across a collection), so a modest budget rarely evicts.
- **Store vs. GC race.** GC and prefetch can run concurrently on the same directory — serialize
  writes/removes through the GRDB write queue (or a store actor) so a GC can't delete a file a
  prefetch is mid-write on.
- **Stale URL after a catalog re-mirror.** `image_url` is snapshotted at add-time, so a set
  keeps its original URL even if the catalog later re-mirrors the image — correct for offline
  stability; just note the cache is keyed to the snapshot, not the current catalog.
