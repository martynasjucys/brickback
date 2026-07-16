# F0 — Revive & baseline

> **Status: ✅ Done (2026-07-16).** Results, evidence, and the F1 reconciliation backlog:
> [`F0-results.md`](F0-results.md). Baseline screenshots: [`baseline/`](baseline/).

> Get the frozen Flutter app (`apps/mobile`, last touched 2026-07-11) building and running
> against the **live** backend again, refresh toolchain/deps, smoke-test Phases 1–6, and stand up
> the Swift app as the side-by-side **oracle**. This phase writes almost no product code — it
> proves the ~90% that already exists still works, so later phases build on solid ground.

Swift oracle: the whole `apps/ios` app. Flutter target: `apps/mobile`.

### Goal

`flutter run` on a simulator/device shows the BrickBack MVP — search a set, add it, count, review,
export — talking to the real catalog + user Supabase projects, with sync and party mode live. No
new features; a green baseline.

### What already exists in Flutter

Everything in Phases 1–6 (see [`../phases/README.md`](../phases/README.md)): `lib/core` (env, two
Supabase clients, entitlement, locale, Drift v3, sync engine), `lib/features/*` (home, search,
catalog, rebuild, review, auth, premium, party, profile, shell), `lib/l10n` (en+lt), plus
`test/` (6) and `integration_test/` (7). The `.env` is present and populated.

### Tasks

1. **Toolchain check.** Confirm the Flutter/Dart SDK satisfies `pubspec.yaml` (Dart `^3.11.0`).
   Record the exact `flutter --version` used, so agents are reproducible. Flutter lives at
   `~/development/flutter` (not on PATH — see project memory).
2. **Dependencies.** `flutter pub get`. Re-run codegen: `dart run build_runner build
   --delete-conflicting-outputs` (Drift `app_database.g.dart`) and regenerate l10n (`generate:
   true`). Resolve any dep that no longer resolves; prefer minimal bumps over major upgrades this
   phase (a dependency-modernization pass is out of scope — note anything risky for later).
3. **Secrets.** Verify `apps/mobile/.env` still has valid `USER_SUPABASE_URL/ANON_KEY`,
   `CATALOG_SUPABASE_URL/ANON_KEY`, `CDN_URL`. Cross-check values against the Swift app's config
   (`apps/ios/BrickBackKit/.../Support/AppConfig.swift` / the `.xcconfig`) — they must be identical.
4. **Build & run.** iOS simulator first (fastest loop), then confirm a **release** build on a real
   device if convenient (project memory notes real-iPad testing quirks). Android is optional this
   phase but a quick `flutter run` on an emulator is a cheap signal that the "Android for free"
   premise holds.
5. **Smoke-test 1–6 against live backend** (guest, then signed-in premium via the debug unlock):
   search → add set → count (offline too) → review → verify → export wanted-list/PDF; enable sync
   and confirm push/pull; create + join a party by code and see a contribution roll up.
6. **Run the suites.** `flutter test` (unit) and the `integration_test/` flows; record pass/fail.
   These are the regression net for F2–F5.
7. **Stand up the oracle.** Get the Swift app (`apps/ios`) building/running on a sim so every later
   phase can compare screens side-by-side. Note the iPad sim UDIDs from
   [`../ios-swift/10-adaptive-layout.md`](../ios-swift/10-adaptive-layout.md) §Verification.
8. **Baseline capture.** Screenshot every Flutter screen (light + dark, iPhone width) and the
   matching Swift screen. This is the "before" set F2/F3 are measured against.

### Flutter specifics

- Two Supabase clients (`core/supabase.dart`): `userClient` (auth) + `catalogClient` (anon,
  read-only). Never conflate them — same hard constraint as the Swift app.
- Drift schema is at **v3**; migrations are real. Don't reset the local DB casually — exercise the
  migration path at least once.
- `.env` is a bundled asset via `flutter_dotenv`; make sure it's still listed under `assets:`.

### Acceptance

- Cold `flutter run` reaches the Home screen with no missing-env/codegen errors.
- All six MVP flows work end-to-end against the **live** projects, guest and premium.
- `flutter test` + integration flows pass (or every failure is triaged and logged as an F1 item).
- Swift app runs beside it on a sim; baseline screenshots captured for both.

### Risks

- **Dep rot in ~6 months of ecosystem churn** (Riverpod 3, go_router 17, Drift 2.34). A transitive
  break is possible; keep bumps minimal and quarantine anything that wants a major upgrade.
- **Codegen drift** (`build_runner`) if the analyzer/SDK moved — regenerate, don't hand-edit `.g.dart`.
- **Stale `.env` / rotated keys.** If a project key was rotated since July, pull the current one
  (MCP-reachable user project; catalog key from the Swift `.xcconfig`).
