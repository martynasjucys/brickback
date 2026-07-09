-- BrickBack user-data project — initial schema.
-- Applied to project nthbhcqufiuyrnioxglm. Kept in-repo for parity/history.
--
-- Local-first: Drift on-device is the source of truth; these cloud tables are the
-- PREMIUM sync mirror. NO foreign keys to the LEGO catalog (it lives in a separate
-- Supabase project) — set/part/color ids are plain ints validated client-side.
-- Every row carries sync columns (id uuid == local id, updated_at, deleted tombstone).
-- RLS: owner-scoped everywhere (auth.uid() = user_id).

-- ── rebuild_sets: one per set being rebuilt ──────────────────────────────────
create table public.rebuild_sets (
  id           uuid primary key,                 -- client-generated (== local Drift id)
  user_id      uuid not null references auth.users (id) on delete cascade,
  set_item_id  bigint not null,                  -- catalog items.id (plain int, not an FK)
  total_parts  integer not null default 0,       -- expanded part count snapshot (denominator)
  verified_at  timestamptz,
  updated_at   timestamptz not null default now(),
  deleted      boolean not null default false
);
create index rebuild_sets_user_idx on public.rebuild_sets (user_id, updated_at desc);

-- ── rebuild_set_parts: per part+color "have" count (metadata re-derived from catalog) ──
create table public.rebuild_set_parts (
  rebuild_set_id uuid not null references public.rebuild_sets (id) on delete cascade,
  part_item_id   bigint not null,                -- catalog parts.item_id (plain int)
  color_id       integer not null,               -- catalog colors.id (plain int)
  have_qty       integer not null default 0 check (have_qty >= 0),
  updated_at     timestamptz not null default now(),
  deleted        boolean not null default false,
  primary key (rebuild_set_id, part_item_id, color_id)
);

-- ── rebuild_minifigs: per minifig "have" count (verified separately) ─────────
create table public.rebuild_minifigs (
  rebuild_set_id  uuid not null references public.rebuild_sets (id) on delete cascade,
  minifig_item_id bigint not null,               -- catalog minifigs.item_id (plain int)
  have_qty        integer not null default 0 check (have_qty >= 0),
  updated_at      timestamptz not null default now(),
  deleted         boolean not null default false,
  primary key (rebuild_set_id, minifig_item_id)
);

-- ── verifications: the finished Inventory Verification report ─────────────────
create table public.verifications (
  id              uuid primary key,
  user_id         uuid not null references auth.users (id) on delete cascade,
  rebuild_set_id  uuid not null references public.rebuild_sets (id) on delete cascade,
  set_item_id     bigint not null,
  completion_pct  real not null default 0,        -- parts completion
  parts_needed    integer,
  parts_found     integer,
  minifigs_needed integer,
  minifigs_found  integer,
  flags           jsonb not null default '{}'::jsonb,  -- { box, instructions, stickers, all_parts, minifigs }
  notes           text,
  verified_at     timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted         boolean not null default false
);
create index verifications_user_idx on public.verifications (user_id, updated_at desc);

-- ── RLS: owner-scoped ────────────────────────────────────────────────────────
alter table public.rebuild_sets      enable row level security;
alter table public.rebuild_set_parts enable row level security;
alter table public.rebuild_minifigs  enable row level security;
alter table public.verifications     enable row level security;

create policy "owner all" on public.rebuild_sets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "owner all" on public.verifications
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "owner all via parent" on public.rebuild_set_parts
  for all using (exists (
    select 1 from public.rebuild_sets r
    where r.id = rebuild_set_parts.rebuild_set_id and r.user_id = auth.uid()))
  with check (exists (
    select 1 from public.rebuild_sets r
    where r.id = rebuild_set_parts.rebuild_set_id and r.user_id = auth.uid()));

create policy "owner all via parent" on public.rebuild_minifigs
  for all using (exists (
    select 1 from public.rebuild_sets r
    where r.id = rebuild_minifigs.rebuild_set_id and r.user_id = auth.uid()))
  with check (exists (
    select 1 from public.rebuild_sets r
    where r.id = rebuild_minifigs.rebuild_set_id and r.user_id = auth.uid()));
