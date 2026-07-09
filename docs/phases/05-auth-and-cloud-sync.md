# Phase 5 — Auth & Premium Cloud Sync

**Goal:** turn on accounts and the **premium** value prop — cloud sync across devices,
unlimited projects. Free tier keeps working exactly as before (local-only, no account).
This is the first phase that writes to the **BrickBack user project**.

MVP: — (first post-MVP phase; the monetization foundation)

Product: "Cloud Sync (Premium) — save unlimited projects, sync across devices."

---

## Scope

**In:**
- Supabase auth on the **user project** (providers per D5: Apple + Google + email OTP; guest by default).
- Premium gating (entitlement check) + a paywall surface.
- Cloud mirror tables + owner RLS on the user project.
- The sync engine (already skeletoned in [01](01-foundation.md)) goes live: local Drift ⇄ user project, gated behind `signedIn && isPremium`.
- Free-tier project cap (D7 default: 1–3 local rebuilds) with an upsell.

**Out:** party mode ([06](06-party-mode.md)); server-side reporting; multi-device conflict UI beyond last-write-wins.

---

## Tasks

### 5.1 Auth (user project)
- Configure providers in the user project: **Apple** (required for App Store if any social login ships), **Google**, **email OTP/magic link**. Reuse whatabrick's OAuth pattern (`signInWithOAuth`, `redirectTo: 'com.brickback://login-callback'`, `authScreenLaunchMode: externalApplication`).
- `auth_repository.dart` + `sign_in_screen.dart` (wireframe): the three buttons. `authStateProvider = StreamProvider(userClient.auth.onAuthStateChange)`.
- **App stays fully usable logged-out** (local-first). Sign-in is only prompted when the user taps a premium feature or "turn on sync". Router redirect stays minimal (only bounce away from `/sign-in` when a session exists) — reuse whatabrick's approach.

### 5.2 Entitlement / premium
- `isPremiumProvider` — source of truth TBD (D7): options are RevenueCat (App Store/Play IAP), or a `profiles.is_premium` flag on the user project set by a webhook. **Recommend RevenueCat** for cross-store IAP + entitlement without building billing. Gate: sync + party + unlimited projects.
- Paywall screen (wireframe): "Sync across devices, unlimited sets, party mode."
- Free cap: when adding a set beyond the free limit, show the paywall instead of creating the rebuild.

### 5.3 Cloud schema (user project migration)
Owner-scoped, **no catalog FKs** (catalog is a different project — [00 §2](00-architecture.md#2-the-two-database-split)). Mirrors the local Drift tables minus the metadata snapshot:

```sql
-- rebuild_sets: which set, how many parts, verified?
create table rebuild_sets (
  id uuid primary key,                         -- client-generated (== local)
  user_id uuid not null references auth.users(id) on delete cascade,
  set_item_id bigint not null,                 -- plain int, NOT an FK (catalog is elsewhere)
  total_parts integer not null default 0,
  verified_at timestamptz,
  updated_at timestamptz not null default now(),
  deleted boolean not null default false
);
create index rebuild_sets_user_idx on rebuild_sets(user_id, updated_at desc);

-- rebuild_set_parts: only the have-count delta (metadata re-derived from catalog on pull)
create table rebuild_set_parts (
  rebuild_set_id uuid not null references rebuild_sets(id) on delete cascade,
  part_item_id bigint not null,                -- plain int
  color_id integer not null,                   -- plain int
  have_qty integer not null default 0 check (have_qty >= 0),
  updated_at timestamptz not null default now(),
  deleted boolean not null default false,
  primary key (rebuild_set_id, part_item_id, color_id)
);

create table rebuild_minifigs (
  rebuild_set_id uuid not null references rebuild_sets(id) on delete cascade,
  minifig_item_id bigint not null,
  have_qty integer not null default 0,
  updated_at timestamptz not null default now(),
  deleted boolean not null default false,
  primary key (rebuild_set_id, minifig_item_id)
);

create table verifications (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  rebuild_set_id uuid not null references rebuild_sets(id) on delete cascade,
  set_item_id bigint not null,
  completion_pct real not null default 0,
  parts_needed int, parts_found int,
  minifigs_needed int, minifigs_found int,
  flags jsonb not null default '{}',
  notes text,
  verified_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted boolean not null default false
);
```
RLS: enable on all; owner policies `auth.uid() = user_id` (for child tables, `exists (select 1 from rebuild_sets r where r.id = rebuild_set_id and r.user_id = auth.uid())`) — mirror whatabrick's `rebuild_*` policies. Regenerate `packages/shared` types.

### 5.4 Sync engine live (reuse)
- Un-gate `sync_service.dart` / `SyncController` for `signedIn && isPremium`: push all `dirty` local rows (`upsert` with `onConflict`) → full pull → apply cloud (last-write-wins by `updated_at`) → invalidate providers. Debounced writes `nudge()`; `pushNow` on pause, `syncNow` on resume, 30s safety timer.
- **Pull re-derives metadata:** on pulling a `rebuild_set` unknown locally, the device fetches `expand_set_parts(set_item_id)` from the **catalog** client to rebuild the snapshot, then overlays the synced `have_qty`s. This is what keeps the cloud payload catalog-independent.
- **First sign-in migration:** when a free user with local rebuilds signs into premium, mark all their local rows `dirty` so the initial push uploads existing work.

---

## Acceptance criteria

Status: engine + gating logic proven by deterministic tests (`test/phase5_sync_test.dart`)
and the live UI flow (`integration_test/phase5_flow_test.dart`); the items needing a real
authenticated session are pending external Auth/billing config (see STATUS.md).

- [x] Sign in on device A, add/count a set, sign in on device B → the set + counts appear (metadata re-derived from catalog). — **sync logic verified** (two in-memory devices + fake remote/catalog); live round-trip pending OAuth config.
- [x] Sign out → app still fully usable; local data intact; no network for user data. — sync gated on `signedIn && isPremium`; app boots + runs signed-out (screenshot).
- [x] Free user hitting the project cap sees the paywall, not a crash. — `kFreeRebuildCap` gate in "Start sorting" → `/paywall`; paywall renders live.
- [ ] RLS verified: user A cannot read user B's rows (test with two accounts). — **pending live two-account test**; owner policies applied, security advisor clean.
- [x] Editing the same set on two devices converges (last-write-wins, no dupes). — **verified deterministically** (different-part convergence + same-part last-syncer-wins, no dup rows).

---

## Dependencies & risks

- Depends on the MVP (1–4) and the user project from [01](01-foundation.md).
- **Risk:** two-project auth confusion — auth/session lives on `userClient` only; the catalog client is always anon. Never send the user JWT to the catalog project.
- **Risk:** IAP/entitlement is its own integration (RevenueCat + store setup); scope it as a sub-track. Don't block sync correctness on billing — build sync first, gate second.
- **Risk:** full-pull re-derivation cost when a user has many sets — acceptable at expected volumes; add a watermark later if needed (whatabrick flagged full-pull as a known v1 simplification).
