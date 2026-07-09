-- BrickBack user-data project — Party Mode (Phase 6).
-- Applied to project nthbhcqufiuyrnioxglm.
--
-- Realtime collaborative counting: a premium host starts a party on one of their
-- rebuild_sets; members join by short code and log found parts, which roll up
-- (server-side, additive) into the host's shared rebuild_set_parts.have_qty.
-- Rows are visible to ANY party member (not just the owner) — the interesting
-- departure from the owner-scoped rebuild_* tables.
--
-- Ported from whatabrick's party migrations, adapted to BrickBack's TWO-project
-- split: the user project has NO catalog, so (a) NO foreign keys to catalog
-- items/colors — part_item_id/color_id are plain ints validated client-side;
-- (b) there is NO server-side `party_parts` (which joined expand_set_parts in
-- whatabrick's single project) — the "still-needed" picker is derived on-device
-- from the catalog client, and `party_have_counts` returns just the rolled-up
-- have; (c) party_sessions carries set_item_id (members can't read the host's
-- owner-scoped rebuild_sets), and party_contributions denormalizes
-- part_name/color_name so the activity feed needs no catalog join.

-- pgcrypto (gen_random_bytes) lives in the `extensions` schema on Supabase; every
-- function that uses it must include `extensions` in its search_path or it throws
-- 42883 at runtime.
create extension if not exists pgcrypto with schema extensions;

-- ── party_sessions ───────────────────────────────────────────────────────────
create table public.party_sessions (
  id             uuid primary key default gen_random_uuid(),
  host_user_id   uuid not null references auth.users (id) on delete cascade,
  rebuild_set_id uuid references public.rebuild_sets (id) on delete set null,
  set_item_id    bigint not null,               -- denormalized so members can derive the picker
  name           text not null,
  join_code      text not null unique,
  status         text not null default 'active' check (status in ('active', 'paused', 'ended')),
  created_at     timestamptz not null default now()
);

-- ── party_members ────────────────────────────────────────────────────────────
create table public.party_members (
  id           uuid primary key default gen_random_uuid(),
  party_id     uuid not null references public.party_sessions (id) on delete cascade,
  user_id      uuid not null references auth.users (id) on delete cascade,
  role         text not null default 'member' check (role in ('host', 'member')),
  display_name text,
  avatar_seed  text,
  joined_at    timestamptz not null default now(),
  unique (party_id, user_id)
);
create index party_members_party_idx on public.party_members (party_id);
create index party_members_user_idx on public.party_members (user_id);

-- ── party_assignments (schema scaffold; no UI in the Phase 6 MVP) ─────────────
create table public.party_assignments (
  id           uuid primary key default gen_random_uuid(),
  party_id     uuid not null references public.party_sessions (id) on delete cascade,
  member_id    uuid references public.party_members (id) on delete set null,
  label        text not null,
  filter_kind  text not null check (filter_kind in ('color', 'category', 'part_type', 'set', 'custom')),
  filter_value jsonb not null default '{}'::jsonb,
  target_qty   int,
  created_at   timestamptz not null default now()
);
create index party_assignments_party_idx on public.party_assignments (party_id);

-- ── party_contributions ──────────────────────────────────────────────────────
-- part_item_id/color_id are plain ints (no catalog FK). part_name/color_name are
-- denormalized for the activity feed (the contributor's device knows them).
create table public.party_contributions (
  id            uuid primary key default gen_random_uuid(),
  party_id      uuid not null references public.party_sessions (id) on delete cascade,
  member_id     uuid references public.party_members (id) on delete set null,
  assignment_id uuid references public.party_assignments (id) on delete set null,
  part_item_id  bigint not null,
  color_id      integer not null,
  part_name     text,
  color_name    text,
  qty           integer not null check (qty > 0 and qty <= 10000),
  created_at    timestamptz not null default now()
);
create index party_contributions_party_idx on public.party_contributions (party_id, created_at desc);

-- Membership check as SECURITY DEFINER so the party RLS policies don't recurse on
-- party_members. Called from RLS `using` clauses (as the querying role), so it
-- must stay executable by `authenticated`.
create or replace function public.is_party_member(p_party_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.party_members
    where party_id = p_party_id and user_id = auth.uid()
  );
$$;

-- Display name from the user's OAuth metadata, else the email local-part.
create or replace function public._party_display_name()
returns text
language sql
security definer
set search_path = public, auth
as $$
  select coalesce(
    nullif(u.raw_user_meta_data->>'name', ''),
    nullif(u.raw_user_meta_data->>'full_name', ''),
    split_part(u.email, '@', 1),
    'Builder'
  )
  from auth.users u
  where u.id = auth.uid();
$$;

-- ── RLS ──────────────────────────────────────────────────────────────────────
alter table public.party_sessions      enable row level security;
alter table public.party_members       enable row level security;
alter table public.party_assignments   enable row level security;
alter table public.party_contributions enable row level security;

-- party_sessions: members read; host writes (create/pause/end/delete).
-- Non-members resolve a code only via join_party().
create policy "member read" on public.party_sessions
  for select using (public.is_party_member(id));
create policy "host insert" on public.party_sessions
  for insert with check (host_user_id = auth.uid());
create policy "host update" on public.party_sessions
  for update using (host_user_id = auth.uid());
create policy "host delete" on public.party_sessions
  for delete using (host_user_id = auth.uid());

-- party_members: members read the roster; a user may only remove their own row.
-- There is deliberately NO self-insert policy: joins go through join_party()
-- and the host row through create_party() (both SECURITY DEFINER), so a user
-- can't add themselves to an arbitrary party_id and bypass the join-code gate.
create policy "member read" on public.party_members
  for select using (public.is_party_member(party_id));
create policy "self delete" on public.party_members
  for delete using (user_id = auth.uid());

-- party_assignments: members read; host writes.
create policy "member read" on public.party_assignments
  for select using (public.is_party_member(party_id));
create policy "host write" on public.party_assignments
  for all
  using (exists (select 1 from public.party_sessions s
                 where s.id = party_id and s.host_user_id = auth.uid()))
  with check (exists (select 1 from public.party_sessions s
                      where s.id = party_id and s.host_user_id = auth.uid()));

-- party_contributions: members read; members insert (into their own party).
create policy "member read" on public.party_contributions
  for select using (public.is_party_member(party_id));
create policy "member insert" on public.party_contributions
  for insert with check (public.is_party_member(party_id));

-- ── create_party: start a party on one of the caller's rebuild sets ───────────
-- The caller must own the rebuild (which they must have synced to the cloud
-- first — party is premium, so sync is on). Host becomes the first member.
create or replace function public.create_party(p_rebuild_set_id uuid, p_name text)
returns public.party_sessions
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_code text;
  v_set_item_id bigint;
  v_party public.party_sessions;
begin
  select set_item_id into v_set_item_id
  from public.rebuild_sets
  where id = p_rebuild_set_id and user_id = auth.uid();
  if v_set_item_id is null then
    raise exception 'not your rebuild';
  end if;

  loop  -- retry on the astronomically-unlikely unique collision
    v_code := upper(encode(gen_random_bytes(4), 'hex'));  -- 8 hex chars (~32 bits)
    exit when not exists (select 1 from public.party_sessions where join_code = v_code);
  end loop;

  insert into public.party_sessions (host_user_id, rebuild_set_id, set_item_id, name, join_code)
  values (auth.uid(), p_rebuild_set_id, v_set_item_id, p_name, v_code)
  returning * into v_party;

  insert into public.party_members (party_id, user_id, role, display_name)
  values (v_party.id, auth.uid(), 'host', public._party_display_name());

  return v_party;
end;
$$;

-- ── join_party: resolve a code and add the caller as a member ─────────────────
-- SECURITY DEFINER so a non-member can join by code alone (no broad read access
-- to party_sessions). Idempotent (on conflict do nothing) so re-joining is safe.
create or replace function public.join_party(p_code text)
returns public.party_sessions
language plpgsql
security definer
set search_path = public
as $$
declare v_party public.party_sessions;
begin
  select * into v_party from public.party_sessions
  where join_code = upper(trim(p_code)) and status = 'active';
  if v_party.id is null then
    raise exception 'party not found';
  end if;

  insert into public.party_members (party_id, user_id, role, display_name)
  values (v_party.id, auth.uid(), 'member', public._party_display_name())
  on conflict (party_id, user_id) do nothing;

  return v_party;
end;
$$;

-- ── party_progress: shared {total, have} for any member ───────────────────────
-- SECURITY DEFINER: members can't read the host's owner-scoped rebuild_set_parts
-- directly. have = capped sum of the rolled-up have_qty.
create or replace function public.party_progress(p_party_id uuid)
returns table (total integer, have integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_rebuild uuid;
  v_total int;
  v_have int;
begin
  if not public.is_party_member(p_party_id) then
    raise exception 'not a member';
  end if;
  select rebuild_set_id into v_rebuild from public.party_sessions where id = p_party_id;
  select total_parts into v_total from public.rebuild_sets where id = v_rebuild;
  select coalesce(sum(have_qty), 0) into v_have
  from public.rebuild_set_parts where rebuild_set_id = v_rebuild and deleted = false;
  return query select coalesce(v_total, 0), least(coalesce(v_have, 0), coalesce(v_total, 0));
end;
$$;

-- ── party_have_counts: rolled-up have per (part, colour) for any member ───────
-- BrickBack replacement for whatabrick's catalog-joining party_parts: returns
-- ONLY the shared have counts; the device joins them against the catalog-derived
-- "needed" list on-device to build the picker.
create or replace function public.party_have_counts(p_party_id uuid)
returns table (part_item_id bigint, color_id integer, have integer)
language plpgsql
security definer
set search_path = public
as $$
declare v_rebuild uuid;
begin
  if not public.is_party_member(p_party_id) then
    raise exception 'not a member';
  end if;
  select rebuild_set_id into v_rebuild from public.party_sessions where id = p_party_id;
  if v_rebuild is null then return; end if;
  return query
    select rsp.part_item_id, rsp.color_id, rsp.have_qty
    from public.rebuild_set_parts rsp
    where rsp.rebuild_set_id = v_rebuild and rsp.deleted = false;
end;
$$;

-- ── rollup trigger: a contribution recomputes the shared have_qty ─────────────
-- have_qty := sum of all party contributions for that (party, part, colour),
-- upserted into the host's rebuild_set_parts. Additive + conflict-free (a full
-- recompute, so it's idempotent under retries). SECURITY DEFINER so it can write
-- the host's owner-scoped row on behalf of a contributing member.
create or replace function public.party_rollup_contribution()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare v_rebuild_set_id uuid;
begin
  select rebuild_set_id into v_rebuild_set_id
  from public.party_sessions where id = new.party_id;
  if v_rebuild_set_id is null then return new; end if;

  insert into public.rebuild_set_parts (rebuild_set_id, part_item_id, color_id, have_qty, updated_at, deleted)
  values (
    v_rebuild_set_id, new.part_item_id, new.color_id,
    (select coalesce(sum(qty), 0) from public.party_contributions
     where party_id = new.party_id and part_item_id = new.part_item_id and color_id = new.color_id),
    now(), false
  )
  on conflict (rebuild_set_id, part_item_id, color_id)
  do update set have_qty = excluded.have_qty, updated_at = now(), deleted = false;
  return new;
end;
$$;

create trigger party_contribution_rollup
  after insert on public.party_contributions
  for each row execute function public.party_rollup_contribution();

-- ── Function grants ──────────────────────────────────────────────────────────
-- Supabase grants EXECUTE on new public functions DIRECTLY to anon/authenticated
-- (via ALTER DEFAULT PRIVILEGES), so `revoke ... from public` is a no-op here —
-- the roles must be revoked explicitly. anon must never call any of these.
--
-- Two functions run ONLY in their definer/trigger context, never as a REST RPC —
-- revoke from both anon and authenticated:
revoke execute on function public._party_display_name()       from anon, authenticated;
revoke execute on function public.party_rollup_contribution() from anon, authenticated;
--
-- The remaining five are authenticated-callable BY DESIGN (this is what party mode
-- is): is_party_member is invoked by the RLS policies as the querying role (a
-- SECURITY DEFINER helper avoids infinite recursion on the party_members policy),
-- and the four RPCs are the party API — each guards internally on auth.uid() /
-- is_party_member(). They stay flagged by the `*_security_definer_function_*`
-- advisor lints (WARN); that is the intended, reviewed surface. Only anon is
-- revoked:
revoke execute on function public.is_party_member(uuid)     from anon;
revoke execute on function public.create_party(uuid, text)  from anon;
revoke execute on function public.join_party(text)          from anon;
revoke execute on function public.party_progress(uuid)      from anon;
revoke execute on function public.party_have_counts(uuid)   from anon;

-- ── Realtime: stream roster + contributions to party members ──────────────────
alter publication supabase_realtime add table public.party_members;
alter publication supabase_realtime add table public.party_contributions;
alter publication supabase_realtime add table public.party_assignments;
