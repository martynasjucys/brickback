# F4 — Offline images: results

Port of the locked S9 design (`docs/ios-swift/09-offline-mode.md`) to Flutter. The
**headline guarantee**: any set added while online is fully openable offline —
images included — via a durable, deduplicated, pin-aware on-device store filled by
an eager prefetch, plus a connectivity trigger that flushes queued edits and
resumes unfinished caching on reconnect. Not premium-gated (only cloud *progress*
sync is).

Baseline before F4: 31 tests green. After F4: **40 tests green** (9 new), `flutter
analyze` clean, iOS simulator build clean, and a full live add→prefetch→cold-relaunch
round-trip exercised on the target sim.

## Module design (`lib/core/offline/`)

A new SDK-layered module mirroring the Swift "pure store in Kit, SDK glue in app"
seam:

| File | Role | SDK surface |
|------|------|-------------|
| `brick_image_store.dart` | `BrickImageStore` — the durable blob store | **Pure** `dart:io` + `crypto` (no Flutter, no Drift). Unit-testable over a temp dir. |
| `image_fetch.dart` | `resolveImageBytes` (disk-first) + `defaultHttpGet` | `dart:io` only. The single byte-resolution path shared by provider + prefetcher. |
| `image_prefetching.dart` | `ImagePrefetching` seam, `NoopImagePrefetcher`, `StoreImagePrefetcher` (bounded ~6) | `dart:io`. |
| `offline_image_service.dart` | `OfflineImageService` — ensure/resume/GC over store + Drift | Drift. |
| `brick_image_provider.dart` | `BrickImageProvider` — disk-first `ImageProvider` | Flutter painting. |
| `network_monitor.dart` | `NetworkMonitor` — de-duped online/offline transitions | `connectivity_plus`. |
| `offline_images.dart` | App-wide store holder (`OfflineImages`) + Riverpod providers | path_provider + Riverpod. |

### `BrickImageStore` (the heart)
- Directory `<app support>/Images/`, **one file per unique image**, filename =
  `sha256(url)` hex via `package:crypto`. **One canonical `hash(url)`** — the only
  URL→filename mapping (the cache-key-alignment guarantee).
- **Filesystem is the index**: `contains(url)` = `existsSync`, no separate table.
- **Dedup is inherent**: the same part+color resolves to the same URL across sets,
  so shared parts collapse to one file.
- API: `data(url)`, `contains(url)`, `store(bytes, url)` (atomic: write to a
  `.tmp_…` file then `rename`), `remove(url)`, `removeAll()`, `gc(livingUrls)`,
  `fileCount()`.
- **GC vs prefetch serialization**: an internal async `_Mutex` serializes
  `store`/`remove`/`removeAll`/`gc` so a sweep can't delete a file mid-write.
  Defense-in-depth: temp files carry a `.` prefix and GC only deletes names
  matching `^[0-9a-f]{64}$`, so an in-flight temp is never swept even absent the
  lock. Reads are lock-free (atomic rename → whole-or-nothing).
- **Backup exclusion**: best-effort. On macOS the `com.apple.MobileBackup` xattr is
  set via `Process`. iOS/Android have no pure-Dart hook for NSURL
  `isExcludedFromBackup` and `dart:io Process` is unavailable there, so it is a
  documented no-op on device (see Deferred). Durability itself is guaranteed by
  living in Application Support (never OS-purged, unlike Caches), independent of
  backup exclusion.

### Prefetch
`StoreImagePrefetcher` fetches a batch with **bounded concurrency (default 6)** —
network I/O overlaps across workers; each store write is serialized by the store
mutex; already-cached URLs are skipped; a failed fetch is swallowed so the set
stays unstamped for a later resume. `OfflineImageService`:
- `ensureCached(id)` — fast no-op once stamped; else prefetch the missing URLs,
  re-check, and stamp if now complete.
- `resumeIncomplete()` — retries every non-deleted set with `images_cached_at IS
  NULL` (covers add-then-offline and cloud-imported sets).
- `gc()` — sweeps files no living (non-deleted) set references.
- Distinct-URL and living-URL sets are computed with `UNION` SQL across
  `rebuild_sets ∪ rebuild_parts ∪ rebuild_minifigs ∪ rebuild_extra_parts`, a
  direct port of the oracle queries.

