# S8 — Launch: billing, external config, App Store

> The launch gate. Wire IAP → `profiles.is_premium`, finish the external OAuth/SMTP config the
> backend has been waiting on since the Flutter Phase 5/6, satisfy Apple's native-app
> requirements (privacy manifest, ATT if needed, review), and ship via TestFlight → App Store.

Flutter references: the "still external" notes in [STATUS Phase 5/6](../phases/STATUS.md#what-changed-in-phase-5)
and the open action items in [`../phases/README.md`](../phases/README.md#open-action-items-user).

### Goal
BrickBack is live on the App Store with working premium sign-in, cloud sync, and party mode on
real accounts.

### Scope
**In:** billing (RevenueCat or StoreKit 2) flipping `is_premium` via webhook; the Supabase Auth
dashboard config (Google/Apple OAuth + SMTP + redirect allow-list); iOS privacy manifest +
App Store privacy labels; Sign in with Apple entitlement; TestFlight; the live acceptance
checks that need real sessions; App Store submission.
**Out:** nothing product-facing — this is release engineering + the inherited external config.

### Deliverables

**Billing (SD9)**
- Integrate **RevenueCat** (fastest) or **StoreKit 2** directly. On a successful purchase, a
  **server webhook flips `profiles.is_premium`** (the app only ever *reads* the flag — the
  design is already in [`entitlement.dart`](../../apps/mobile/lib/core/entitlement.dart) and
  the RLS makes `is_premium` non-client-writable). Remove/guard the debug force-premium toggle
  for release builds.
- App Store Connect products (premium subscription/one-time), restore-purchases, and the
  paywall bound to real offerings.

**External config (inherited, backend-side — not code)**
- Enable **Google + Apple OAuth** and **SMTP** on the user project's Supabase Auth dashboard.
- Add `com.brickback://login-callback` to the **redirect allow-list**.
- Configure Sign in with Apple: the **Apple Developer** Service ID / key, and the app's
  **Sign in with Apple capability/entitlement**.
- Consider upgrading the BrickBack Supabase org **off the free plan** before party mode's
  realtime load (a flagged item in the Flutter plan).

**Apple requirements**
- **`PrivacyInfo.xcprivacy`** privacy manifest + **App Store privacy nutrition labels**
  (account, user content on premium sync; nothing for free/local users — the clean privacy
  story from [00 §8](00-architecture.md#8-security--privacy-model-unchanged)).
- App icon, screenshots (both languages), App Store description, keywords, support URL, the
  [marketing site](../phases/08-marketing-site.md) (already built) as the marketing URL.
- Export-compliance, age rating, and **Sign in with Apple** presence (required since Google
  social login ships).

**Release engineering**
- `fastlane` lanes for build/sign/upload; Xcode Cloud or GitHub Actions release workflow.
- **TestFlight** beta → internal + external testers.

### Live acceptance checks (finally possible with real sessions)
These were provably-deferred in the Flutter plan because they need real auth; run them now on
the Swift client:
- **Cross-device / cross-client sync:** count a set on device A → it appears on device B with
  re-derived catalog metadata; and a Flutter-created cloud account's data appears in the Swift
  app (proves [00 §9](00-architecture.md#9-no-data-migration-the-clean-slate-advantage)).
- **Two-account party realtime:** host creates → member joins by code/QR → contributions roll
  up live → non-member is blocked → host-only end. (The RLS/RPC/rollup logic is already proven
  server-side; this proves the transport on real accounts.)
- **Billing:** purchase → webhook → `is_premium` flips → sync + party unlock; restore works.

### Acceptance
App approved and live; a fresh TestFlight install can sign in (all three providers), buy
premium, sync across two devices, and run a two-person party — all on production infrastructure.

### Risks
- **App Store review:** Sign in with Apple must be present and functional; the privacy manifest
  must be accurate; guard debug-only unlocks out of release builds.
- **OAuth/SMTP config is the long pole** — it's been the one open external item since the
  Flutter Phase 5. Start it early in S8 (or in parallel from S5) so it's not the thing blocking
  submission.
- **Free-plan limits** under real party/realtime load — validate before a public push.
