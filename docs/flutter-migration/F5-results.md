# F5 — Reconciliation & polish · results (in progress)

> Burning down the F1 reconciliation backlog to reach side-by-side parity with the Swift oracle
> (`apps/ios`), then retiring Swift. Each cluster is verified `flutter analyze` clean + full test
> suite green before moving on. Baseline entering F5: **analyze clean, 40/40 tests**.

## Status by backlog item

| Item | What | Status |
|---|---|---|
| P2 | Set lifecycle stage + availability dates on set detail | ✅ done |
| P3 | BrickLink market value card on set detail | ✅ done |
| P7 | Verification report date localization (intl DateFormat) | ✅ done |
| P13 | Free-tier rebuild cap removed on "Start sorting" | ✅ done |
| P25 | Counting per-part step is session-only (stop persisting `step_qty`) | ✅ done |
| P26 | "Set details" action from counting → catalog detail | ✅ done |
| P27 | "Remaining only" moved into the view-settings sheet | ✅ done |
| P28 | `setsByIds` theme-name resolution (`CatalogSet.themeName`) | ✅ done |
| P29 | Friendly `setNotFound` error (`.maybeSingle` + typed exception) | ✅ done |
| P10 | Rich VoiceOver semantics on part tiles + search rows | ✅ done |
| P4 | Home theme + status filter (sheet, badge, backfill, no-match state) | ✅ done |
| P11 | Home list live (StreamProvider over Drift) | ✅ done |
| P16 | Home pull-to-refresh forces cloud sync | ✅ done |
| P20 | "All sets" section header | ✅ done |
| P21 | Home empty-state copy + icon | ✅ done |
| P22 | Continue-strip label + caption copy | ✅ done |
| P5 | Display-name brick generator + Profile name editor | ✅ done |
| P6 | Profile lifetime stats card (Sets built / Parts collected) | ✅ done |
| P12 | Appearance row (System / Light / Dark) | ✅ done |
| P17 | Remove manual "Sync now" button | ✅ done |
| P18 | Explicit signed-out "Sign in" entry (not via paywall) | ✅ done |
| P19 | Profile About / version footer | ✅ done |
| P9 | Sign in with Apple — native token exchange (client code) | ✅ code; ⚠ needs iOS capability + Supabase Apple provider for round-trip |
| P14 | Paywall offering + copy drift (3 benefits, PREMIUM badge) | ✅ done |
| P15 | Sign-in screen copy drift | ✅ done |
| P8 | Language "System" option + first-launch device auto-detect | ✅ done |
| P30 | Misc copy (counting menu, remaining-only hint) | ✅ landed with its screens |
| P1 | Party join = free guest — session, gate drop, Party tab, landing, error classes | ✅ done (anon sign-ins already enabled) |

## Cluster A — Catalog / set detail (P2, P3, P13, P28, P29)

- `catalog_models.dart`: added `SetLifecycle` enum (`upcoming`/`available`/`retiring_soon`/`retired`,
  with `fromRaw`), lifecycle + date fields (`themeName`, `lifecycle`, `launchDate`, `exitDate`,
  `retiringSoonDate`) on `CatalogSet`, a `SetPrice` value type, and `price` on `SetDetail`.
- `catalog_repository.dart`: `_setDetailCols` pulls the four lifecycle columns; `_parseDate`
  (UTC "yyyy-MM-dd") + `_flexDouble` (numeric-as-number-or-string tolerance) helpers;
  `_toSet` parses lifecycle safely (null where not selected); `setsByIds` now batch-resolves
  theme names (P28); `setDetail` uses `.maybeSingle()` + throws `CatalogSetNotFound` (P29) and
  reads a non-throwing BrickLink `sold` price (P3, skip `total_quantity==0`, `qty_avg_price ??
  avg_price`, EUR default).
- `set_detail_screen.dart`: coloured lifecycle pill + "Availability" card (release/retirement
  rows, month-precision localised dates) + "Value" card (New green / Used amber, localised
  currency). Removed the free-tier cap on Start sorting (P13) — adding a set is unlimited, premium
  gates only hosting + cloud sync, matching the oracle.
- `main.dart`: `initializeDateFormatting()` so LT month/number formatting works.
- l10n: 13 new keys (lifecycle/date/value), en + lt.

## Cluster B — Review report date (P7)

- `verification_report.dart`: replaced the hardcoded English `_months` array with
  `DateFormat.yMMMd(localeName)` (intl) — the certificate's date now localises (LT month names
  fixed), abbreviated style "Jul 8, 2026" matching the oracle. Test updated to the new format.

## Cluster C — Counting (P25, P26, P27, P10)

- P25: counting step is session-only — dropped the `step_qty` seed-on-load and the persist call
  in `_setStepFor` (column kept for schema compat).
- P26: added a "Set details" header action (info button) → `/set/:setItemId`.
- P27: removed the inline header "Remaining only" checkbox; added it as a toggle row in the
  view-settings sheet (above "Show extras", matching oracle order). `_SettingsSheet` is now a
  `ConsumerStatefulWidget` taking the session filter + change callback.