### App-wide wiring
`OfflineImages` resolves `<app support>/Images/` once (path_provider is async) and
holds the store. Consumers that may run before init await `OfflineImages.store`
(a `Future`); the image provider uses the synchronous `OfflineImages.storeOrNull`
so an early load never hangs — it just falls back to the network for the sub-second
window before init resolves (and gets cached on the next load / by prefetch).

## schemaVersion 4 migration + sync-safety proof

`rebuild_sets` gained a device-local nullable `images_cached_at DATETIME`:
- `schemaVersion` bumped **3 → 4**.
- A new `if (from < 4)` rung adds the column; the existing v2/v3 rungs are
  **untouched**. `app_database.g.dart` regenerated.
- `NULL` ⇒ prefetch incomplete ⇒ resume on next online/open; stamped when all of a
  set's live URLs are on disk. The stamp is written **without** marking the row
  `dirty` and **without** bumping `updatedAt` (no spurious last-write-wins).

**Proof push/pull never touch `images_cached_at`** (`core/sync/sync_service.dart`,
unmodified): `grep -n images_cached_at lib/core/sync/` → **no matches**.
- Push builds **explicit column maps** (`_pushSets` sends only `id`, `user_id`,
  `set_item_id`, `total_parts`, `verified_at`, `updated_at`, `deleted`).
- Pull writes an **explicit `RebuildSetsCompanion`** (`_pullSets` sets only
  `totalParts`, `verifiedAt`, `updatedAt`, `deleted`, `dirty`) → `imagesCachedAt`
  is `Value.absent` and preserved.
- New-to-device sets arrive via `importFromCloud`, which inserts with the column
  absent → `NULL` → prefetch triggers. No sync-service code change was needed.

## Widget integration (disk-first)

`SetThumb` (in `primitives.dart` — used by Home, review parts/minifigs, catalog,
search, party, and the report) now loads through **`BrickImageProvider`** instead
of `CachedNetworkImage`. Only the byte-loading path changed; the F2 chrome
(radius, stroke, placeholder, hairline, `errorBuilder` → placeholder) is intact.
The provider:
- Resolves via `resolveImageBytes`: store first, then network with **write-through**
  into the store.
- Carries **no processors** and keys on **URL + scale only** (`==`/`hashCode`), so
  the effective cache key equals the URL GC pins against, and Flutter's `ImageCache`
  dedupes identical loads across widgets.

**Verification report** (`verification_report.dart`): the certificate's set image
already routes through the store via `SetThumb`. To keep an **offline PNG/PDF export
from baking a placeholder**, `_capturePng` now `await precacheImage(...)`s the same
`BrickImageProvider(url)` key before `RepaintBoundary.toImage`, forcing the disk
decode to finish first.

## Certificate-preview width cap (F3 brief task 7, owned here)

The report preview is now wrapped in `Center(ConstrainedBox(maxWidth: 360))` around
the `RepaintBoundary`, pinning the on-screen preview to the ~360 width the export
actually renders (the Swift preview misrepresented ~360 output at ~780 on wide
layouts).

## Reconnect + launch wiring (`app.dart`)

`_BrickBackAppState` now, after `OfflineImages.init()`:
1. **Launch triggers** (fire-and-forget): `resumeIncomplete()` (finish any
   incomplete set) and `gc()` (prune unpinned files).
2. Subscribes to `NetworkMonitor.onlineTransitions()`. On a **`→ online` edge**:
   (a) `syncControllerProvider.syncNow()` — the F1 C1 "reconnect trigger" that
   promptly flushes queued edits (reusing the already-reconnect-resilient engine,
   just adding the prompt), and (b) `offline.resumeIncomplete()`.
   The subscription is cancelled in `dispose`.

## Test results (9 new, all green)

`test/f4_offline_images_test.dart`:
- **Store**: content-addressing dedups identical URLs (same URL → 1 file; distinct
  URLs → distinct files); `hash` is 64-hex sha256 and names the file; `removeAll`
  wipes.
