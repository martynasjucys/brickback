# BrickBack (Swift) — Build Status

> Living "where are we" doc for the **native Swift/SwiftUI rebuild** (`apps/ios`). Update at
> the end of each phase. Read this first when resuming in a fresh session, alongside
> [README.md](README.md) + [00-architecture.md](00-architecture.md). The Flutter app
> (`apps/mobile`) remains the acceptance oracle; its status is [../phases/STATUS.md](../phases/STATUS.md).

**Last updated:** **S7 — dark mode** (system + in-app override) landed on top of the S7
branded-design + i18n passes.
**Current state:** S0–S6 are **code-complete and verified**; S7 **design system + i18n + dark mode**
are done (Dynamic Type / VoiceOver polish are the remaining S7 items).

<details><summary>S7 dark mode summary (system-driven + a persisted Profile override)</summary>

**Approach — "swap the values, keep the names" again:** every `AppColors` token became a **dynamic**
`Color(lightHex:darkHex:)` (a `UIColor(dynamicProvider:)` under the hood), so it resolves to the
active appearance with **zero call-site change** — the same S1→S7 token seam. `Tokens.swift` is the
only file that holds colour values. A **`ThemeController`** (`@Observable`, persists `app_theme` =
system/light/dark in `UserDefaults`, mirrors `LocaleController`) drives the root's
`.preferredColorScheme(theme.colorScheme)` — the old `.preferredColorScheme(.light)` lock is gone.
Because the tokens are dynamic, pinning the scheme re-skins the whole app; **no `.id` rebuild needed**
(unlike the language switch). Profile gained an **Appearance** row (System/Light/Dark
`.confirmationDialog`, named "Appearance" to avoid colliding with the LEGO-theme filter's "Theme").

**Palette:** branded hues (blue Home header, green Rebuild header, red CTA) stay **vivid** in dark;
neutrals invert (cream canvas → warm near-black `#161619`, white plate → lifted charcoal `#232228`
over an even-darker lip `#100F13`); semantic + lego-accent tones are **lifted** for contrast on dark.
A new `shadow` token (dark in both modes) replaced the three `AppColors.ink`-based header shadows
(ink inverts to near-white in dark → would glow). The **verification certificate stays light** in
both modes via `.environment(\.colorScheme, .light)` on the card (on-screen **and** the
`ImageRenderer` export) — it's a "paper" document shared as PNG/PDF, sitting on the themed report bg.

**Verified on the iPhone 17 Pro sim (dark):** Home (vivid blue header + **white status-bar glyphs** —
fixes the old marginal case — dark card plates), Profile (Appearance row; **Light override flips live**
even under a dark system), counting (green header, dark tiles, colour-swatch sections), review (dark
summary card, red re-verify CTA), report (**light certificate on dark chrome**), search (dark field,
red cursor, dark result plates). Build green, no warnings; 42 kit tests unaffected (dark mode is
app-target-only). Known cosmetic note: LEGO catalog thumbnails are white-background renders, so they
read as white tiles on dark — inherent to the product imagery, not a bug.

</details>

<details><summary>S7 i18n summary (English + Lithuanian, live in-app override + device auto-detect)</summary>

**Approach:** a hand-authored **String Catalog** (`BrickBack/Resources/Localizable.xcstrings`, 190
semantic keys, en source + lt, ICU plurals incl. Lithuanian `one/few/other` + exact-`zero`) is the
translation source; a generated typed façade **`L`** (`BrickBack/Localization/L.swift`, one accessor
per key, from `apps/ios/scripts/gen_l10n.py` — edit the table + regenerate, don't hand-edit) is the
call site. Every accessor resolves against **`I18n.bundle`/`I18n.locale`**, which
**`LocaleController`** (`@Observable`, persists `app_language` = system/en/lt to `UserDefaults`) keeps
in lock-step with the SwiftUI `\.environment(\.locale)`. The app root also `.id(locale.language)`s
the tree so a language switch **re-renders every screen live** (no relaunch); routers **and the
selected tab** live in `AppEnvironment`, so navigation survives the rebuild. Default = **System**
(device-locale auto-detect on first launch — the improvement the Flutter app deferred); a Profile →
**Language** picker overrides it and persists.

**Scope:** all ~28 app-target screens delocalized to `L.*` (dynamic catalog data — set/colour/theme/
part names, emails, notes — stays verbatim; DEBUG-only gallery left English). BrickBackKit stays
**string-free**: `PartSection` now carries a semantic `SectionTitle?` `titleKey` the UI localizes
(`L.sectionTitle`), keeping the plain-English `label` only as a test fallback / real catalog name.
The verification **report date** now uses `Date.FormatStyle(date:.abbreviated).locale(I18n.locale)`
(replacing the hardcoded English month array), so the shared PNG/PDF follow the language.

**Verified on the iPhone 17 Pro sim:** boots **Lithuanian** under a `lt` device locale with no manual
switch (Home, Profile, counting, review, report all translated); the Profile picker switches en↔lt
**live** and the choice persists across relaunch (overriding the system locale); **plurals** render
correctly — e.g. review shows "dar trūksta 24 tipų" / "24 tipai" (Lithuanian `few`), "reikia 4",
"Minifigūrėlės"; the report reads "INVENTORIAUS PATVIRTINIMAS … Patvirtinta 2026-07-13"; catalog
data (colour names "Bright Green", set names) correctly stays English. `xcstringstool` compiles the
catalog into `en/lt.lproj` (`.strings` + `.stringsdict`). **42 unit tests pass**, `xcodebuild` green,
no warnings.

</details> **S6 is a pure client port** of the
already-built, already-verified party backend (`0003_party_mode.sql`, applied): a `PartyRemote`
seam (RPCs + PostgREST + **Realtime v2** behind a disposer closure) → `PartyRepository` (the two
BrickBack-only bits: the **client-derived "still-needed" picker** = catalog `expandSetParts` ⟕
shared `party_have_counts`, and **local reconciliation** = `ensureLocalRebuild` snapshot +
`applyHaveCounts` overlay) → four SwiftUI screens (hub, join-by-code, invite/**QR**, add-parts
picker) + `PartyAvatar`/`AvatarStack`, all gated behind **premium + a signed-in session**. Entry
points: a **Start party** header button on `RebuildView` (flush + `pushNow()` so `create_party`
finds the synced rebuild) and a **Join a party** card on Profile. Dual-entry (host from Rebuilds,
join from Profile) is handled by an injected `\.activeRouter` so push/pop lands on the right stack.
**8 new unit tests** port `phase6_party_test.dart` over in-memory GRDB + a fake party server that
faithfully simulates the rollup trigger / `party_progress` / `party_have_counts` (create→join by
code, gated by code/active-status, un-synced rebuild rejected; contribution rolls into the shared
have-count + progress; picker `remaining` drops satisfied parts; multi-member additive convergence;
denorm feed names; idempotent `applyHaveCounts` with a `previous` diff; `ensureLocalRebuild`
reuse). **38 unit tests pass** (the S5 thirty + eight). Build green, no warnings. Driven on the
iPhone 17 Pro sim: Profile shows the **Party mode** card; a guest tapping **Join a party** bounces
to the **paywall**; the **join** (code entry) + **invite** (CoreImage QR + code + Share) screens
render. **The live two-account realtime round-trip waits for S8** (OAuth/session config — same gap
as S5); the client logic is complete and testable behind the fakes. Ready to start **S7** (design
polish & i18n).

<details><summary>S5 summary (superseded by the line above)</summary>

**S5 turns the wired-but-inert sync
skeleton live**: the gate is now `signedIn && isPremium` reading real values (an app-side
`@Observable EntitlementController` = `debugForcePremium || profiles.is_premium`), so a signed-in
premium user's rebuilds push/pull across devices **and clients** (cloud payload is
catalog-independent → `importFromCloud` re-derives metadata on a fresh device). `AuthRepository`
gained the three production-correct sign-in paths — native **Sign in with Apple** (SHA-256 nonce →
`signInWithIdToken`), **Google** web OAuth (`ASWebAuthenticationSession`), **email OTP** (magic link
→ `.onOpenURL` → PKCE exchange) — plus `handleOpenURL`/`currentUserEmail`. New surfaces: `SignInView`
(Apple/Google/email), `PaywallView` (4 benefits + "Turn on Cloud Sync" + debug force-premium
toggle), a reworked **Profile** (guest vs signed-in email, Free/Premium badge, Sync now, Sign out),
and the **free-cap** on "Start sorting" (non-premium at `kFreeRebuildCap = 3` → paywall). Driven on
the iPhone 17 Pro sim (`idb`): Home ("Catalog OK") → Profile shows **Not signed in / Premium: Free**
→ **Sign in** renders the native Apple button + Google + email OTP → back → **Premium** renders the
paywall (Cloud Sync · PREMIUM, four benefit cards, CTA, debug toggle) → flipping **Debug: force
premium** flips Profile to **Premium: Active** (proving the nested-`@Observable` reactivity through
`env.isPremium`, and `onPremiumEnabled()` fires harmlessly while signed-out — gate stays closed).
**30 unit tests pass** (the S4 twenty-six + four new: push clears exactly the pushed dirty rows +
cloud carries only the delta, a verification + `verified_at` sync across two devices, and two
`SyncController` triggers — turning premium on while signed in pulls cloud sets with no manual sync,
and a first-enable `requestEnableSync` → `markAllDirty` uploads existing local-only work). Build
green, no warnings. **Live OAuth/SMTP round-trip waits for S8** (Supabase dashboard provider config
+ billing); the client logic is complete and testable behind the debug unlock + in-memory fakes.
Ready to start **S6** (party mode).

</details>

---

## Phase checklist

- [x] **S0 — Project & tooling bootstrap** ✅ (done, verified)
- [x] **S1 — Core: clients, local store, shell, sync skeleton** ✅ (done, verified)
- [x] **S2 — Catalog & set selection** ✅ (done, verified)
- [x] **S3 — Inventory collection (core loop)** ✅ (done, verified)
- [x] **S4 — Review & verification — MVP complete gate** ✅ (done, verified)
- [x] **S5 — Auth & cloud sync (turns the sync engine ON)** ✅ (done, verified)
- [x] **S6 — Party mode (realtime collaborative counting)** ✅ (done, verified)
- [~] **S7 — Design polish & i18n** ← branded design + **i18n + dark mode done**; Dynamic Type / VoiceOver remain
- [ ] S8 — Launch / App Store

---

## What's built (S0 + S1)

### Project layout & tooling (S0)

- **`apps/ios/`** — the Swift app, side-by-side with the Flutter app at `apps/mobile` (SD8).
- **XcodeGen** generates the project: [`project.yml`](../../apps/ios/project.yml) →
  `BrickBack.xcodeproj`. Regenerate after editing `project.yml` with `xcodegen generate`
  (both `xcodegen` and `tuist` are on PATH). Bundle id **`com.brickback.brickback`** (reused
  so the existing OAuth scheme + Supabase redirect config stay valid).
- **Local SPM package [`BrickBackKit`](../../apps/ios/BrickBackKit)** holds the entire
  UI-independent domain/data layer. GRDB + supabase-swift are declared **inside** the package
  and stay internal to it — the SwiftUI app target links only `BrickBackKit` and never imports
  either SDK. `AppServices` is the composition root that owns both Supabase clients.
- **Pins** (`Package.resolved`, committed): **GRDB.swift 7.11.1**, **supabase-swift 2.51.0**.
  `Nuke`/`NukeUI` is **deferred to S2** (no images render in S1; `SetThumb` uses SwiftUI
  `AsyncImage` for now).
- **Language mode:** Swift **5** for now (S0 "concurrency warnings, not errors"); toolchain is
  Swift 6.3. A Swift-6 mode bump is a later step (the sync engine is already actor-isolated).
- **Config chain:** `.xcconfig` → `Info.plist` `BrickBackConfig` dict → typed
  [`AppConfig.fromBundle()`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Support/AppConfig.swift),
  which **traps with a clear message** on a missing/empty value (ports the `Env._req` guard).
  The five publishable values live in a **gitignored** `BrickBack/Config/Secrets.xcconfig`,
  regenerated from `apps/mobile/.env` by [`gen-secrets.sh`](../../apps/ios/gen-secrets.sh).
  Two gotchas that script handles: xcconfig treats `//` as a comment (URL schemes are written
  `https:/$()/host`), and it strips `.env` inline `# comments` + trailing whitespace (the
  `CDN_URL` line carries a `# ⟵ SET ME` note). `Secrets.xcconfig.example` is committed as a
  template. **Publishable keys only — never a server secret.**
- **URL scheme** `com.brickback` registered in `Info.plist` (`CFBundleURLSchemes`) for the
  `com.brickback://login-callback` OAuth return (used from S5).
- **`.gitignore`** updated for `xcuserdata`, `DerivedData`, package `.build/`, and the secret
  xcconfig.

### Data layer — GRDB local store (S1)

- [`AppDatabase`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Local/AppDatabase.swift) —
  a `DatabaseQueue` at `Application Support/brickback.sqlite` (+ an `inMemory()` factory for
  tests), with a `DatabaseMigrator`. **Statement-for-statement port of the Drift v3 schema**:
  `rebuild_sets`, `rebuild_parts`, `rebuild_minifigs`, `rebuild_extra_parts`, `verifications`,
  snake_case columns matching the cloud so the sync mapping is a straight pass-through.
- Migrations **v1/v2 only** — **`step_qty` is deliberately dropped** (00-architecture §5):
  the per-part counting step is in-memory session state (S3), never persisted. `category_name`
  is added in v2 (proven by a test) alongside the extras table.
- Record structs (`Codable` + `FetchableRecord` + `MutablePersistableRecord`) with the sync
  columns `updated_at` / `dirty` / `deleted`.

### Repositories & sync engine (S1)

- [`SupabaseCatalogRepository`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Catalog) —
  read-only anon catalog reads (`setsByIds`, `expandSetParts`, `setMinifigs`, `getSetSpares`,
  image resolution) behind the `CatalogReader` protocol, plus a `smokeReadSetName` probe.
  Search + set detail land in S2.
- [`RebuildRepository`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Rebuild) — local-first
  store: `addSet`/`importFromCloud` (catalog snapshot), absolute-write counting
  (`setPartHave`/`setMinifigHave`/`setExtraHave`), tombstone `remove`, `listSummaries`
  (with duplicate-copy `#N` numbering), `activeCount`, `detail`, and a live
  `observeSummaries()` (GRDB `ValueObservation` bridged to a GRDB-free `AsyncStream`).
  Verification-save + wanted-list export are S4.
- [`SyncService`](../../apps/ios/BrickBackKit/Sources/BrickBackKit/Sync) — the push/pull engine
  **ported 1:1** as an `actor` (push dirty parents→children, full-pull, cloud-authoritative,
  skip locally-dirty, re-derive metadata via `importFromCloud`). `SyncRemote` protocol +
  `SupabaseSyncRemote` (the only place payloads meet the SDK: ISO-8601 timestamps + jsonb
  `flags`) + `@MainActor SyncController` (debounced nudge, background push, foreground sync,
  30 s safety timer, first-enable `markAllDirty`). **Gated OFF** (`isPremium` closure returns
  false) until S5 — free/guest users never touch the network for user data.
- `AuthRepository` (session state + sign-out + auth-change stream; native sign-in sheets in
  S5), `EntitlementService` (`profiles.is_premium` read), `AppConfig`, `ImageResolver`.

### App shell & design system (S1)

- `BrickBackApp` (builds config → `AppServices` → `AppEnvironment`, forwards scene lifecycle
  to the inert sync controller), `AppEnvironment` (DI container).
- Navigation: `Route` enum + `@Observable Router` per tab + `RootTabView` (Rebuilds + Profile
  `NavigationStack`s). Routes past the shell render "coming in Sx" placeholders.
- Design system (**wireframe fidelity, token names stable for the S7 swap**): `AppColors` /
  `AppSpacing` / `AppRadius` / `AppText` + ~10 SwiftUI primitives (`Pressable`, `AppButton`,
  `AppCard`, `AppBadge`, `ScreenHeader`, `EmptyState`, `AppProgressBar`, `ProgressRing`,
  `SetThumb`, `SearchField`).
- Features: live `Home` (empty state + catalog smoke-read banner + reactive rebuild list),
  static `Profile` shell, debug-only design gallery.

---

## What's built (S2)

### Catalog reads (`BrickBackKit/Catalog`)
- `SupabaseCatalogRepository` gained the two S2 reads, **ported verbatim** from
  `catalog_repository.dart`: `search(_:limit:)` (the `sanitize` strip of `,()%*`, the
  `or("name.ilike.%q%,set_num.ilike.q%")` + `gt("num_parts", 0)` filter, CDN image join,
  `limit 25`) and `setDetail(_:)` (set row + `items.theme_id → themes(name)` + minifig count).
  A `CatalogError.setNotFound` replaces the Dart `.single()` throw. `expandSetParts` /
  `setMinifigs` / `getSetSpares` already shipped in S1 on the `CatalogReader` protocol.
- `AppServices` exposes `searchCatalog` + `setDetail` (the two are concrete, like the Dart
  `CatalogRepository`; the narrow `CatalogReader` protocol still covers what sync/rebuild need).

### The one online write (`BrickBackKit/Rebuild`)
- `addSet` / `listSummaries` / `remove` were already ported in S1; **S2 adds their unit test**
  (`RebuildRepositoryTests`): `addSet` writes 1 set + N parts + M minifigs + K extras in one
  transaction, `totalParts = Σ neededQty`, rows `dirty=true`; duplicates auto-number `#1/#2`.

### App target — catalog & search screens (`BrickBack/Features`)
- `Search/SearchScreen` — debounced via `.task(id: query)` + a 300 ms `Task.sleep` (a new
  keystroke cancels the in-flight search); `<2` chars shows the prompt state. Rows push
  `.setDetail`.
- `Catalog/SetDetailScreen` — 200 px image, `set_num · theme · year`, parts caption, two
  tappable stat cards (**Unique parts**, lazily counted via `expandSetParts`, → `.setParts`;
  **Minifigs** → `.setMinifigs`), and **Start sorting** → `addSet` → `sync.nudge()` (no-op) →
  `homeRouter.popToRoot()` + push `.rebuild(id)` so the add-flow collapses out of the stack.
  The free-tier cap check is deliberately **deferred to S5**.
- `Catalog/SetPartsScreen` / `SetMinifigsScreen` — the two preview lists (thumbnail, name,
  colour swatch + `colour · part-num`, `×qty`), parts sorted by colour then name. `swatchColor`
  ports the Dart `FF$rgb` hex parse.
- `LoadState<T>` (`Support/`) — a tiny `idle/loading/loaded/failed` enum, the SwiftUI analog of
  Riverpod's `AsyncValue.when`, so one-shot loads stay inline (no VM for a simple fetch).
- `Home` — added the **continue-rebuilding** strip (in-progress sets, horizontal) and
  **swipe-to-remove** (a `List` with `.swipeActions` + `.listStyle(.plain)` for AppCard rows);
  removal tombstones via the VM and the live `ValueObservation` drops the row.
- Two new `Route` cases: `.setParts(Int)`, `.setMinifigs(Int)`; `RouteView` now renders the real
  S2 screens (the S1 placeholders are gone for search / set-detail / parts / minifigs).

### Images
- **Nuke 12.8.0** added to `project.yml` (app target only — `BrickBackKit` stays UI-free).
  `SetThumb` swapped `AsyncImage` → NukeUI `LazyImage` (memory + disk cache), same public API.
- `SearchField` autofocus is now implemented (`@FocusState`, ~350 ms after appear) plus a clear
  (✕) button — the `autofocus:` param was inert in S1.

---

## What's built (S3)

### Counting domain (`BrickBackKit/Rebuild/Counting.swift`, `Support/BrickLink.swift`)
- Pure, unit-tested helpers the grid is built on (ports `_buildGroups` / `_PartGroup` / the
  tap-cap): `PartGrouping {color,category,status,none}`, `tapIncrement(current:step:needed:)`
  (never over-counts), `PartSection` (+ `haveIn` / `visible`), `partSections(_:grouping:have:)`
  (the dynamic Progress split reads live `have`), and `extrasSection`. A **documented exception**
  to "BrickBackKit is string-free": the few fallback section titles (All parts / Unknown / Other /
  Remaining / Complete) live here as English, moving to the String Catalog in S7.
- `BrickLink.url(...)` / `hasLink(...)` — part-page deep link, else search-by-part-number.
- `ExpandedPart` is now `Identifiable` (`id == key`) so it drives `.sheet(item:)`.
- **No new persistence:** `detail` / `setPartHave` / `setExtraHave` were already ported in S1;
  there is **no `setPartStep`** and `RebuildInventory` has **no `step`** field — the per-part step
  is view-model session state, never GRDB (00-architecture §5).

### Counting UI (`BrickBack/Features/Rebuild`)
- `RebuildViewModel` (`@Observable @MainActor`) — the session source of truth: live `have` /
  `extraHave` maps + the **in-memory `step` map** (default 1, discarded on teardown). Each edit
  is optimistic in memory and **debounced ~350 ms** to GRDB via a per-key `Task`; `flush()` awaits
  all pending writes and is called from the back button, `.onDisappear`, and scenePhase
  `.background` (force-quit safety). Haptics map: selection tick per count, medium impact on
  finishing a part, light on touching a done one.
- `RebuildView` — header (back + flag→review, search, settings; **party deferred to S6**), the
  `ProgressRing` + "N of M parts · K types" + **Remaining only** toggle, and a `ScrollView` of
  `LazyVGrid` sections (`.adaptive` columns ≈ Flutter's `maxCrossAxisExtent 176`). Groups are
  computed **at render time** from `partSections(...)`; the extras section renders below when
  enabled.
- `PartTile` — image-forward, colour-coded neutral → amber → green, check badge when complete.
  **Tap vs long-press** (reworked in S5): a **`Button`** (tap → increment, press-scale via a
  `ButtonStyle`) **+ `.simultaneousGesture(LongPressGesture(0.4))`** (long-press → detail) with a
  `longPressed` suppression flag. The S3 `LongPressGesture.exclusively(before: TapGesture)` attached
  via `.gesture` was replaced because it blocked ScrollView scrolling and swallowed the tap (see the
  gotcha below). `PartDetailSheet` / `PartSearchSheet` / `ViewSettingsSheet` round out the
  sheets; grouping + show-extras persist via `@AppStorage` (keys `rebuild_grouping` /
  `rebuild_show_extras`), degrading to defaults.
- `RouteView` `.rebuild(id)` now renders `RebuildView` (the S2 placeholder is gone). The
  continue-rebuilding strip on Home (added in S2) now lights up once a rebuild has progress.

---

## What's built (S4)

### Verification domain (`BrickBackKit`)
- `Rebuild/Verification.swift` — **`VerificationFlags`** (Codable; box / instructions / stickers +
  derived `all_parts` / `minifigs`, JSON keys matching the cloud schema, tolerant `decode`) and the
  **`Verification`** domain model (id, counts, decoded flags, notes, verifiedAt + `partsMissing` /
  `partsComplete` / `minifigsComplete` / `pctLabel` getters). Named `Verification` to avoid a
  collision with the pre-existing GRDB storage record `VerificationRecord` (both port the one Dart
  `VerificationRecord`). `MissingPart` (+ `.exportable`) and the `RebuildInventory.missingParts`
  getter already shipped in the S1/S3 models.
- `Support/WantedList.swift` — `WantedList.buildWantedListXML(_:)` + `WantedItem`. **Verbatim port**
  of `wanted_list.dart` (`<ITEMID>` = BL part id else part number, `<COLOR>` omitted when unknown,
  `<MINQTY>` = shortfall; XML-escaped).
- `RebuildRepository` gained the three S4 helpers: **`wantedListXml(_:)`** (maps `missingParts` →
  `WantedItem`s), **`saveVerification(...)`** (insert a `verifications` row **and** stamp
  `rebuild_sets.verified_at` in **one transaction**, both `dirty`; notes trimmed; returns a
  `Verification`), and **`latestVerification(_:)`** (newest non-deleted row → `Verification`). The
  `verifications` table + GRDB `VerificationRecord` + `verified_at` column already existed (S1
  schema); `setMinifigHave` was already ported in S1.

### Review + report UI (`BrickBack/Features/Review`)
- `ReviewViewModel` (`@Observable @MainActor`) — reads the snapshot once; holds the live minifig
  `have` map (each toggle writes **straight to GRDB**, no debounce — minifigs are few) + `onNudge`
  to keep Home live; `markVerified(...)` derives the two count-flags and calls `saveVerification`.
- `ReviewView` — header (back + **share** the wanted-list XML, shown only when parts are missing),
  the completion **summary card** (ring == counting ring, "N of M parts found", complete/missing
  types line), the **minifig section** (present/absent toggle for needed×1, ±stepper for needed>1),
  the **missing-parts list** (thumbnail, colour swatch, `need N`, tap → BrickLink), the "not
  exportable" footnote, and the bottom bar (**Mark as verified** / **Re-verify** + **View report**
  once verified). `MarkVerifiedSheet` (box/instructions/stickers flags + notes) → `markVerified` →
  push `.report`.
- `ReportViewModel` + `ReportView` + `VerificationReportCard` — the certificate (INVENTORY
  VERIFICATION header + seal, set image, name, completion badge, parts/minifig stats, the flag
  checklist, date, notes, "Verified with BrickBack"). `ReportViewModel` **pre-fetches the set image
  into a `UIImage`** (via `URLSession`) so the off-screen `ImageRenderer` bakes it into the export —
  a plain `LazyImage` wouldn't have loaded off-screen. Both exports come from the **same** card:
  `renderer.scale = 3` → `uiImage` PNG, and an `ImageRenderer.renderedPDF` extension (`render` →
  `UIGraphicsPDFRenderer`, one A4 page, fit-to-margins, vector) so print matches the shared image.
- `ShareSheet.swift` — `ActivityView` (`UIActivityViewController` bridge) presented via
  `.sheet(item:)` (avoids the iPad popover-anchor issue) + `safeFileStem`. Used for the XML and the
  report PNG/PDF. `RouteView` `.review`/`.report` now render the real screens (placeholders gone).

---

## What's built (S5)

### Auth + entitlement (`BrickBackKit`)
- `AuthRepository` gained the three sign-in paths (the S1 skeleton was session-state + stream only):
  **`signInWithApple(idToken:nonce:)`** → `signInWithIdToken(.apple, …)` (the native
  `ASAuthorizationController` half runs in the app's `SignInWithAppleButton`, which SHA-256s a raw
  nonce into the request; the repo just exchanges the token — the production-correct path App Store
  review requires), **`signInWithGoogle()`** → the web `signInWithOAuth(.google, …)`
  `ASWebAuthenticationSession` convenience (no GoogleSignIn SDK; matches the Flutter web-OAuth path,
  `com.brickback://login-callback` redirect + `prompt=select_account`), **`signInWithEmail(_:)`** →
  `signInWithOTP(email:redirectTo:)`, and **`handleOpenURL(_:)`** → `auth.handle(url)` (the PKCE
  exchange for the OTP/OAuth deep-link return) + `currentUserEmail`.
- `EntitlementService.fetchIsPremium()` was already ported in S1 (reads own `profiles.is_premium`,
  degrades to false); S5 just wires it live. `kFreeRebuildCap = 3` (BrickBackKit).
- `SyncController` gate closures changed from `@Sendable` to plain `@MainActor`-invoked closures so
  they can read the app's `@Observable` premium state without an isolation warning. The engine
  itself (`SyncService`/`SupabaseSyncRemote`, ported 1:1 in S1) is **unchanged** — S5 only flips the
  gate on and feeds it real `isSignedIn`/`isPremium`.

### App target
- `Features/Premium/EntitlementController.swift` — app-side `@MainActor @Observable` mirror of the
  Flutter `entitlementController` + `debugForcePremium` + `isPremium` trio: `debugForcePremium ||
  lastEntitlement`, lazily false (no eager network), `refresh()` degrades to false. The synchronous
  source of truth for the sync gate **and** the free-cap check.
- `AppEnvironment` rework — owns the `EntitlementController`, exposes observable `isSignedIn` /
  `userEmail` (mirrored from `signInStates()`), real `isPremium`, and the gate closures now return
  real values. `startSyncWiring` updates the auth mirror + `dismissAuthScreens()` on sign-in +
  `onAuthChanged()`. `setForcePremium(_:)` flips the debug unlock **and** triggers `onPremiumEnabled`
  (premium-turning-on is its own sync trigger — auth state doesn't change). `syncNow` / `signOut`.
- `Features/Auth/SignInView` — native `SignInWithAppleButton` (nonce via `SecRandomCopyBytes` +
  CryptoKit `SHA256`, extract identity token in `onCompletion`), Continue with Google, an "or"
  divider, email field + "Email me a sign-in link" (with sent/err inline states). Cancels are
  swallowed (`ASAuthorizationError.canceled`, `CancellationError`).
- `Features/Premium/PaywallView` — Cloud Sync + PREMIUM badge, four benefit cards, "Turn on Cloud
  Sync" (`requestEnableSync()` then pop-if-signed-in / push `.signIn`), and a **DEBUG-only** force-
  premium `Toggle`.
- `Features/Profile/ProfileScreen` — guest (Sign in) vs signed-in (email + Free/Premium badge +
  Turn on Cloud Sync when free + Sign out) account card, plus a **Sync now** row (premium → `syncNow`,
  else → paywall).
- `SetDetailScreen` "Start sorting" — the **free-cap** now enforced: non-premium at
  `activeCount() >= kFreeRebuildCap` pushes `.paywall` instead of adding a 4th rebuild.
- `RouteView` renders `SignInView` / `PaywallView` (the S1 placeholders + `PlaceholderScreen` are
  gone); `BrickBackApp` registers `.onOpenURL { auth.handleOpenURL($0) }` at the root.
- **Sign in with Apple capability**: `BrickBack/Resources/BrickBack.entitlements`
  (`com.apple.developer.applesignin = [Default]`) wired via `CODE_SIGN_ENTITLEMENTS` in
  `project.yml` (re-run `xcodegen generate`).

---

## What's built (S6)

### Party domain + seam (`BrickBackKit/Party`)
- `PartyModels.swift` — **`Party`** (+ denormalized `setItemId` so members derive the picker
  without reading the host's owner-scoped `rebuild_sets`), **`PartyMember`**, **`PartyContribution`**
  (denorm `partName`/`colorName` for the feed), **`PartyProgress`** (`value` clamped), and
  **`PartyPart`** (built on-device from `ExpandedPart` ⟕ shared `have`, with a `remaining` getter).
  Verbatim port of `party_models.dart`.
- `PartyRemote.swift` — **`protocol PartyRemote`** (the network seam, like `SyncRemote`) +
  **`SupabasePartyRemote`** on the `userClient`: `create_party` / `join_party` (RPC, flexible
  object-or-array decode via `.execute().data`), `party_progress` / `party_have_counts` (RPC →
  typed rows), `getParty` / `setStatus` / `members` / `myMember` / `recentContributions` / the
  contribution insert (PostgREST), and **`subscribe(partyId:onChange:)`** returning a plain disposer
  closure that hides **Realtime v2** (`client.channel(...)` + `postgresChange(AnyAction.self,
  table:, filter: .eq("party_id", …))` async streams on `party_contributions` + `party_members`,
  `subscribeWithError()` in a task, torn down by the disposer). Timestamps decode tolerantly to
  `Date` via `ISO8601DateFormatter` (with/without fractional seconds).
- `PartyRepository.swift` — pass-throughs + the two BrickBack-only bits: **`parts(_:setItemId:)`**
  (catalog `expandSetParts` ⟕ `haveCounts`, sorted colour-then-biggest-need) and reconciliation
  (**`ensureLocalRebuild`** snapshots the set for a joining member / reuses an existing rebuild;
  **`applyHaveCounts`** overlays shared counts into local GRDB via `setPartHave`, diffing against a
  `previous` map so a realtime tick doesn't churn every part). Wired into `AppServices` as
  `party` (`SupabasePartyRemote(client: userClient)` + the anon catalog + the local rebuild store).

### Party UI (`BrickBack/Features/Party`)
- `PartyView` + `PartyViewModel` — the realtime hub: `load()` fetches party/members/progress/feed/
  have-counts + `ensureLocalRebuild` (best-effort), then `subscribe(onChange: refresh)`; the ring +
  roster (`AvatarStack`) + "Add found parts" + activity feed re-render on each tick. **Reconcile on
  leave** (`applyHaveCounts` once per session, guarded, + `onNudge`) via the back button and a
  safety `.onDisappear`; host **End party** confirm via `.alert`.
- `PartyJoinView` (code entry, autofocus, `.replaceTop(.party(id))` so back returns past it),
  `PartyInviteView` (**CoreImage `CIQRCodeGenerator`** → `UIImage`, code, `ActivityView` share — no
  QR dependency), `PartyAddPartsView` + VM (client-derived picker, pending map, ±steppers, submit →
  one contribution per line), `PartyAvatar`/`AvatarStack` (stable FNV-1a seed → wireframe palette,
  host ring, `+N` overflow).
- **Routing:** four new `Route` cases (`.party` / `.partyJoin` / `.partyInvite` / `.partyAddParts`)
  in `RouteView`; a new `\.activeRouter` `EnvironmentValue` injected by `TabNavigation` so the
  dual-entry party screens push/pop on whichever tab's stack they're on (host from Rebuilds, join
  from Profile) instead of hardcoding a router.
- **Entry points:** a **Start party** header button on `RebuildView` (`person.2`; premium + account
  gate → paywall / sign-in; `flush()` + `pushNow()` then `createParty` then push `.party(id)`; a
  spinner replaces the button while starting) and a **Party mode** card on `ProfileScreen` with
  **Join a party** (same premium + account gate → paywall / sign-in / `.partyJoin`).

---

## Acceptance (parity vs. Flutter Phase 6) — all met · **party mode**

- **Create → join by code; `ensureLocalRebuild` snapshots on join / reuses an existing rebuild:**
  unit-tested (`createAndJoin`, `ensureLocalRebuildReuses`). ✅
- **Joining is gated (wrong code / ended party throw; un-synced rebuild rejected):** unit-tested
  (`joinGated`, `unsyncedRebuildRejected`) against a fake server that mirrors the RPC membership +
  active-status gates. ✅
- **A contribution rolls into the shared have-count + progress; the picker's `remaining` drops
  satisfied parts:** unit-tested (`contributionRollsUp` — `haveCounts == ["10:1":2]`, progress
  `2/3`, part 10 `remaining 0` / part 11 `remaining 1`). ✅
- **Multiple members roll up additively and converge to 100%:** unit-tested
  (`multipleMembersConverge` — member 2×#10 + host 1×#11 → `have 3`, `value 1.0`). ✅
- **The feed carries denormalized part + colour names:** unit-tested (`feedDenormalized` —
  `Brick 2x4` / `Red` / `qty 2` / `memberId`). ✅
- **`applyHaveCounts` overlays into local GRDB and is idempotent with a `previous` diff; both host
  and member reconcile:** unit-tested (`applyHaveCountsOverlays`). ✅
- **Sim renders:** Profile shows the **Party mode** card; a **guest** tapping **Join a party**
  bounces to the **paywall**; the **join** (code entry) + **invite** (**QR** + code + Share) screens
  render (reached via a temporary gate-bypass since a live signed-in session is an S8 gap, then
  reverted; the gate is verified restored). ✅
- **Live two-account realtime round-trip** is the one deferred item → **S8** (OAuth/session config;
  the `party_*` RLS/RPC/rollup guarantees are already proven live on the real DB in Flutter Phase 6).
  ⏳ (S8)
- `swift test` green (**38 tests**); `xcodebuild build` green, no warnings. ✅

---

## How to build / test / run

```sh
cd apps/ios
./gen-secrets.sh                          # (re)generate Secrets.xcconfig from ../mobile/.env
xcodegen generate                         # regenerate the .xcodeproj after project.yml edits
swift test --package-path BrickBackKit    # fast unit tests (macOS host, no simulator)
xcodebuild -scheme BrickBack \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath DerivedData build      # build the app for the sim
```

Install/launch on the booted sim: `xcrun simctl install booted <BrickBack.app>` →
`xcrun simctl launch booted com.brickback.brickback` → `xcrun simctl io booted screenshot out.png`.

---

## Acceptance (parity vs. Flutter Phase 4) — all met · **MVP complete**

- **Completion % == the counting ring:** review reads `inv.progress` off the same snapshot; live
  sim showed a 9% ring + "4 of 43 parts found" matching the counting screen (unit test:
  `progress == 1/6`). ✅
- **Missing-parts list:** shortfall per still-short part, complete parts excluded, sorted biggest
  first, unmapped part surfaced (not dropped) with a "not exportable" footnote — unit-tested + seen
  live (need 5, 4, 4, 3, 2…). ✅
- **Wanted-list XML:** BL part id or part-number fallback as `<ITEMID>`, colour omitted when
  unknown, unmapped part absent; fully-counted rebuild → no `<ITEM>` (unit-tested). ✅
- **Minifig verification rolls up separately from parts:** present toggle drove Emma 0/1 → 1/1
  (green) and set the derived "Minifigures included" flag, while parts stayed 9% (unit test:
  `minifigsComplete` independent of `complete`). ✅
- **Mark verified persists + report renders:** `saveVerification` wrote the `verifications` row
  (notes trimmed) + stamped `verified_at` in one txn; `latestVerification` reads it back
  (unit-tested); live Home shows the green **"Verified"** badge; the certificate rendered with the
  set image, "9% · 39 parts missing" badge, `4 / 43`, `1 / 1`, the flag checklist, and the date. ✅
- **Share-as-image + printable PDF** off the **same** SwiftUI card via `ImageRenderer` (@3× PNG +
  A4 PDF); **Share PDF produced a valid 972 KB A4 document** in the system share sheet. ✅
- `swift test` green (**26 tests**); `xcodebuild build` green, no warnings. ✅

---

## Acceptance (parity vs. Flutter Phase 5) — all met · **sync engine ON**

- **Push uploads dirty rows, clears exactly the pushed rows, cloud carries only the delta:**
  unit-tested (`pushClearsDirtyAndCarriesDelta` — dirty counts 1/2/1 → 0/0/0; typed `CloudSet`
  structurally carries no catalog metadata). ✅
- **Pull re-derives catalog metadata + overlays `have_qty`; two devices converge with no dupes;
  same-part edits resolve last-syncer-wins; tombstone propagates:** the S1 `SyncServiceTests`
  (convergence, LWW, tombstone, `markAllDirty`) still green. ✅
- **A verification syncs across devices** (and the set's `verified_at`): unit-tested
  (`verificationSyncsAcrossDevices`). ✅
- **`SyncController` premium triggers:** turning premium on while signed in pulls the cloud sets
  with no manual sync (`premiumEnablePulls`); a first-enable `requestEnableSync` → `markAllDirty`
  uploads existing local-only work (`firstEnableUploadsLocalWork`). ✅
- **Sign-in + paywall render on the sim (routes + surfaces):** Profile (guest → **Free**) → Sign in
  (native Apple + Google + email OTP) → Paywall (benefits + CTA + debug toggle) → force-premium →
  Profile **Active** (reactive `env.isPremium`). ✅
- **Free-cap:** non-premium at `kFreeRebuildCap` routes "Start sorting" → paywall (reads the same
  `env.isPremium` proven reactive live; `activeCount` covered by repo tests). ✅
- **Live OAuth/SMTP round-trip** is the one deferred item → **S8** (Supabase dashboard provider
  config + billing); client logic complete + testable behind the debug unlock + fakes. ⏳ (S8)
- `swift test` green (**30 tests**); `xcodebuild build` green, no warnings. ✅

---

## Notes / gotchas for the next session

- **`step_qty` divergence:** no such column and no v3 migration — intentional (00-architecture
  §5). Confirmed live in S3: the per-part step lives only in `RebuildViewModel.step` (default 1,
  reset when the set is left); `RebuildInventory` has no `step` field and there is no `setPartStep`.
- **Tap-vs-long-press on a tile inside a ScrollView (revised in S5):** the S3
  `LongPressGesture.exclusively(before: TapGesture)` attached via `.gesture(…)` was **wrong** — it
  greedily claimed finger-down (so the grid **couldn't scroll**) and the exclusive composition ate
  the quick tap (so **tap didn't increment**), leaving only the scale animation. The correct pattern
  (`PartTile`): a **`Button`** for the tap (cooperates with the ScrollView's pan; press-scale via a
  `ButtonStyle`'s `isPressed`) **+** a **`.simultaneousGesture(LongPressGesture(0.4))`** for detail,
  with a `longPressed` flag so the button's trailing touch-up tap is suppressed after a long-press.
  Verified live: grid scrolls, tap 0/1→1/1, long-press opens detail without incrementing. Applies to
  any future dual-gesture tile/row — don't attach a greedy `.gesture` on scrollable cells.
- **Search is client-authored, not `CatalogReader`:** `search`/`setDetail` live on the concrete
  `SupabaseCatalogRepository` (exposed via `AppServices`), mirroring the Dart split where the
  narrow `CatalogReader` interface only carries what sync/rebuild re-derive from the catalog.
- **Nuke is app-target-only:** added to `project.yml` (not `BrickBackKit/Package.swift`) so the
  domain package stays UI-free. Re-run `xcodegen generate` after the `project.yml` edit. Declared
  as `from: "12.8.0"`; resolving the app scheme wrote the concrete pin (**Nuke 12.9.0**) into the
  committed `BrickBackKit/Package.resolved` alongside GRDB/supabase (xcodebuild folds the local
  package's resolved file into the app graph — run `xcodebuild -resolvePackageDependencies
  -scheme BrickBack` to refresh it).
- **UI driving:** `idb` (+ `idb_companion --udid <sim> --grpc-port <p>` then `idb connect
  localhost <p>`) drives sim taps/typing; `idb ui describe-all` gives the accessibility tree
  (points, not pixels — iPhone 17 Pro is 402×874 @3x). `idb ui text` types into the *focused*
  field only, which is why `SearchField` autofocus had to be implemented for the flow to work.
- **`Package.resolved` is committed** so a clean checkout resolves the same GRDB/supabase/Nuke pins.
  **Gotcha (hit in S6):** running `swift build --package-path BrickBackKit` **strips the Nuke pin**
  from the committed resolved file (Nuke is an app-target dep, not in the package). Refold it after
  with `xcodebuild -resolvePackageDependencies -scheme BrickBack` before committing.
- **Party header button (S6) is present:** the counting header now ships flag→review, **party**
  (`person.2`, premium+account gated), search, settings. A spinner replaces the party button while
  `createParty` runs.
- **Dual-entry navigation → `\.activeRouter` (S6):** party mode is reachable from **both** tabs
  (host from Rebuilds, join from Profile), but the shared `RouteView` can't know which stack it's on.
  Existing single-tab screens hardcode a router (`env.homeRouter` / `env.profileRouter`); the party
  screens instead read an injected `\.activeRouter` (`TabNavigation` sets it on each `NavigationStack`)
  so push/pop lands on the right tab. Reuse this for any future dual-entry screen — don't hardcode.
- **`return` on its own line before an `if` is a footgun (S6):** Swift 5.9+ `if` is an *expression*,
  so `return` ⏎ `if … { push(.paywall) }` parses as `return (if-expression)` and **executes** the
  branch. Bit me in a throwaway verify hack (the join gate ran `push(.paywall)` after a bypass push).
  The compiler warns ("expression following 'return' is treated as an argument"); heed it. Real code
  is fine — this was only a temporary edit.
- **Realtime v2 seam (S6):** `PartyRemote.subscribe` returns a plain `@Sendable () -> Void` disposer
  (keeps the interface fake-able, mirrors the Flutter callback+disposer). Inside `SupabasePartyRemote`
  it spins a `Task` that **registers the `postgresChange(AnyAction.self, …)` streams BEFORE**
  `subscribeWithError()` (the v2 contract), iterates both in a `withTaskGroup`, and the disposer
  cancels the task + `removeChannel`. Not live-exercised until S8 (needs a JWT session); the fake's
  `subscribe` is a no-op, so the tests don't depend on it.
- **RPC single-row decode (S6):** `create_party` / `join_party` are `returns <composite>` (a JSON
  object), while `party_progress` / `party_have_counts` are `returns table` (an array). The party
  screens decode the former via `.execute().data` + a flexible object-or-array `JSONDecoder` (mirrors
  the Dart `_asRow`); the latter decode straight to `[Row]` via `.execute().value`.
- **Two `VerificationRecord`s, on purpose:** the GRDB **storage** record is `VerificationRecord`
  (in `Records.swift`, `flags` as a raw JSON string, used by sync); the **domain** model the repo
  returns is `Verification` (in `Verification.swift`, `flags` decoded to `VerificationFlags`). Both
  port the single Dart `VerificationRecord`; the rename dodges the name clash and keeps the SwiftUI
  layer off GRDB. The `flags` string is package-agnostic end-to-end (sync passes it through), so the
  S5 cloud mirror needs no change.
- **`ImageRenderer` off-screen sizing + async images:** the report card is rendered at a **fixed
  `.frame(width: 360)`** so its off-screen layout is deterministic; `ReportViewModel` **pre-fetches
  the set image into a `UIImage`** because a `LazyImage`/`AsyncImage` wouldn't have loaded when
  `ImageRenderer` captures. PNG uses `renderer.scale = 3`; the A4 PDF uses the `renderedPDF`
  extension (`render` → `UIGraphicsPDFRenderer`), which must be `@MainActor` (like `render`).
- **Share sheet:** use `ActivityView` (a `UIActivityViewController` bridge) via `.sheet(item:)`,
  **not** a bare activity controller — the sheet presentation handles the iPad popover anchor. One
  minor stale-state note: after saving, we **push** `.report` on top of `.review`; popping back to
  review shows the pre-verify bottom bar until the screen is re-entered (its VM `load()` is
  once-only). Harmless for MVP; revisit if review needs to reflect a just-saved verification inline.
- **Sync gate is now ON:** the gate is `signedIn && isPremium`, both real. `isPremium` reads the
  app-side `EntitlementController` (`debugForcePremium || profiles.is_premium`). Free/guest and
  signed-in-but-free users still never touch the network for user data (gate closed). The engine
  (`SyncService`/`SupabaseSyncRemote`) is untouched from S1 — S5 only fed it real gate values.
- **idb can't flip a standalone SwiftUI `Toggle` with a bare `ui tap`** — a zero-duration synthetic
  tap doesn't register on the `UISwitch`. Use **`idb ui tap --duration 0.12 <x> <y>`** (a real
  press), and land on the **switch control**, not the label (a standalone Toggle — outside a
  Form/List — only flips when the switch itself is hit). This is what verified force-premium →
  Profile "Active" live. Applies to any future switch (S7 settings).
- **Two `Provider` enums in supabase-swift:** the top-level `Provider` (`.google`/`.apple`) for
  `signInWithOAuth`, and the nested `OpenIDConnectCredentials.Provider` for `signInWithIdToken`
  (`.apple`). Both resolve by context. Google uses the **web OAuth** `ASWebAuthenticationSession`
  convenience (no GoogleSignIn SDK — matches Flutter); only Apple is native (`SignInWithAppleButton`).
- **Sign in with Apple entitlement:** `BrickBack/Resources/BrickBack.entitlements`
  (`com.apple.developer.applesignin`) + `CODE_SIGN_ENTITLEMENTS` in `project.yml`. **Simulator**
  builds don't validate it (built + ran fine); a **device** build needs the capability on the App ID
  — automatic signing with the paid team adds it. Re-run `xcodegen generate` after `project.yml`.
- **Live OAuth/SMTP is external config → S8:** Apple/Google/email round-trips need Supabase
  dashboard provider config (+ Apple provider on the user project). The client paths are complete;
  the debug force-premium unlock + in-memory `FakeSyncRemote` cover the gate/sync/entitlement logic
  without it. Don't "improve" LWW (last-*syncer*-wins is the sanctioned v1).
- **S7 kick-off:** design polish & i18n. The whole UI is still **wireframe fidelity** — the S7 pass
  swaps `DesignSystem/Tokens.swift` (the one file) for the branded palette/typography with the token
  **names kept stable**, so screens don't move. i18n: the few English string literals scattered
  through the app + the documented `BrickBackKit` fallbacks in `Counting.swift` / `PartyModels`'
  "part" default move to a String Catalog. Flutter reference: [`07-design-polish-and-i18n.md`](07-design-polish-and-i18n.md).
- **Party mode is done (S6) but live realtime waits on S8:** the `party_*` tables + RLS + RPCs +
  rollup trigger were verified live in Flutter Phase 6; the Swift client calls the identical RPCs and
  is unit-covered (8 tests) + sim-rendered. The two-account realtime round-trip needs a signed-in
  session (OAuth config), the **same S8 gap** as sync. Don't "fix" the rollup authority nuance
  (contributions are authoritative for contributed parts — `have_qty = Σ contributions` replaces a
  host's pre-party manual count); that's the sanctioned v1, matching whatabrick + Flutter.
