# Phase 6 — Party Mode (premium, realtime)

**Goal:** multiple people sort one physical pile toward a shared inventory, live. Product's
"Party Mode (Premium)" — families, friends, community rebuild events. Requires accounts +
premium (builds on [05](05-auth-and-cloud-sync.md)) and Supabase Realtime on the user project.

MVP: — (post-MVP; the second premium hook)

---

## Scope

**In:**
- Create a party from a rebuild (or a group of rebuilds from one pile).
- Join by **short code** or **QR** (`qr_flutter`).
- Realtime shared progress + activity feed across participants.
- Optional work-slicing assignments ("Alex: Technic parts", "Sam: blue parts").
- Contributions roll up into the shared have-counts.

**Out:** voice/chat, presence avatars beyond a seed, cross-pile merging, non-premium party.

---

## Tasks

### 6.1 Schema (user project migration) — reuse whatabrick's party design
Port the party tables from whatabrick `docs/mobile/03-data-model.md` (they're already
designed), adapted to BrickBack's no-catalog-FK rule (`part_item_id`/`color_id` as plain ints):
- `party_sessions` (id, host_user_id, name, `join_code` unique, status, created_at).
- `party_members` (party_id, user_id, role, display_name, avatar_seed, unique(party_id,user_id)).
- `party_assignments` (party_id, member_id, label, filter_kind `color|category|part_type|set|custom`, filter_value jsonb, target_qty).
- `party_contributions` (party_id, member_id, assignment_id, part_item_id, color_id, qty, created_at) — drives feed + progress; rolls up to `rebuild_set_parts`.

### 6.2 Party-scoped RLS (the interesting bit)
Rows visible to **any member of the party**, not just the owner:
```sql
create policy "party members can read" on party_contributions
for select using (exists (
  select 1 from party_members m
  where m.party_id = party_contributions.party_id and m.user_id = auth.uid()));
```
Joining by code needs a `security definer` RPC `join_party(code)` so a non-member can
resolve code → party and insert their own `party_members` row without broad read access.
Port both from whatabrick's party migrations.

### 6.3 Realtime
- Subscribe to `party_contributions` (and progress) via Supabase Realtime channels on the `userClient`. Update the shared checklist + activity feed live.
- Reconcile realtime deltas into the local Drift `have_qty` so the counting screen ([03](03-inventory-collection.md)) reflects everyone's contributions.

### 6.4 UI
- Party create/join screens, invite screen with QR + code (`qr_flutter`), member list, per-assignment progress bars, live activity feed. Reuse whatabrick `features/party/*` as the reference (7 files).

---

## Acceptance criteria

- [ ] Two accounts join one party by code/QR; both see progress update within ~1–2s of a tap.
- [ ] RLS: a non-member cannot read party rows; `join_party` lets them join by code only.
- [ ] Contributions roll into the shared have-counts and reconcile with each device's local Drift.
- [ ] Host can end/pause a party; members handled gracefully.

---

## Dependencies & risks

- Depends on [05](05-auth-and-cloud-sync.md) (auth, user project, premium, sync).
- **Risk:** realtime + local-first reconciliation (two sources of truth). Define authority: cloud is authoritative during an active party; local overlays optimistically then reconciles.
- **Risk:** Realtime quotas/scale on Supabase — fine for small parties; cap party size for MVP of this feature.
- **Complexity gate:** this is the most complex feature; only start once premium sync ([05](05-auth-and-cloud-sync.md)) is solid.
