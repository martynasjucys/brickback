# Reconciliation backlog (F1 output)

> Produced by **F1 — Parity diff** (2026-07-16). A systematic Swift↔Flutter behavioural diff across
> all nine areas of Phases 1–6. The Swift app (`apps/ios`) is the acceptance oracle; the Flutter app
> (`apps/mobile`) froze on 2026-07-11. Every difference below is tagged **port** / **already-present**
> / **ignore**, with the Swift `file:line` and the Flutter file to change, and the phase that burns it
> down. Method: one agent per area, diffing behaviour/copy/logic (contract-level keys diffed
> character-for-character).

## The headline (de-risk verdict)

**Nothing silently drifted at the contract level, and no shipped product logic regressed.** Every
dangerous-class item — the sync wire contract, `verification.flags` jsonb keys, the BrickLink
wanted-list XML, the party identity key, the RPC names/params — is **byte-identical** between the two
clients (see [Contract verification](#contract-verification-the-dangerous-class-—-all-match)). The
"501 vs 201" i18n scare was a counting artifact: apples-to-apples it's **236 Swift keys → 201 Flutter
keys**, and 63 of the 74 Swift-only strings are copy that rides along with the five deferred features
(the other 11 are VoiceOver-only artifacts).

What the diff actually found: the expected **S7/S9/S10 delta** (branded design, offline images,
adaptive layout — already carved into F2/F3/F4) plus a **backlog of small behavioural + copy
refinements** the Swift 1–6 screens absorbed after the freeze. All of it is F5-sized or smaller; none
needs its own phase.

### Counts

| Tag | Count | Meaning |
|---|---:|---|
| **port** | ~30 items | Swift is ahead; do it (in the phase noted). Most are S/M; two are L. |
| **already-present** | 15 groups | Verified identical — no-op, but recorded so the area is provably reviewed. |
| **ignore** | 16 items | Swift-only mechanism/redesign artifact with no Flutter meaning. |

### How to read the phase tags

- **F2** (design system): small behavioural/copy items on screens F2 restyles anyway — cheapest to fold in there.
- **F3** (adaptive layout): anything layout/shell (Party tab, the counting ••• menu, master-detail).
- **F4** (offline images): the S9 image-store delta — *confirmed as expected, not new F1 work*.
- **F5** (reconciliation & polish): the bulk — the feature refinements, copy, i18n, a11y.

---

## Ranked port backlog

Ranked by user impact, then effort (cheaper first) as tiebreak. `⚠` = has an external/server dependency.

| # | Item | Tag | Effort | Phase | Target Flutter file |
|---|---|---|---|---|---|
| **P1 ⚠** | Party join = free anonymous guest (drop paywall gate) + guest session + Party tab/landing + join errors | port | M (cluster) | F3 | `features/auth/auth_repository.dart`, `features/party/*`, `features/shell/app_shell.dart`, `features/profile/profile_screen.dart` |
| **P2** | Set lifecycle stage + availability dates on set detail | port | M | F5 | `features/catalog/{catalog_models,catalog_repository,set_detail_screen}.dart` |
| **P3** | BrickLink market value (new/used) on set detail | port | M | F5 | `features/catalog/{catalog_models,catalog_repository,set_detail_screen}.dart` |
| **P4** | Home theme + status filter sheet | port | L | F5 | `features/home/home_screen.dart`, `features/rebuild/{rebuild_models,rebuild_repository}.dart` |
| **P5** | Display-name brick-themed generator + Profile name editor | port | M | F5 | `features/profile/profile_screen.dart` (+ new generator) |
| **P6** | Profile lifetime stats card (Sets built / Parts collected) | port | M | F5 | `features/profile/profile_screen.dart` |
| **P7** | Verification report date localization (LT locale bug) | port | S | F5 | `features/review/verification_report.dart` |
| **P8 ⚠** | Language "System" option + first-launch device auto-detect | port | M | F5 | `core/locale.dart` |
| **P9 ⚠** | Sign in with Apple — native token exchange (App Store compliance) | port | L | F5 | `features/auth/{auth_repository,sign_in_screen}.dart` |
| **P10** | Counting: rich VoiceOver semantics on part tiles / search rows | port | L | F5 | `features/rebuild/rebuild_screen.dart` |
| **P11** | Home list goes live (progress updates while visible) | port | M | F5 | `features/rebuild/rebuild_repository.dart` |
| **P12** | Appearance setting row (System/Light/Dark) — UI only | port | S | F5 | `features/profile/profile_screen.dart` (dark tokens = F2) |
| **P13** | Free-tier rebuild cap removed on "Start sorting" (product decision) | port | S | F5 | `features/catalog/set_detail_screen.dart` |
| **P14** | Paywall offering + copy drift (3 benefits, drop "Unlimited") | port | S | F5 | `features/premium/paywall_screen.dart`, `l10n/*.arb` |
| **P15** | Sign-in screen copy drift | port | S | F5 | `l10n/*.arb` |
| **P16** | Home: pull-to-refresh forces cloud sync | port | S | F5 | `features/home/home_screen.dart` |
| **P17** | Profile: remove manual "Sync now" button (oracle retired it) | port | S | F5 | `features/profile/profile_screen.dart` |
| **P18** | Profile: explicit "Sign in" entry for signed-out users | port | S | F5 | `features/profile/profile_screen.dart` |
| **P19** | Profile: About / version footer | port | S | F5 | `features/profile/profile_screen.dart` |
| **P20** | Home: "All sets" section header | port | S | F5 | `features/home/home_screen.dart` |
| **P21** | Home: empty-state copy + icon align | port | S | F5 | `features/home/home_screen.dart`, `l10n/*.arb` |
| **P22** | Home: continue-strip caption + label copy align | port | S | F5 | `features/home/home_screen.dart`, `l10n/*.arb` |
| **P23** | Counting: remove "coming soon" price/3D placeholder rows | port | S | F2 | `features/rebuild/rebuild_screen.dart` |
| **P24** | Counting: "all accounted for" caption in part-detail sheet | port | S | F2 | `features/rebuild/rebuild_screen.dart` |
| **P25** | Counting: per-part step no longer persists (match oracle session-only) | port | S | F2 | `features/rebuild/{rebuild_repository,rebuild_screen,rebuild_models}.dart` |
| **P26** | Counting: "Set details" action in the ••• menu | port | S | F3 | `features/rebuild/rebuild_screen.dart` |
| **P27** | Counting: move "Remaining only" toggle into the settings sheet | port | S | F3 | `features/rebuild/rebuild_screen.dart` |
| **P28** | Catalog: `setsByIds` theme-name resolution (`CatalogSet.themeName`) | port | S | F3 | `features/catalog/{catalog_models,catalog_repository}.dart` |
| **P29** | Catalog: friendly `setNotFound` error instead of raw `.single()` throw | port | S | F5 | `features/catalog/catalog_repository.dart` |
| **P30** | Misc copy: report/menu/error strings (counting menu 10, review/error 4) | port | S | F5 | `l10n/*.arb` |

**F4 carve-out (confirmed S9 delta — owned by F4, listed for completeness, not new F1 work):**

| # | Item | Tag | Phase | Target |
|---|---|---|---|---|
| C1 | Reconnect → `syncNow` trigger (flush queued edits the instant network returns) | port | F4 | `app.dart` + new `core/.../network_monitor.dart` |
| C2 | `rebuild_sets.images_cached_at` column (prefetch-complete marker) → bump Drift `schemaVersion` to 4 | port | F4 | `core/db/app_database.dart` |
| C3 | Eager `ensureCached(id)` after a set is added | port | F4 | `features/catalog/set_detail_screen.dart` |
| C4 | Guarantee the set image is baked into the exported certificate (cold+offline) | port | F4 | `features/review/verification_report.dart` |

**F0 test-drift (fold-in):**

| # | Item | Tag | Phase | Target |
|---|---|---|---|---|
| T1 | `phase4_flow_test.dart:51` taps `find.text('Review')`; the counting header exposes Review as `Icons.flag_outlined` (`rebuild_screen.dart:372`). Fix: `find.byIcon(Icons.flag_outlined)`. Test-only, product path intact. | port | any | `integration_test/phase4_flow_test.dart` |

---

## Detail by phase

### F2 — fold into the design-system pass

- **P23 · Remove "coming soon" placeholder rows.** Swift dropped the price / 3D-preview dead-ends from
  the part-detail sheet (`RebuildSheets.swift:89-96` — BrickLink action only). Flutter still shows both
  disabled rows (`rebuild_screen.dart:1118-1125`); delete them and the unused `countPriceComingSoon` /
  `count3dPreviewComingSoon` strings.
- **P24 · "All accounted for" caption.** Swift shows `L.allAccountedFor` under the count when a part is
  complete (`RebuildSheets.swift:64-67`); Flutter only recolours the number (`rebuild_screen.dart:1081`).
- **P25 · Per-part step is session-only in the oracle.** Swift keeps the counting step in memory and
  resets to 1 on reopen (`RebuildViewModel.swift:26,60`; `step_qty` deliberately dropped,
  `RebuildRepository.swift:8`). Flutter persists it to Drift (`rebuild_repository.dart:370` `setPartStep`,
  read at `:314`). Stop reading/writing `step_qty` (leave the column for schema compat).
  ⚑ *Owner call:* this is a deliberate oracle simplification and arguably a minor UX regression — confirm
  we want to match it rather than keep the persisted step.

### F3 — with the adaptive layout / shell work

- **P1 · Party-join-as-guest cluster** ⚠ (the one shipped-behaviour divergence + the "join = guest"
  product decision). Frozen Flutter bounces a joiner to the paywall then sign-in
  (`profile_screen.dart:155-163`); the oracle lets anyone join as an anonymous "Golden Piece" guest —
  only *hosting* is premium (`PartyJoinView.swift:61-88`, `RootShell.swift:161-164`). Sub-parts:
  - Add `ensureGuestSession(displayName:)` → `signInAnonymously(data:{name})` and treat anonymous as
    signed-*out* in `isSignedIn`/`authStateProvider` (`auth_repository.dart`; oracle
    `AuthRepository.swift:50-56,35-40,99-109`).
  - Drop the `!isPremium → /paywall` / `!signedIn → /sign-in` gate on join; call `ensureGuestSession`
    before `joinParty` (`party_join_screen.dart:30-45`).
  - Promote Party to a 3rd top-level tab (`app_shell.dart:12-14`, Swift `RootShell.swift:7-9`) and add a
    `PartyLandingScreen` (Join CTA, host note, "you'll appear as {name}").
  - Classify join errors: `notFound` vs offline vs failed (`party_remote.dart` currently lets the raw
    `PostgrestException` propagate; `party_join_screen.dart:40-42` shows "check the code" for *every*
    failure). Oracle: `PartyJoinView.swift:80-86` + `PartyRemote.swift:87-98` (P0001).
  - Copy keys: `navParty`, `partyTabSubtitle`, `partyHostNote`, `partyAppearAs`, `partyJoinFailed`,
    `partyJoinOffline` (+ LT).
  - ⚠ **Blocked on server:** anonymous sign-ins must be enabled on the user project
    (`nthbhcqufiuyrnioxglm`) — the long-standing blocker. The join-error classification is independent
    and can land earlier (F2) if useful.
- **P26 · "Set details" ••• action** — jump from counting to the set's catalog detail
  (`RebuildView.swift:186-188`); Flutter's header row has no such affordance (`rebuild_screen.dart:391`).
  Lands with the native ••• menu.
- **P27 · "Remaining only" into the settings sheet** — Swift hosts it as the 2nd row of the view-settings
  sheet (`RebuildSheets.swift:374`); Flutter still has it as an inline header checkbox
  (`rebuild_screen.dart:420`). Filter *logic* is identical; this is placement, coupled to the header
  redesign.
- **P28 · `setsByIds` theme resolution** — Swift batch-joins `items → themes(name)` so a set fetched by
  id carries its theme (`SupabaseCatalogRepository.swift:84-97,204-205`; `CatalogSet.themeName`,
  `CatalogModels.swift:29`). Flutter's `setsByIds` doesn't (`catalog_repository.dart:100-106`). *Also a
  prerequisite for P4's theme filter* — the Home filter needs a theme on each summary.

### F4 — offline images (confirmed S9 delta, owned by F4)

C1–C4 above. These are the *expected* S9 work, not regressions — F1 confirms the sync/persistence/catalog/
report code is otherwise byte-identical, and that the offline-image seam is the only thing missing.
`rebuild_parts.step_qty` (Flutter-extra) and the diverging v3 migration rungs are **ignore** (see below);
when C2 adds `images_cached_at`, bump Flutter to `schemaVersion 4` with its own rung rather than mutating v3.

### F5 — reconciliation & polish (the bulk)

**Catalog / set detail**
- **P2 · Set lifecycle** — `SetLifecycle` enum + `launchDate`/`exitDate`/`retiringSoonDate`; a coloured
  status pill + an "Availability" card with month-precision dates. Swift `CatalogModels.swift:14,30-33`,
  `SupabaseCatalogRepository.swift:17,75-78,308-331`, `SetDetailScreen.swift:70-158`. **Needs** the
  detail-only column select (`launch_date, exit_date, retiring_soon_date, lifecycle_status` — Swift
  `:132-138`; Flutter `catalog_repository.dart:198-200` selects only `_setCols`) and the 9 lifecycle copy
  keys. Contract-risk: those four columns must exist on the catalog `sets` table.
- **P3 · BrickLink market value** — non-throwing read of `bricklink_price_guides`
  (`select new_or_used, qty_avg_price, avg_price, total_quantity, currency_code`,
  `eq guide_type 'sold'`; Swift `SupabaseCatalogRepository.swift:168-191`), skip `total_quantity==0`,
  value = `qty_avg_price ?? avg_price`, currency default "EUR"; a "Value" card with New(green)/Used(amber).
  Port `FlexDouble` tolerance (Postgres `numeric` may arrive as JSON number *or* quoted string). Verify
  the table/columns exist before porting.
- **P13 · Free-tier cap removed on Start sorting** — oracle adds sets unlimited (`SetDetailScreen.swift:6,
  277-295`); Flutter gates past `kFreeRebuildCap` behind the paywall (`set_detail_screen.dart:155-167`).
  Monetization policy — confirm with product; consistent with "join = guest, hosting stays premium".
- **P29 · `setNotFound` friendly error** — Swift `.limit(1)` + typed error
  (`SupabaseCatalogRepository.swift:139-141,295-303`); Flutter `.single()` surfaces a raw PostgREST error
  (`catalog_repository.dart:200`). Swap to `.maybeSingle()` + explicit not-found.

**Home / Profile**
- **P4 · Home theme + status filter** — the biggest single Home gap. Filter added sets by LEGO theme
  (OR-matched) + completion status, a header badge with the active-filter count, and a "No matching sets"
  empty state (`HomeScreen.swift:258-391`). Requires `RebuildSummary.theme` + a `backfillThemes()`
  (`HomeViewModel.swift:27`, `RebuildRepository.swift:201-217`) — theme is a local, catalog-derived,
  non-synced column. Copy: `homeNoMatch*`, the 13 filter-sheet keys.
- **P5 · Display-name generator** — Swift seeds a brick-themed random name on first launch
  (`DisplayNameController.swift:38-49`, `NameGenerator.swift:6-21`) used by the Profile name editor and
  guest-session metadata; Flutter has no name field at all. Word lists to reproduce — adjectives: *Brave,
  Sunny, Clever, Golden, Mighty, Swift, Jolly, Cosmic, Turbo, Nimble, Sparky, Lucky, Bold, Zippy, Cheery,
  Snappy*; nouns: *Brick, Stud, Minifig, Baseplate, Builder, Plate, Tile, Sorter, Block, Wrench, Cog,
  Piece, Bricklayer, Gearhead, Tinker*; format `"<Adjective> <Noun>"`, fallbacks `"Brave"`/`"Brick"`,
  24-char cap, prefs key `display_name`. *Feeds P1* (guest roster name).
- **P6 · Lifetime stats card** — `setsBuilt` (complete||verified) + `partsCollected` (Σ haveTotal) off the
  live summaries stream (`ProfileScreen.swift:15-17,66-94`); Flutter Profile has none.
- **P11 · Home list goes live** — Swift observes summaries via GRDB `ValueObservation`
  (`RebuildRepository.swift:170-186`) so progress updates in place; Flutter's `rebuildListProvider` is a
  one-shot `FutureProvider.autoDispose` (`rebuild_repository.dart:501-502`) that only refreshes on
  re-navigation/invalidate. Consider a `StreamProvider`. Low urgency (nav-back reloads).
- **P12 · Appearance row** — System/Light/Dark picker (`ProfileScreen.swift:36-38`, `ThemeController.swift`).
  Cheap UI; **inert until F2 lands the dark palette** — build the row in F5 wired to a controller, leave
  the `dark` mapping to F2. Don't double-count the dark-theme tokens (F2 owns those).
- **P16 · Pull-to-refresh syncNow** — `HomeScreen.swift:63` `.refreshable { syncNow() }` (no-op for
  free/guest); Flutter Home has no `RefreshIndicator`.
- **P17 · Remove manual "Sync now"** — the oracle deliberately retired it (`ProfileScreen.swift:33-35`);
  Flutter still shows it (`profile_screen.dart:113-132`). Auto-sync + P16 cover it.
- **P18 · Signed-out sign-in entry** — Swift's signed-out account card has an explicit "Sign in" button
  (`ProfileScreen.swift:126-128`); Flutter only offers "Turn on Cloud Sync" → paywall
  (`profile_screen.dart:104-112`), so a user who just wants to sign in is routed through the paywall.
- **P19 · About/version footer** (`ProfileScreen.swift:217-227`); Flutter has none.
- **P20 · "All sets" section header** (`HomeScreen.swift:161`); **P21 · empty-state** copy+icon ("No
  rebuilds yet" / "Search a set to start counting…" / `cube.box` vs Flutter's "No sets yet" /
  `grid_view`, `home_screen.dart:40-50`); **P22 · continue-strip** copy ("Continue building" + "X / Y
  parts", no %, vs Flutter "Continue rebuilding" + "X / Y · Z%", `home_screen.dart:76,131-137`).

**Auth / paywall**
- **P9 · Sign in with Apple (native)** ⚠ — oracle uses `ASAuthorizationController` + SHA-256 nonce →
  `signInWithIdToken(.apple)` (`AuthRepository.swift:62-66`, `SignInView.swift:36-49,133-172`); Flutter
  uses the OAuth web flow (`auth_repository.dart:31-37`). App Store review requires the native button +
  identity-token exchange when social login ships — a rejection risk. Needs the `sign_in_with_apple`
  package + nonce plumbing. *Distinct from the known server OAuth-provider gap — this is missing client
  code.*
- **P14 · Paywall** — oracle shows 3 benefits (Sync/Backup/Party), drops the "Unlimited" bullet, `PREMIUM`
  badge, reworded copy (`PaywallView.swift:13-17`); Flutter shows 4 incl. "Unlimited" + "Premium" badge.
  The free cap still exists, so dropping "Unlimited" is a deliberate offering change. No restore-purchases
  delta (billing deferred in both). Could fold into an F2 paywall UI rebuild.
- **P15 · Sign-in copy** — headline/subtitle/footer all reworded (`SignInView.swift:28-32,78`); fields,
  validation (`email.contains("@")`), and routing are identical — copy only.

**i18n / locale**
- **P8 · Language "System" + auto-detect** ⚠ — Swift defaults to `.system` on first launch and follows the
  device language (`LocaleController.swift`); Flutter has only `['en','lt']`, defaults EN, and
  `core/locale.dart` `_localeFor(null) → Locale('en')` is the exact line suppressing auto-detect. Add an
  `AppLanguage.system` (3rd picker row + `languageSystem` key): "System" ⇒ `MaterialApp.locale = null` and
  let `basicLocaleListResolution` over `[en,lt]` do the fallback; "System" clears the pref, `en`/`lt`
  persist. This also closes the Profile language-row gap (System option + picker-vs-toggle is cosmetic).
- **P30 · Misc copy** — the counting ••• menu strings (10: `moreActions`, `closeActions`, `menuReview`
  "Review & verify", `menuStartParty`, `menuSearchParts`, `menuSetDetails`, `allAccountedFor`,
  `remainingOnlyHint`, `ok`, `close`) and review/error strings (4: `reportTitle`, `shareMissingParts`,
  `appleNoToken`, `rebuildGone`). Land each with the screen that ports first; every ARB add must carry its
  LT string.
- The remaining Swift-only UI copy (set-detail 12, Home filter 13, Profile 18, Party 6) is **not** separate
  work — it lands with P2/P4/P5/P6/P1 respectively.

**Review**
- **P7 · Report date localization** — the injected `{date}` on the shared certificate is hardcoded English
  and in the wrong order (`verification_report.dart:184-192` `_months` array). Oracle uses
  `Date.FormatStyle(.abbreviated).locale(I18n.locale)` (`VerificationReportView.swift:118-120`) → "Jul 5,
  2026"; Flutter renders "5 Jul 2026" and, in the shipped **LT** locale, prints English months while every
  other report label is translated. Replace the getter with `DateFormat.yMMMd(localeName)` (intl). The rest
  of the report copy *is* localized — this is the only bug.

**Accessibility (cross-cutting)**
- **P10 · VoiceOver semantics** — counting part tiles and search rows have no `Semantics`
  (`rebuild_screen.dart:843,1294`); the oracle reads each tile as one actionable control with label/value/
  hint/rotor action (`PartTile.swift:95-103`, `RebuildSheets.swift:320-327`). Tiles are effectively opaque
  under VoiceOver today. This is an app-wide a11y workstream, not a pure counting port — track it as its own
  thread (the 11 Swift a11y string keys stay **ignore** unless we localize a11y labels, then ~11 ARB keys).

---

## Contract verification (the dangerous class — all MATCH)

Diffed character-for-character. **No mismatches found** — this is the F1 de-risk result.

| Contract | Verdict | Evidence |
|---|---|---|
| Sync wire: tables, columns, `onConflict` keys | **MATCH** | `rebuild_sets`(id), `rebuild_set_parts`(rebuild_set_id,part_item_id,color_id), `rebuild_minifigs`(rebuild_set_id,minifig_item_id), `verifications`(id) — full field lists identical |
| Sync: tombstones, conflict rule, excluded set | **MATCH** | boolean `deleted` col (no `deleted_at`); whole-row last-syncer-wins, pull skips `dirty`; `rebuild_extra_parts` never synced on either side |
| `verification.flags` jsonb keys | **MATCH** | `box`, `instructions`, `stickers`, `all_parts`, `minifigs` — same spelling/casing/underscores (`Verification.swift:26-32` / `verification_models.dart:36-52`) |
| BrickLink wanted-list XML | **MATCH** | same prolog, `<INVENTORY>`/`<ITEM>`/`<ITEMTYPE>P`/`<ITEMID>`/`<COLOR>?`/`<MINQTY>`, 2-space indent, filter, escape set (`WantedList.swift:24-45` / `wanted_list.dart:16-35`) |
| BrickLink deep-link / search URLs | **MATCH** | `/v2/catalog/catalogitem.page?P=<id>`, `/v2/search.page?q=<partNum>` |
| Party identity key `partItemId:colorId` | **MATCH** | single `:`, partItemId first, no padding (`RebuildModels.swift:42` / `rebuild_models.dart:37`) |
| Party RPCs + realtime + invite link | **MATCH** | `create_party{p_rebuild_set_id,p_name}`, `join_party{p_code}`, `party_progress{p_party_id}`, `party_have_counts{p_party_id}`; channel `party_<id>`, tables `party_contributions`+`party_members`; `brickback://party/<code>` |
| Catalog search + `expand_set_parts` RPC | **MATCH** | `_setCols`, `or(name.ilike/set_num.ilike)`, `gt(num_parts,0)`, `limit 25`, 300 ms debounce, min 2 chars; `bl_part_id`/`bl_color_id` parsed |
| Verification math / report content | **MATCH** | `partsMissing`, `partsComplete`, `minifigsComplete`, `pctLabel`, `flags={allParts, minifigsIncluded}`, missing-file scrub |
| Local schema (4 of 5 tables) | **MATCH** | `rebuild_minifigs`, `rebuild_extra_parts`, `verifications`(incl. `flags TEXT NOT NULL DEFAULT '{}'`) byte-identical; PKs/defaults/nullability all equal |

---

## Already-present (verified identical — no action)

Recorded so each seeded item is provably closed: **duplicate-set "#N" numbering** (byte parity),
**extras/spares device-local never-synced** (parity), **step map [1,5,10,20] + 350 ms debounce** (exact
match), **counting grouping/sorting/clamping/rollup + settings keys**, **entitlement read path + debug
force-premium toggle**, **session persistence/sign-out**, **pluralization** (ICU ⇄ String-Catalog map
1:1, all LT `few` categories present), **LT translation coverage** (all 201 keys, no holes), **catalog
image resolution** (`item_images kind=webp` → CDN, `rebrickable_img_url` fallback), plus the full
contract table above.

---

## Ignore (Swift-only mechanism / redesign artifact — do not chase)

- **S7/S10 visual redesign chrome:** set-detail badge chips + name-in-nav-bar; counting count-roll motion,
  adaptive tile width, progress-bar-vs-ring; Home header/add-set entry; native-toolbar migration across
  Party/Home/Review. These are the *intended* `ios/ui-redesign` direction — F2/F3 own the look; don't
  back-port the SwiftUI chrome, only the data/logic items above.
- **Framework mechanism:** `SyncController` actor/file split; timestamp-codec robustness asymmetry (Swift
  falls back to `Date()` on unparseable input, Flutter throws & aborts that round — only on malformed
  server data); GRDB TEXT vs Drift INTEGER timestamp storage (same instant).
- **Harmless Flutter extras:** `rebuild_parts.step_qty` column (persisted step is a benign superset — see
  P25 for the behavioural side); diverging v3 migration rungs (informational); part-detail celebration
  haptic + double-buzz suppression; party end-sheet toast (Flutter is *richer* here); `verifiedBadge` /
  `completeParts` copy nuance ("Verified ✓", pluralized).
- **Redesign/placement (owned elsewhere):** party card on Profile (owned by P1's Party-tab move); account-
  card avatar/status presentation; "Design gallery" dev button (strip before release).
- **i18n artifacts:** 11 VoiceOver-only string keys (Flutter attaches `Semantics` inline, doesn't route
  through ARB); month-name/date localization is a formatter concern (P7), not missing keys.
- **Carried server gap:** OAuth provider config + SMTP unbuilt in *both* clients — not a client delta
  (F0 item 6).

---

## Areas reviewed (F1 acceptance)

All nine areas explicitly diffed Swift↔Flutter:

- [x] **Catalog / search / set detail** — 2 seeded ports confirmed (lifecycle, price); search/RPC/image contracts identical.
- [x] **Counting engine** — both seeded items PARITY (extras never-synced; step map + 350 ms debounce); step-persistence is the only logic port.
- [x] **Review / verification / export** — `flags` keys + wanted-list XML + math byte-identical; report date is the one bug.
- [x] **Sync engine** — full wire contract byte-identical; only the S9 reconnect trigger missing (F4).
- [x] **Party mode** — identity key + RPCs + realtime + invite byte-identical; join-gating is the behavioural port.
- [x] **Auth / entitlement / paywall** — entitlement read identical; guest session + Apple-native + copy are the ports.
- [x] **Home / profile / settings** — "#N" numbering parity; filter, stats, name, appearance, copy are the ports.
- [x] **Persistence / schema** — 4/5 tables identical; the 2 diffs are F4-owned (`images_cached_at`) or harmless (`step_qty`).
- [x] **i18n content** — 236→201 keys, 63 UI strings ride with features, 11 a11y ignore; auto-detect is the one mechanism gap.

## Escalations (no port is larger than a phase)

Confirmed: **no "port" item needs its own phase** — the S7/S9/S10 big-ticket work is already carved into
F2/F3/F4. Two external dependencies gate otherwise-ready client work (both long-standing, tracked in the
migration README's open action items):

- **⚠ Anonymous sign-ins** on the user project (`nthbhcqufiuyrnioxglm`) — gates P1 (party join = guest)
  and P8's guest-session reuse. Client code is a real delta; the server flag is the blocker.
- **⚠ Apple/Google OAuth + SMTP** config — gates P9's *round-trip test* (the native Apple client code
  is portable now; only end-to-end verification waits on the provider config).