- P10: `Semantics` wrappers collapse each part tile and search row into one screen-reader control
  — label ("Brick 2×4, Red"), value ("3 of 5[, complete]"), hint ("Adds one"), activate = +1,
  and a named "Details" custom action (only where a detail sheet exists). Header action buttons
  gained semantic labels.
- l10n: 10 new keys (menu labels, remaining-only hint, a11y label/value/hint/details), en + lt.

## Cluster D — Home (P4, P11, P16, P20, P21, P22)

- `RebuildSummary` gained `theme` (local, catalog-derived, non-synced). `rebuild_sets.theme`
  column already existed; `addSet` now captures `themeName` at add-time (via P28), `listSummaries`
  selects it, and a new `backfillThemes()` fills it in for pre-existing / cloud-pulled sets
  (distinct sets with `theme IS NULL`, resolved via `setsByIds`, written back without marking rows
  dirty — sync never touches `theme`).
- P11: `rebuildListProvider` is now a `StreamProvider` over `watchSummaries()`, which re-derives
  the list on any `rebuild_sets`/`rebuild_parts` change (`tableUpdates`) — Home updates in place.
- P4: `HomeScreen` is now stateful, holds a `_HomeFilter` (themes OR-matched + status all/
  incomplete/complete), triggers `backfillThemes()` on init, shows a header filter button with an
  active-count badge, a filter bottom-sheet (status chips + present-theme pills, live-applied,
  Done / Clear all), a "No matching sets" empty state with Clear filter, and prunes selected
  themes whose last set was removed.
- P16: the "All sets" list is wrapped in a `RefreshIndicator` → `syncNow()` (no-op for free/guest).
- P20: "All sets" section header above the list. P21: empty-state now "No rebuilds yet" /
  "Search a set to start counting…" with a box icon. P22: continue strip is "Continue building"
  with an "X / Y parts" caption (no percentage).
- l10n: 19 new keys (filter sheet, statuses, empty/no-match, continue/all-sets, parts-have-total),
  homeEmptyTitle/Message updated, en + lt.

## Cluster E — Profile (P5, P6, P12, P17, P18, P19)

- New `core/display_name.dart`: `NameGenerator` (16 adjectives × 15 nouns) + `DisplayNameController`
  (Notifier<String>, persists `display_name`, seeds a random name on first launch, never blank,
  24-char cap) — feeds the party guest-session name (P1).
- P6: `_StatsCard` at the top — Sets built (complete||verified) + Parts collected (Σ haveTotal),
  off the live `rebuildListProvider`, locale-grouped numbers, one semantics node per stat.
- P5: `_NameCard` row + `_NameEditorSheet` (text field + shuffle button + Save).
- P12: `_AppearanceCard` — System / Light / Dark, wired to the existing `themeControllerProvider`
  (already drives `MaterialApp.themeMode`).
- P17: dropped the manual "Sync now" button from the sync card.
- P18: signed-out users get an explicit "Sign in" button (→ `/sign-in`, not through the paywall).
- P19: `_AboutFooter` — "BrickBack" + "v{version}" (version from `core/app_info.dart`, kept in
  sync with pubspec by hand to avoid a `package_info_plus` native dependency).
- The "Design gallery" dev button is **kept** for now — flagged for removal before release in the
  cross-cutting sweep.
- l10n: 14 new keys (stats, name editor, appearance, sign-in prompt), en + lt.

## Cluster F — Auth / paywall (P9, P14, P15)

- P9: `auth_repository.signInWithApple()` is now the **native** flow on Apple platforms — a random
  nonce, `sha256`-hashed into the `SignInWithApple.getAppleIDCredential` request, then
  `signInWithIdToken(provider: apple, idToken, nonce: rawNonce)` (oracle
  AuthRepository.swift:62-66). Non-Apple platforms fall back to the web OAuth flow. Added the
  `sign_in_with_apple` dependency. **Round-trip is server/native-config blocked**: needs the
  Apple provider configured on the Supabase dashboard and the "Sign in with Apple" capability added
  to the iOS Runner target (`Runner.entitlements` + `com.apple.developer.applesignin`) — the client
  code is complete and compiles.
- P14: paywall now shows **three** benefits (Cloud sync / Safe backup / Party mode) — dropped
  "Unlimited" (the free cap is gone, P13) — with a `PREMIUM` badge and reworded headline/CTA copy.
- P15: sign-in headline / subtitle / footer reworded to the oracle copy.
- l10n: `premiumBadge` added; paywall + sign-in copy updated; `benefitUnlimited*` / `benefitPartyTitle`
  removed. en + lt.

### Follow-ups for P9 (not client code)
- iOS: add the "Sign in with Apple" capability to the Runner target.
- Supabase: configure the Apple auth provider (+ Google + SMTP) on the user project — the standing
  server-config blocker, shared with P1/P8.

## Cluster G — i18n / locale (P8, P30, plural check)