- **Dedup across sets** (acceptance): two sets sharing a part → **exactly one file
  per distinct URL** (5 distinct URLs → 5 files, the shared part collapsed); both
  sets stamped; re-run is a no-op.
- **Pin-aware GC** (acceptance): delete one of two sets sharing a part → the shared
  file **survives** (pinned by the surviving set), the deleted set's **unique file
  is swept** (3 → 2 files).
- **Interrupted prefetch resumes**: offline → nothing cached, set unstamped; network
  returns → `resumeIncomplete` finishes caching and stamps.
- **Disk-first, NO network**: `resolveImageBytes` over a pre-seeded store with a
  **throwing** `httpGet` returns the disk bytes and **never calls the network**;
  and a store miss falls through to `httpGet` + write-through.
- **Provider decode from disk**: `precacheImage(BrickImageProvider(url, store,
  throwingGet))` fully decodes an image from the store with the network fetch never
  invoked.

## What was verified on the simulator vs deferred

Verified live on iPhone 16 Pro `FE3D0E3F`:
- App launches (no crash); `Application Support/Images/` created at launch.
- Catalog search rendered a real thumbnail through `BrickImageProvider` (network
  write-through path).
- **Add Colosseum (10276, 9036 parts, 220 unique parts)** → within ~3 s the store
  held **221 content-addressed files** (220 distinct part URLs + 1 set image), stable
  (no duplicates), **zero `.tmp` leftovers**, all names 64-hex. `images_cached_at`
  **stamped** (`rebuild_sets.images_cached_at = 1784213551`).
- **Cold kill + relaunch** → 221 files persist; Home shows the Colosseum with its
  **real thumbnail rendered from the durable store**.

Not exercisable on the sim (documented honestly): the iOS Simulator shares the host
network with **no per-sim airplane toggle**, so a true *offline* round-trip (real
network cut) can't be forced. The offline-read guarantee is instead proven by the
**disk-first-with-throwing-httpGet unit tests** (bytes served from disk, network
never touched) plus the cold-relaunch persistence above.

## l10n keys added

**None.** The optional "Saving for offline…" indicator and the offline
search/add-set UX states live in F3-owned feature screens; adding copy there is out
of boundary, so no ARB strings were added and no l10n regen was needed. (See
Deferred.)

## Deferred (follow-ups, out of F4 boundary)

- **Offline search/add-set UX states** (F4 brief task 7): "you're offline —
  searching/adding needs a connection" and the "Saving for offline…" affordance.
  These belong in F3-owned `search_screen.dart` / the add-set flow / shell — deferred
  to avoid a merge conflict with the concurrent F3 branch.
- **Rebuild-checklist `_PartTile` image path**: the counting screen's private
  `_PartTile` in F3-owned `rebuild_screen.dart` still uses `CachedNetworkImage`. Its
  part-image URLs are already pinned in the store (same URLs), so a one-line swap to
  `BrickImageProvider` would give it the same offline guarantee — an F3-owned edit,
  deferred. (Every tile that goes through `SetThumb` — Home, review, report, catalog,
  search, party — is already covered.)
- **iOS/Android backup exclusion**: needs a tiny native hook to set NSURL
  `isExcludedFromBackup` (native project files are out of F4 boundary). Durability is
  unaffected.

## Boundary confirmation

Edited **only**: `lib/core/offline/**` (new), `lib/core/db/app_database.dart` (+
regen `.g.dart`), `lib/features/rebuild/rebuild_repository.dart`,
`lib/widgets/primitives.dart`, `lib/features/review/verification_report.dart`,
`lib/app.dart`, `pubspec.yaml`/`pubspec.lock`, and new `test/f4_offline_images_test.dart`.
`core/sync/sync_service.dart` was **not** modified (the reconnect trigger lives in
`app.dart`; the column is confirmed untouched by the existing explicit-column push/pull).
**No** F3-owned files were touched (`app_shell.dart`, `app_router.dart`,
`rebuild_screen.dart`, `search_screen.dart`, `set_detail_screen.dart`,
`home_screen.dart`, `profile_screen.dart`, `party/*`, `sign_in_screen.dart`,
`paywall_screen.dart`, `review_screen.dart`, native manifests). No l10n ARB changes.
