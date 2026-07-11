# S5 — Auth & premium cloud sync

> Turn on the wired-but-inert sync skeleton. Sign-in (native Apple + Google + email OTP),
> premium entitlement (`profiles.is_premium`), the live push/pull engine, the free-project
> cap, and the paywall. **The MVP flow is untouched for free/guest users** — nothing leaves
> the device until premium sync is on.

Flutter reference: [`../phases/05-auth-and-cloud-sync.md`](../phases/05-auth-and-cloud-sync.md) +
[STATUS Phase 5](../phases/STATUS.md#what-changed-in-phase-5). Sources:
[`sync_service.dart`](../../apps/mobile/lib/core/sync/sync_service.dart),
[`sync_remote.dart`](../../apps/mobile/lib/core/sync/sync_remote.dart),
[`entitlement.dart`](../../apps/mobile/lib/core/entitlement.dart),
[`auth_repository.dart`](../../apps/mobile/lib/features/auth/auth_repository.dart),
[`sign_in_screen.dart`](../../apps/mobile/lib/features/auth/sign_in_screen.dart),
[`paywall_screen.dart`](../../apps/mobile/lib/features/premium/paywall_screen.dart).

### Goal
A signed-in premium user's rebuilds sync across devices **and across clients** (a Flutter
user's cloud data appears in the Swift app on pull — [00 §9](00-architecture.md#9-no-data-migration-the-clean-slate-advantage)).

### Scope
**In:** `AuthRepository` (Apple/Google/email OTP), `authStateChanges` stream, the
`EntitlementService` (`profiles.is_premium`) + debug force-premium, the real `SyncService` /
`SyncController` gating flipped on, `importFromCloud` (re-derive metadata on pull),
`activeCount` free-cap check on "Start sorting" → paywall, sign-in + paywall screens, Profile
auth state.
**Out:** RevenueCat/StoreKit billing wiring (S8 — the flag is flipped by a debug toggle here);
the external OAuth/SMTP dashboard config (S8 checklist).

### Deliverables

**`BrickBackKit/Auth` + `Entitlement`**
- `AuthRepository` on `userClient.auth`:
  - **Apple:** native `ASAuthorizationController` → `userClient.auth.signInWithIdToken(
    credentials: .init(provider: .apple, idToken:, nonce:))` (better than the Flutter
    web-redirect; required by App Store review anyway).
  - **Google:** GoogleSignIn SDK idToken → `signInWithIdToken(provider: .google, …)`, or the
    web `signInWithOAuth` fallback. Same `com.brickback://login-callback` redirect.
  - **Email OTP:** `signInWithOTP(email:, redirectTo:)`; handle the return in `.onOpenURL` →
    `userClient.auth.session(from: url)`.
  - `signOut()`, `currentSession`, and an `authStateChanges` `AsyncStream` the router + sync
    controller both consume.
- `EntitlementService.fetchIsPremium()` — read own `profiles.is_premium`, degrade to `false`
  on any error (local-first). Port the exact fallback semantics. `isPremium` is a computed
  value: `debugForcePremium || lastFetched`. `kFreeRebuildCap = 3`.

**`BrickBackKit/Sync`** — flip the S1 skeleton live:
- `SupabaseSyncRemote` upserts/fetches on `userClient` with the exact `onConflict` keys and
  1000-row paging from [`sync_remote.dart`](../../apps/mobile/lib/core/sync/sync_remote.dart).
- `SyncService.pushDirty/fullSync/markAllDirty` — the push-then-cloud-authoritative algorithm,
  pulls skipping locally-dirty rows, `importFromCloud` re-deriving catalog metadata. **Port
  statement-for-statement** from [`sync_service.dart`](../../apps/mobile/lib/core/sync/sync_service.dart).
- `SyncController` gate `enabled = signedIn && isPremium` now returns real values; wire the
  30 s timer, the `authStateChanges` listener (`onAuthChanged` → refresh entitlement → first
  upload via `markAllDirty` → `syncNow`), the premium-flip listener (`onPremiumEnabled`), and
  `requestEnableSync`. Drive `pushNow`/`syncNow` from `ScenePhase`.

**App target**
- `Features/Auth/SignInView` — Continue with Apple / Continue with Google / Email me a sign-in
  link.
- `Features/Premium/PaywallView` — benefit list + "Turn on Cloud Sync" CTA + debug force-premium
  toggle.
- `Features/Profile` — Guest vs signed-in email, Free/Premium badge, Turn on Cloud Sync / Sync
  now / Sign out.
- `SetDetailView` "Start sorting" — enforce the free cap (non-premium at
  `kFreeRebuildCap` → paywall instead of a 4th add).
- Router: add `.signIn` + `.paywall`; bounce away from sign-in once a session exists.

### Swift specifics
- **`SyncService` as an `actor`** (see [00 §6](00-architecture.md#6-sync-engine-ported-11)) —
  the `_running` guard becomes actor isolation. Keep the `SyncRemote` protocol + in-memory
  fake so the two-device convergence tests stay network-free.
- **Sign in with Apple** must use `ASAuthorizationAppleIDProvider` + a nonce; store nothing
  client-side beyond what Supabase needs. This is the production-correct path the Flutter app
  stubbed.
- **Deep link:** register `.onOpenURL` at the app root; forward OAuth/OTP returns to
  `userClient.auth`. supabase-swift does the PKCE exchange.

### Acceptance (parity vs. Flutter Phase 5)
Port `test/phase5_sync_test.dart` to two in-memory GRDB "devices" sharing one fake remote +
fake catalog: **push** uploads dirty rows, clears exactly the pushed rows, cloud set carries
only the delta (no metadata); **pull** on a fresh device re-derives catalog metadata + overlays
`have_qty`; two devices editing different parts converge with no dupes; same-part edits resolve
last-syncer-wins; **tombstone** propagates; a **verification syncs**; `markAllDirty` re-flags
everything. Live (once OAuth is configured in S8): sign in on two real devices → a set counted
on A appears on B with re-derived names. Sign-in + paywall screens render on the sim now
(routes + surfaces), matching the Flutter Phase-5 integration test.

### Risks
- **OAuth/SMTP are external config** (Supabase dashboard) — the same open item the Flutter
  plan carries; the client logic is fully testable without it (debug force-premium + fakes),
  live round-trip waits for S8.
- **Clock skew / LWW:** last-*syncer*-wins is the sanctioned v1 (documented deferral); don't
  silently "improve" it — parity first.
