-- Cases: one row per funded (or potentially funded) client matter.
-- Money is stored as whole cents; the monthly fee as basis points (300 = 3.00%).

create table public.cases (
  id uuid primary key default gen_random_uuid(),
  client_name text not null,
  status text not null default 'intake'
    check (status in ('intake', 'underwriting', 'funded', 'paid_off')),
  assigned_sales_id uuid not null references public.profiles (id),
  advance_cents bigint not null check (advance_cents > 0),
  monthly_fee_bps integer not null check (monthly_fee_bps >= 0),
  funded_on date,
  created_at timestamptz not null default now()
);

create index cases_assigned_sales_id_idx on public.cases (assigned_sales_id);

alter table public.cases enable row level security;

revoke all on table public.cases from anon, authenticated;
grant select on table public.cases to authenticated;

-- Only logged-in staff can view cases.
create policy "Authenticated users can view cases"
  on public.cases
  for select
  to authenticated
  using ((select auth.uid()) is not null);

-- Payoff = advance + (advance x monthly fee x months outstanding).
create function public.payoff_cents(
  advance_cents bigint,
  monthly_fee_bps integer,
  months integer
)
returns bigint
language sql
immutable
as $$
  -- Convert to dollars, apply the monthly fee, convert back to cents.
  select round(
    (advance_cents / 100.0)::float
    * (1 + (monthly_fee_bps / 10000.0)::float * months)
    * 100
  )::bigint;
$$;
