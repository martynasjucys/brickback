-- BrickBack user-data project — profiles / premium entitlement (Phase 5).
-- Applied to project nthbhcqufiuyrnioxglm.
--
-- Source of truth for `isPremiumProvider`. `is_premium` is NOT user-writable — it
-- is flipped by a billing webhook / service role (e.g. RevenueCat) later. The app
-- only READs its own row (owner RLS). A trigger auto-creates a profile row on
-- signup so `select is_premium` always finds a row (defaults to false = free).

create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  is_premium  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Owner may read their own profile. No insert/update/delete policy: entitlement is
-- set server-side (service role bypasses RLS), never by the client.
create policy "own profile read" on public.profiles
  for select using (auth.uid() = id);

-- Auto-provision a profile row when a new auth user is created.
create or replace function public.handle_new_user()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- The function only ever runs from the trigger (as its definer). Revoke the
-- default PUBLIC execute so it is not callable as a REST RPC by anon/authenticated.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
