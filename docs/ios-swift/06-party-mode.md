# S6 — Party mode (realtime collaborative counting)

> Premium: a host starts a party on one of their rebuilds; members join by short code (or QR)
> and log found parts, which roll up **server-side** into the shared have-count and stream to
> every device in realtime. The backend for this is **already built and verified live** — S6
> is a pure client port.

Flutter reference: [`../phases/06-party-mode.md`](../phases/06-party-mode.md) +
[STATUS Phase 6](../phases/STATUS.md#what-changed-in-phase-6). Sources:
[`apps/mobile/lib/features/party/*`](../../apps/mobile/lib/features/party). Cloud:
`supabase/migrations/0003_party_mode.sql` (**applied — do not re-create**).

### Goal
Reproduce the realtime party hub, the client-derived picker, and local reconciliation, against
the existing `party_*` tables + RPCs.

### The already-solved backend (reuse verbatim)
The user project has `party_sessions` (+ denormalized `set_item_id`), `party_members`,
`party_assignments` (schema-only), `party_contributions` (+ denormalized `part_name`/`color_name`,
`qty` bounded), the `is_party_member` helper, member-scoped RLS, the RPCs `create_party` /
`join_party` / `party_progress` / `party_have_counts`, the additive **rollup trigger**, and
realtime publication on `party_members` + `party_contributions` + `party_assignments`. All
**verified live** with two impersonated auth users (create→join→contribute→rollup→progress,
non-member blocked, host-only pause). **The Swift client calls the identical RPCs** — no SQL
changes.

### The BrickBack two-project adaptation (already designed — keep it)
Because the user project has **no catalog**, the "still-needed" picker and the activity feed
are built client-side:
- No server `party_parts`. `party_have_counts(party_id)` returns rolled-up `(part_item_id,
  color_id, have)`; the device joins it against the **catalog-derived** needed list
  (`catalogClient.expandSetParts`) to build the picker.
- `party_sessions.set_item_id` is denormalized so members (who can't read the host's
  owner-scoped `rebuild_sets`) can derive the picker + reconcile into their own local GRDB.
- `party_contributions` denormalizes part/colour names so the feed renders with no catalog join.
- `part_item_id`/`color_id` are plain ints, no catalog FK.

### Scope
**In:** `PartyRemote` protocol + `SupabasePartyRemote` (Realtime v2 seam), `PartyRepository`
(orchestrates remote + catalog + rebuild repo, incl. the client-side picker derivation and
local-Drift reconciliation), models, and the four screens (hub, join, invite/QR, add-parts
picker), gated behind premium + a signed-in session.
**Out:** `party_assignments` UI (schema-only, as in Flutter); a deep-link handler for
`brickback://party/<code>` (join is by code entry, matching the Flutter deferral).

### Deliverables

**`BrickBackKit/Party`**
- `Models`: `Party` (+ `setItemId`), `PartyMember`, `PartyContribution` (denorm names),
  `PartyProgress`, `PartyPart` (built on-device from `ExpandedPart` ⟕ shared `have`, with a
  `remaining` getter). Port [`party_models.dart`](../../apps/mobile/lib/features/party/party_models.dart).
- `protocol PartyRemote` + `SupabasePartyRemote` — `create_party` / `join_party` /
  `party_progress` / `party_have_counts` via `rpc(...)`, the contribution insert, and
  `subscribe(partyId:)` returning a plain disposer closure that hides the Realtime types from
  callers (mirrors the Flutter seam so party logic is unit-testable with a fake). Use
  **Realtime v2** `RealtimeChannelV2` async streams for member/contribution changes.
- `PartyRepository` — the two BrickBack-only bits: `parts(partyId:setItemId:)` (client-side
  picker derivation) and reconciliation (`ensureLocalRebuild` snapshots the set for a joining
  member; `applyHaveCounts` overlays shared counts into local GRDB via `setPartHave`, diffing
  against a `previous` map). Port [`party_repository.dart`](../../apps/mobile/lib/features/party/party_repository.dart).

**App target (`Features/Party`)**
- `PartyView` (realtime hub — progress ring, roster/avatars, activity feed, add/invite/end;
  subscribes on enter, reconciles into local GRDB on leave), `PartyJoinView` (code entry),
  `PartyInviteView` (QR of `brickback://party/<code>` via **CoreImage `CIQRCodeGenerator`** +
  code + share), `PartyAddPartsView` (the client-derived picker). `PartyAvatar` (seeded
  avatars + overflow stack).
- Entry points: a **Start party** header button on `RebuildView` (premium + account gate →
  paywall / sign-in; flush + `pushNow()` so `create_party` finds the synced rebuild, then open
  the party) and a **Join a party** entry on Profile.

### Swift specifics
- **Realtime v2:** `let channel = userClient.realtimeV2.channel("party:\(id)")`; consume
  `channel.postgresChange(...)` as an `AsyncStream` in a `Task` owned by the view model;
  cancel on disappear. Cleaner than the Flutter callback + manual disposer, but keep the
  disposer-closure shape in `PartyRemote` so tests inject a fake.
- **QR without a dependency:** render `CIQRCodeGenerator` output to a `UIImage` — drops the
  `qr_flutter` dep entirely.
- **Rollup authority nuance (keep, don't "fix"):** contributions are authoritative for
  contributed parts (the rollup recomputes `have_qty = Σ contributions`); a host's pre-party
  manual count for a contributed part is replaced by the sum. This matches the sanctioned
  whatabrick v1 and the Flutter app — preserving a baseline is an explicit later refinement.

### Acceptance (parity vs. Flutter Phase 6)
Port `test/phase6_party_test.dart` to in-memory GRDB + a fake party server that faithfully
simulates the rollup trigger, `party_progress`, and `party_have_counts` (host + member
device): create→join (rejected for an un-synced rebuild / wrong code / ended party;
`ensureLocalRebuild` snapshots on join and reuses an existing rebuild); contribution rolls into
the shared have-count + progress; the picker's `remaining` math drops satisfied parts; multiple
members roll up additively and converge; the feed carries denorm names; `applyHaveCounts` is
idempotent with a `previous` diff. The **live RLS/RPC/rollup guarantees are already proven** on
the real DB (STATUS Phase 6); re-run the two-account realtime acceptance once OAuth is live
(S8). Sim: Profile shows the Party card; a guest tapping Join bounces to the paywall; the join
+ invite (QR) screens render.

### Risks
- **Realtime auth:** the channel needs the user JWT; ensure the `userClient` session is set
  before subscribing.
- **Re-fetch on tick:** the Flutter hub re-fetches on each realtime event (fine for small
  parties); keep that simplicity, or debounce if a party is large.
- **Live two-account test** waits on OAuth config (S8) — same external gap as S5.