- P8: `LocaleController` is now `Notifier<Locale?>` — `null` follows the device (first-launch
  auto-detect via `basicLocaleListResolution` over `[en, lt]`), so a Lithuanian device comes up
  Lithuanian with no manual switch. New `AppLanguage` enum (system / en / lt); "System" clears the
  pref, en/lt persist. The Profile language card is now a 3-way picker (System / English /
  Lietuvių). `MaterialApp.locale` already reads the provider.
- P30: the counting-menu + remaining-only-hint copy landed with Cluster C; the residual
  review/error edge strings (`reportTitle`/`shareMissingParts`/`rebuildGone`) stay with the review
  screen (not re-ported in F5 beyond P7). The Apple "no identity token" error is an internal
  message on a rare path (not user-copy).
- Plural check: confirmed the LT `one/few/other` forms are correct and **locked with tests**
  (`test/f5_reconciliation_test.dart`) at counts 0/1/2/5/10/21 for `partsCount`,
  `partyMemberCount`, `uniquePartsCount` — the classic `few` (2–9) miss is covered.
- New unit coverage: `SetLifecycle.fromRaw`, `SetPrice.hasAny`, `NameGenerator.random` format,
  plus the LT plurals — 8 new tests (**48/48** total).

## Cluster H — Party join = guest (P1)

> The standing blocker (anonymous sign-ins on the user project) was **already enabled**, so this
> is the full, live client implementation — not scaffolding.

- `auth_repository.dart`: `ensureGuestSession({displayName})` mints a transparent anonymous session
  (stamping the name into `raw_user_meta_data.name`) only when signed out; `isSignedIn` now means a
  **real** (non-anonymous) account and `isAnonymous` exposes the guest state. New `isSignedInProvider`.
- The "signed in" notion is now real-account-only everywhere it gates premium/sync/UI: the sync
  controller's default check, the `/sign-in` router redirect, the paywall's post-CTA routing, and
  the Profile account card all treat a guest session as signed-out.
- `party_join_screen.dart`: mints a guest session (carrying the display name) before `joinParty`,
  and classifies failures — `P0001` → "check the code", offline → "you're offline", else → generic
  "couldn't join" (replacing the old blame-the-code-for-everything message).
- **Party is now a first-class tab**: added a `/party` `StatefulShellRoute` branch (order Rebuilds
  0 / Party 1 / Profile 2), a three-tab phone bottom bar, and a new `PartyLandingScreen` (Join CTA,
  "you'll appear as {name}", premium host note). The old Profile "Party mode" join card is removed;
  the sidebar Party destination now lands on `/party`.
- l10n: `partyJoinOffline`, `partyJoinFailed`, `partyHostNote`, `partyAppearAs` added, en + lt.

## Cluster I — Cross-cutting sweep + acceptance

**Dark-mode sweep.** Migrated the remaining light-only `AppColors.*` surfaces to theme-aware
`BrickColors.of(context)`: `rebuild_screen.dart` (52 refs — the counting screen), plus
`set_parts_screen`, `set_minifigs_screen`, `party_add_parts_screen`, `party_avatar` (chrome only —
the avatar identity palette stays fixed), and `review_screen`. Deliberately left fixed:
`verification_report.dart` (printable certificate), `party_invite_screen.dart` (QR-scanner
contrast), `design_gallery.dart` (dev).

**Root dark-mode bug found on the simulator + fixed.** `AppText._base` baked a fixed light
`AppColors.ink` (and `caption` baked light `inkSoft`), so every un-overridden `Text` rendered
dark-on-dark in dark mode (F3's dark screenshots were never actually captured). Removed the baked
colours so `AppText.*` inherits the Material theme's brightness-correct ink
(`textTheme.apply(bodyColor: c.ink)`). Pinned the always-light verification certificate to dark ink
via `DefaultTextStyle.merge` so it stays correct in either app theme. Verified light unchanged +
dark legible on the sim.

**Contract re-check (F1 dangerous class).** Confirmed byte-unchanged by F5: the sync wire (my new
`theme` column, like `images_cached_at`, never enters push/pull), the `verification.flags` jsonb
keys, the party identity key `$partItemId:$colorId`, and the BrickLink wanted-list XML + deep-link
URLs.

**Simulator acceptance (iPhone 16 Pro, iOS 18.6).** Built (the new `sign_in_with_apple` pod
integrates via CocoaPods), installed, launched — no crash. Verified in **light + dark**: Home
(filter button, "All sets", continue strip, 3-tab bar), the Party landing (join card, "You'll
appear as Lucky Stud" — the P5 generator produced a real brick name, host note), and Profile
(stats, name row, sync + explicit sign-in, appearance picker, party card removed). The appearance
picker flips the theme live. Screenshots under the job tmp dir.

**Not visually driven** (code-complete + analyze/48-tests green, deferred from the sim pass): the
counting screen a11y semantics, set-detail lifecycle/value cards (conditional on catalog
data), and the en/lt + tablet-orientation matrix. The counting widget test (`phase3_counting_test`)
exercises the counting path headlessly.

**Acceptance status:** `flutter analyze` clean; **48/48** unit tests; app builds + runs. All 30
`port` backlog items closed.
