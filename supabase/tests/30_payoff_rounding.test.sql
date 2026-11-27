-- Does the payoff come out to the right cent?
-- Rule under test: the fee is rounded once, at the end, to the nearest cent,
-- and exactly half a cent rounds up.
begin;
select plan(5);

select is(
  public.payoff_cents(250050, 300, 3),
  272555::bigint,
  '$2,500.50 at 3% for 3 months: fee is $225.045, so payoff is $2,725.55'
);

select is(
  public.payoff_cents(125050, 250, 2),
  131303::bigint,
  '$1,250.50 at 2.5% for 2 months: fee is $62.525, so payoff is $1,313.03'
);

select is(
  public.payoff_cents(250050, 300, 5),
  287558::bigint,
  '$2,500.50 at 3% for 5 months: fee is $375.075, so payoff is $2,875.58'
);

select is(
  public.payoff_cents(100001, 300, 1),
  103001::bigint,
  '$1,000.01 at 3% for 1 month: fee is $30.0003, so payoff is $1,030.01'
);

select is(
  public.payoff_cents(100000050, 375, 36),
  235000118::bigint,
  '$1,000,000.50 at 3.75% for 36 months: fee is $1,350,000.675, so payoff is $2,350,001.18'
);

select * from finish();
rollback;
