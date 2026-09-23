create or replace function public.admin_current_role()
returns public.admin_role
language sql
stable
security definer
set search_path = ''
as $$
  select admin.role
  from public.admin_users admin
  where admin.user_id = auth.uid() and admin.active = true;
$$;

revoke all on function public.admin_current_role() from public, anon;
grant execute on function public.admin_current_role() to authenticated;

create policy admin_users_read_self on public.admin_users
  for select to authenticated
  using (user_id = auth.uid() and active = true);

grant select on public.admin_users to authenticated;

create policy crm_tasks_admin_read on public.crm_tasks
  for select to authenticated
  using (
    public.admin_current_role() = 'ADMIN'
    or (
      public.admin_current_role() = 'CALLER'
      and (assigned_to is null or assigned_to = auth.uid())
    )
  );

grant select on public.crm_tasks to authenticated;

create or replace function public.admin_crm_queue()
returns table (
  task_id uuid,
  place_id uuid,
  google_place_id text,
  task_type public.crm_task_type,
  task_status public.crm_task_status,
  priority_score numeric,
  assigned_to uuid,
  unique_requesters bigint,
  request_count bigint,
  place_open_count bigint,
  navigation_count bigint,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_role public.admin_role := public.admin_current_role();
begin
  if current_role is null or current_role not in ('ADMIN', 'CALLER') then
    raise exception 'admin role required' using errcode = '42501';
  end if;

  return query
  select
    task.id,
    task.place_id,
    ref.external_id,
    task.task_type,
    task.status,
    task.priority_score,
    task.assigned_to,
    coalesce(demand.unique_requesters, 0),
    coalesce(demand.request_count, 0),
    coalesce(demand.place_open_count, 0),
    coalesce(demand.navigation_count, 0),
    task.created_at
  from public.crm_tasks task
  left join public.crm_place_demand demand on demand.place_id = task.place_id
  left join public.external_place_refs ref
    on ref.place_id = task.place_id and ref.provider = 'GOOGLE'
  where task.status in ('OPEN', 'IN_PROGRESS', 'WAITING_CALLBACK')
    and (
      current_role = 'ADMIN'
      or task.assigned_to is null
      or task.assigned_to = auth.uid()
    )
  order by task.priority_score desc, task.created_at asc;
end;
$$;

create or replace function public.admin_claim_crm_task(claimed_task_id uuid)
returns boolean
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
  current_role public.admin_role := public.admin_current_role();
  affected_rows integer;
begin
  if current_role is null or current_role not in ('ADMIN', 'CALLER') then
    raise exception 'admin role required' using errcode = '42501';
  end if;

  update public.crm_tasks
  set
    assigned_to = auth.uid(),
    status = case when status = 'OPEN' then 'IN_PROGRESS' else status end
  where id = claimed_task_id
    and status in ('OPEN', 'IN_PROGRESS', 'WAITING_CALLBACK')
    and (assigned_to is null or assigned_to = auth.uid());

  get diagnostics affected_rows = row_count;
  return affected_rows = 1;
end;
$$;

revoke all on function public.admin_crm_queue() from public, anon;
revoke all on function public.admin_claim_crm_task(uuid) from public, anon;
grant execute on function public.admin_crm_queue() to authenticated;
grant execute on function public.admin_claim_crm_task(uuid) to authenticated;

comment on function public.admin_crm_queue is
  'Phase 2 role-checked CRM queue. CALLER sees unassigned and own tasks; ADMIN sees all.';
