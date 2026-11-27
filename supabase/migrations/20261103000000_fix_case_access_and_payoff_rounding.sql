-- Fixes the two defects proven by supabase/tests/20_* and 30_*.
-- The earlier migration is left untouched: it may already have run somewhere,
-- so the correction ships as a new migration on top of it.

-- 1. Access: who can read which case ------------------------------------------

-- Looks up the caller's role. Lives in a schema the API does not expose, and
-- runs as its owner so it can read profiles regardless of the caller's rights.
create schema if not exists private;

create function private.current_app_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role from public.profiles p where p.id = (select auth.uid());
$$;

revoke all on function private.current_app_role() from public;
grant usage on schema private to authenticated;
grant execute on function private.current_app_role() to authenticated;

-- The old rule only asked "is this person logged in?".
drop policy "Authenticated users can view cases" on public.cases;

-- One rule per role. A user with no profile matches none of them and sees nothing.
create policy "Admins read every case"
  on public.cases
  for select
  to authenticated
  using ((select private.current_app_role()) = 'admin');

create policy "Sales read the cases assigned to them"
  on public.cases
  for select
  to authenticated
  using (
    (select private.current_app_role()) = 'sales'
    and assigned_sales_id = (select auth.uid())
  );

create policy "Underwriting reads cases awaiting a decision"
  on public.cases
  for select
  to authenticated
  using (
    (select private.current_app_role()) = 'underwriting'
    and status in ('intake', 'underwriting')
  );

create policy "Servicing reads funded and paid-off cases"
  on public.cases
  for select
  to authenticated
  using (
    (select private.current_app_role()) = 'servicing'
    and status in ('funded', 'paid_off')
  );

-- 2. Money: payoff in whole cents ---------------------------------------------

-- Rounding rule: the fee is rounded once, at the end, to the nearest cent,
-- and exactly half a cent rounds up.
--
-- Everything is integer arithmetic. The fee in ten-thousandths of a cent is
-- advance_cents * monthly_fee_bps * months; adding 5000 before dividing by
-- 10000 rounds half up.
create or replace function public.payoff_cents(
  advance_cents bigint,
  monthly_fee_bps integer,
  months integer
)
returns bigint
language sql
immutable
as $$
  select advance_cents
    + (advance_cents * monthly_fee_bps * months + 5000) / 10000;
$$;
