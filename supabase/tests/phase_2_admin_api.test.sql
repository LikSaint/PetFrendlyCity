begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(7);

select extensions.has_function(
  'public',
  'admin_current_role',
  array[]::text[],
  'admin role resolver exists'
);

select extensions.has_function(
  'public',
  'admin_crm_queue',
  array[]::text[],
  'role-checked CRM queue RPC exists'
);

select extensions.has_function(
  'public',
  'admin_claim_crm_task',
  array['uuid'],
  'atomic task claim RPC exists'
);

select extensions.is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public'
      and tablename = 'admin_users'
      and policyname = 'admin_users_read_self'
  ),
  1,
  'admin users can only read their own active role'
);

select extensions.is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public'
      and tablename = 'crm_tasks'
      and policyname = 'crm_tasks_admin_read'
  ),
  1,
  'CRM task read policy exists'
);

select extensions.throws_ok(
  'select * from public.admin_crm_queue()',
  '42501',
  'admin role required',
  'unauthenticated queue access is rejected'
);

select extensions.throws_ok(
  $$select public.admin_claim_crm_task('00000000-0000-0000-0000-000000000001')$$,
  '42501',
  'admin role required',
  'unauthenticated task claim is rejected'
);

select * from extensions.finish();
rollback;
