begin;
select plan(5);

select has_table('public', 'cases', 'cases table exists');

select is(
  (select relrowsecurity from pg_class where oid = 'public.cases'::regclass),
  true,
  'row-level security is on for cases'
);

select is(
  public.payoff_cents(100000, 300, 6),
  118000::bigint,
  '$1,000.00 at 3% a month for 6 months pays off at $1,180.00'
);

select is(
  public.payoff_cents(100000, 300, 0),
  100000::bigint,
  'with no months outstanding the payoff is the advance'
);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'ana@example.test');

insert into public.profiles (id, role, full_name) values
  ('00000000-0000-0000-0000-00000000000a', 'sales', 'Ana Example');

insert into public.cases (client_name, status, assigned_sales_id, advance_cents, monthly_fee_bps) values
  ('Sample Client', 'intake', '00000000-0000-0000-0000-00000000000a', 100000, 300);

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

select results_eq(
  'select client_name from public.cases',
  $$values ('Sample Client')$$,
  'a sales user can view their case'
);

select * from finish();
rollback;
