begin;
select plan(3);

select has_table('public', 'profiles', 'profiles table exists');

select is(
  (select relrowsecurity from pg_class where oid = 'public.profiles'::regclass),
  true,
  'row-level security is on for profiles'
);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'ana@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'ben@example.test');

insert into public.profiles (id, role, full_name) values
  ('00000000-0000-0000-0000-00000000000a', 'sales', 'Ana Example'),
  ('00000000-0000-0000-0000-00000000000b', 'sales', 'Ben Example');

set local role authenticated;
set local request.jwt.claim.sub = '00000000-0000-0000-0000-00000000000a';

select results_eq(
  'select full_name from public.profiles',
  $$values ('Ana Example')$$,
  'a user reads their own profile and nobody else''s'
);

select * from finish();
rollback;
