# Phase 2 — Catalog & Set Selection

**Goal:** the first half of the core workflow — a user can find a LEGO set and add it to
their rebuild list. Everything reads from the **catalog project** (anon, read-only);
adding a set snapshots its full inventory into local Drift.

MVP: ✅

Corresponds to product workflow step 1 ("Select a LEGO set") + the "add" bridge into step 2.

---

## Scope

**In:**
- Catalog search by set number or name (`/search`).
- Set detail screen (image, name, number, year, theme, part count, minifig count).
- "Add set / Start sorting" → fetch `expand_set_parts` + minifigs, snapshot into Drift, create a local `rebuild_sets` row.
- Home tab lists the user's rebuilds with progress (empty until parts are counted).
- Catalog image resolution via R2 CDN with fallback.

**Out:** the counting UI ([03](03-inventory-collection.md)); browse-by-theme, filters, sorting-by-rarity, pricing (whatabrick extras — not MVP); scan-to-identify a set ([09](09-design-polish-and-future.md)); shared-link open ([09](09-design-polish-and-future.md)).

---

## Deliverables

1. Search screen: type "911" or "Millennium Falcon" → relevant sets appear (debounced).
2. Set detail renders real catalog data + image.
3. "Add set" creates a local rebuild with a fully snapshotted checklist; it shows on Home.
4. Adding the same set twice is allowed and disambiguated ("#1", "#2").

---

## Tasks

### 2.1 Catalog repository (reuse + retarget to `catalogClient`)
Port `apps/mobile/lib/features/catalog/catalog_repository.dart` and `catalog_models.dart`,
swapping every `supabase.` for `catalogClient.`. Keep:
- `search(query, kind: 'set', limit, offset)` — `.or('name.ilike.%q%,set_num.ilike.q%')`, `.gt('num_parts', 0)`, `.range(...)`. Reuse the `_sanitize` (strips `,()%*`) guard.
- `setsByIds(ids)` — batch fetch set metadata.
- `expandSetParts(setItemId)` — `catalogClient.rpc('expand_set_parts', params: {'p_set_item_id': id})`. Returns part+color+qty lines (minifig sub-parts included, spares excluded).
- Image URL resolution: prefer `item_images` (kind=`webp`) → `${CDN_URL}/${storage_key}`; fallback `rebrickable_img_url`.
- **New:** `setMinifigs(setItemId)` — join `inventories → inventory_minifigs → minifigs` for the set's figs (for minifig verification in [04](04-review-and-verification.md)).

Expose `catalogRepositoryProvider`, `searchProvider(query)` (`FutureProvider.autoDispose.family`), `setDetailProvider(setItemId)`.

### 2.2 Search screen (`/search`)
- Port `search_screen.dart` (wireframe-skinned). `SearchField` (built on raw `EditableText`), debounced ~300 ms → `searchProvider`. Results as `SetThumb` + name/number/year rows. Empty/loading/error via `.when`.
- Entry point: a "＋ Add a set" button on Home and in the empty state.

### 2.3 Set detail screen (`/set/:id`)
- Port `set_detail_screen.dart`. Show image, canonical name, set_num, year, theme name, `num_parts`, minifig count.
- Primary CTA: **"Start sorting"** → `RebuildRepository.addSet(setItemId)` → `context.push('/rebuild/$newId')`.
- Keep it lean — no price/rarity/3D (whatabrick had these; out of MVP scope).

### 2.4 Add-set → local snapshot (the important bit)
Port the snapshot logic from `rebuild_repository.dart` `addSet`, but write **only to Drift**
(no cloud in MVP):
1. `catalog.setsByIds([id])` → set metadata.
2. `catalog.expandSetParts(id)` → part/color/qty lines; `catalog.setMinifigs(id)` → figs.
3. Compute `total_parts` (sum of needed qty, spares already excluded by the RPC).
4. Generate a client uuid; insert `rebuild_sets` (Drift) + one `rebuild_parts` row per line (with metadata snapshot: name, part_num, color rgb, image url, bl_part_id, bl_color_id) + `rebuild_minifigs` rows.
5. Mark rows `dirty` (harmless now; consumed by sync in Phase 5).
- Allow duplicates (same set added twice → separate uuids). `listSummaries` auto-numbers copies "#1 / #2".

### 2.5 Home tab — rebuild list
- Port `inventory_screen.dart` list portion → BrickBack Home. Each card: set thumb, name, `ProgressRing` / `AppProgressBar` (have/total), "continue" tap → `/rebuild/:id`. Swipe-to-remove (`flutter_slidable`) → delete local rebuild (tombstone).
- `EmptyState` when no rebuilds: "No sets yet — add one to start sorting."
- `rebuildListProvider` (`FutureProvider.autoDispose`) reads Drift.

---

## Schema / code specifics

- **No writes to the catalog project, ever.** All catalog access is `select` / `rpc`.
- **`expand_set_parts` is the single catalog RPC** the core loop depends on. Confirm it's `execute`-able by the anon role on the catalog project (it is in whatabrick). If a set has no inventory in the catalog, handle gracefully (empty checklist + a "no inventory data" notice).
- Part/color identity key is `'$partItemId:$colorId'` (whatabrick convention) — reuse verbatim so `wanted_list.dart` and progress math line up.

---

## Acceptance criteria

- [ ] Searching a known set number and a known name both return correct results.
- [ ] Set detail shows correct part/minifig counts matching Rebrickable.
- [ ] "Start sorting" produces a local rebuild whose `total_parts` equals the set's real expanded part count (spares excluded).
- [ ] Airplane mode **after** adding a set: the rebuild + its full checklist still open (snapshot is local).
- [ ] Home lists rebuilds with a 0% progress bar right after adding.

---

## Dependencies & risks

- Depends on Phase 1 (`catalogClient`, Drift, design system).
- **Risk:** large sets (e.g. 7k-part UCS sets) — `expand_set_parts` returns thousands of lines; snapshot insert must be a single Drift batch/transaction, not row-by-row. Test with a big set.
- **Risk:** image CDN misses (`storage_key` null) — always fall back to `rebrickable_img_url`; `SetThumb` shows a brick placeholder if both fail.
- **Risk:** catalog `expand_set_parts` signature/param name (`p_set_item_id`) must match the deployed function on the whatabrick project. Verify against the live RPC in Phase 1.
