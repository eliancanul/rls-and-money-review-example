-- Who can read which case? One test per role, plus the two "nobody" cases.
begin;
select plan(8);

-- Six made-up people: one per role, a second salesperson, and someone with a
-- login but no profile.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'admin@example.test'),
  ('00000000-0000-0000-0000-0000000000b1', 'sales.ana@example.test'),
  ('00000000-0000-0000-0000-0000000000b2', 'sales.ben@example.test'),
  ('00000000-0000-0000-0000-0000000000c1', 'underwriting@example.test'),
  ('00000000-0000-0000-0000-0000000000d1', 'servicing@example.test'),
  ('00000000-0000-0000-0000-0000000000e1', 'no.profile@example.test');

insert into public.profiles (id, role, full_name) values
  ('00000000-0000-0000-0000-0000000000a1', 'admin', 'Admin Example'),
  ('00000000-0000-0000-0000-0000000000b1', 'sales', 'Ana Example'),
  ('00000000-0000-0000-0000-0000000000b2', 'sales', 'Ben Example'),
  ('00000000-0000-0000-0000-0000000000c1', 'underwriting', 'Uma Example'),
  ('00000000-0000-0000-0000-0000000000d1', 'servicing', 'Sam Example');

-- Four made-up cases: two belong to Ana, two to Ben, one in each status.
insert into public.cases (client_name, status, assigned_sales_id, advance_cents, monthly_fee_bps) values
  ('Ana - intake',       'intake',       '00000000-0000-0000-0000-0000000000b1', 250000, 300),
  ('Ana - funded',       'funded',       '00000000-0000-0000-0000-0000000000b1', 500000, 300),
  ('Ben - underwriting', 'underwriting', '00000000-0000-0000-0000-0000000000b2', 125000, 350),
  ('Ben - paid off',     'paid_off',     '00000000-0000-0000-0000-0000000000b2', 300000, 250);

-- Not logged in.
set local role anon;

select throws_ok(
  'select client_name from public.cases',
  '42501',
  null,
  'a visitor who is not logged in is refused outright'
);

-- Logged in, one person at a time.
set local role authenticated;

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000a1';
select results_eq(
  'select client_name from public.cases order by client_name',
  $$values ('Ana - funded'), ('Ana - intake'), ('Ben - paid off'), ('Ben - underwriting')$$,
  'admin reads every case'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b1';
select results_eq(
  'select client_name from public.cases order by client_name',
  $$values ('Ana - funded'), ('Ana - intake')$$,
  'sales (Ana) reads only the cases assigned to her'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b2';
select results_eq(
  'select client_name from public.cases order by client_name',
  $$values ('Ben - paid off'), ('Ben - underwriting')$$,
  'sales (Ben) reads only the cases assigned to him'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000c1';
select results_eq(
  'select client_name from public.cases order by client_name',
  $$values ('Ana - intake'), ('Ben - underwriting')$$,
  'underwriting reads only cases still awaiting a decision'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000d1';
select results_eq(
  'select client_name from public.cases order by client_name',
  $$values ('Ana - funded'), ('Ben - paid off')$$,
  'servicing reads only funded and paid-off cases'
);

set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000e1';
select is_empty(
  'select client_name from public.cases',
  'a logged-in user with no profile reads nothing'
);

-- Reading is all anyone may do through the API in this example.
set local request.jwt.claim.sub = '00000000-0000-0000-0000-0000000000b1';
select throws_ok(
  $$update public.cases set assigned_sales_id = '00000000-0000-0000-0000-0000000000b1'$$,
  '42501',
  null,
  'sales cannot reassign cases to herself'
);

select * from finish();
rollback;
