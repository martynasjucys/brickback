# F4 — Offline images (durable, deduplicated, pin-aware store)

> Guarantee that **any set added while online is fully openable offline — images included.** This
> is the one delta phase with **no Flutter precedent**: the old Flutter app relied on
> `cached_network_image`'s best-effort LRU disk cache, which is *not* an offline guarantee. The
> Swift app built a real store in S9; port it. The logic is ~280 LOC of SDK-free Swift that
> translates almost directly to Dart.

Swift oracle: `apps/ios/BrickBackKit/.../Support/{BrickImageStore,OfflineImageService,NetworkMonitor,ImageResolver,ImagePrefetching}.swift`
and `apps/ios/BrickBack/Support/ImageCache.swift`; full design in
[`../ios-swift/09-offline-mode.md`](../ios-swift/09-offline-mode.md).
Flutter target: a new `lib/core/offline/` module + wiring into `rebuild_repository.dart`,
`core/sync/sync_service.dart`, and the image widgets.

### Goal

Add a set on Wi-Fi → airplane mode → kill & relaunch → open it: Home thumbnail, every part/minifig
tile, review, and the verification report all render with **real images**, no placeholders, no
network. Counting done offline syncs the moment the network returns.

### The starting point (same as Swift)

Metadata is **already** offline: `addSet` snapshots set + expanded parts + minifigs + spares into
Drift including each row's resolved `image_url` (`${cdn}/${storage_key}`). So counting / progress /
review / wanted-list already run offline. **The only gap is the image bytes.** That single gap is
this whole phase.

### Design (port the locked S9 decision)

**Own the store — pin-aware, guaranteed.** Not an LRU cache: an added set must *never* lose its
images to a blind sweep.

1. **`BrickImageStore` (SDK-free Dart).** Directory `<app support>/Images/`, one file per unique
   image, filename = `sha256(url)`. **Dedup is inherent** — the same part+color resolves to the
   same URL across sets, so shared parts share one file. Mark the dir excluded-from-backup. API:
   `data(forUrl)`, `contains(url)`, `store(bytes, forUrl)` (atomic write), `remove(url)`,
   `removeAll()`, and pin-aware `gc(livingUrls)`. **One** canonical `hash(url)` — the only place
   URLs → filenames. **Filesystem-authoritative:** the directory of hash-named files *is* the index
   (`contains` = file-exists), so no separate index table and no file/row-divergence bugs.
2. **Per-set completeness marker.** Add a device-local, **never-synced** `images_cached_at`
   (nullable datetime) to `rebuild_sets` via a **Drift migration** (bump schemaVersion; the cloud
   schema is unchanged, and push/pull must not touch this column). `NULL` ⇒ prefetch incomplete ⇒
   resume when next online/opened; stamped when every one of the set's live URLs is on disk.
3. **Image-widget integration.** Route `SetThumb`/`PartTile`/etc. through a disk-first loader that
   checks `BrickImageStore` before the network. Options in Flutter: a custom `ImageProvider` backed
   by the store, or keep `cached_network_image` with a custom `BaseCacheManager` that reads/writes
   the store. Prefer the custom provider so the store is the single source of truth (mirrors the
   Swift `DataCaching` adapter). Once bytes are on disk the widget renders offline with no per-call
   change.
4. **Eager prefetch (protocol-first seam).** An `OfflineImageService` that lists a set's distinct
   live URLs (set + parts + minifigs + extras), fetches them with **bounded concurrency (~6)** off
   the UI isolate, writes into the store, and stamps `images_cached_at`. Triggers: after `addSet`
   (online); after cloud-import (a new-to-device set arriving via sync pull); on set-open when
   `images_cached_at IS NULL` and online; on reconnect.
5. **`NetworkMonitor`.** `connectivity_plus` (or a socket probe) exposed as a stream of distinct
   online/offline transitions. On a `→ online` edge: (a) `syncNow()` to flush queued edits promptly
   (the sync engine is already reconnect-resilient; this just adds the *prompt* trigger, not new
   sync logic), and (b) `resumeIncomplete()` to finish caching any set with `images_cached_at IS
   NULL`.
6. **Pin-aware GC.** `livingUrls = SELECT DISTINCT image_url` across sets ∪ parts ∪ minifigs ∪
   extras where the owning set isn't deleted. `gc(livingUrls)` deletes every file whose hash isn't
   in that set. Run on set-delete and occasionally (e.g. launch). Deleting a set unpins its images
   **only** if no surviving set still references them.
7. **Offline-aware UX.** Search + Add-set need the catalog network — when offline, show a clear
   "searching/adding needs a connection" state, not a spinner/error. Optional "Saving for offline…"
   affordance while a prefetch is in flight. Route the **verification report** image through the
   store (disk-first) so an offline PNG/PDF export still bakes in the set image.

**Not gated on premium** — free/local users add sets online and must view them offline too. The
store, prefetch, and GC run for everyone; only cloud *progress* sync stays premium-gated.

### Flutter specifics

- `sha256` via `package:crypto`. Atomic write = write to a temp file then `rename`.
- Run prefetch/hashing off the UI isolate; a large set is a few hundred small WebP thumbs
  (~5–30 KB each) at once — bound concurrency, keep it non-blocking (the set is usable immediately;
  images fill in).
- **Serialize** GC vs. prefetch on the same directory (a store mutex / the Drift write queue) so GC
  can't delete a file a prefetch is mid-write on.
- Keep the store module **UI-free** (mirrors the Swift "SDK-free in Kit" seam) so it's unit-testable
  with a temp dir + fake DB.

### Acceptance (parity with S9)

- **Offline open (headline):** add online → airplane mode → relaunch → open: Home thumb, every
  tile, review, and report render with real images, no network.
- **Dedup:** add two sets sharing parts → `Images/` has one file per distinct URL hash; total bytes
  ≈ union, not sum.
- **Pin-aware GC:** delete one of two sets sharing a part → the shared part's file survives; a part
  unique to the deleted set is removed. (Unit test over a temp store + fake DB.)
- **Reconnect sync:** count offline (premium) → restore network foregrounded → dirty rows flush in a
  couple of seconds, not only at the safety timer.
- **Interrupted prefetch resumes:** add, kill mid-prefetch → next online/open finishes and stamps
  `images_cached_at`.
- **Offline degradation:** search/add offline show the offline state.
- **Report offline:** export offline → the shared PNG/PDF includes the set image.

### Risks

- **Cache-key alignment.** GC pins by hashing the stored `image_url`; the image loader must read by
  the **same** hash. Centralize hashing in `BrickImageStore.hash` and keep requests plain (no image
  processors that would change the effective key) — a divergence silently orphans/mis-pins files.
- **Stale URL after catalog re-mirror.** `image_url` is snapshotted at add-time (correct for offline
  stability); the cache is keyed to the snapshot, not the live catalog. Expected, just note it.
- **Migration safety.** The new `images_cached_at` column must survive sync — push uses explicit
  payloads, pull does targeted column updates; verify neither clobbers it.
