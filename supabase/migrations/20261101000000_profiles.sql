-- Baseline: every staff member has a profile with exactly one role.
-- The four roles are an example. Swap them for the real ones.

create type public.app_role as enum ('admin', 'sales', 'underwriting', 'servicing');

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.app_role not null,
  full_name text not null
);

alter table public.profiles enable row level security;

revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;

create policy "Users read their own profile"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);
