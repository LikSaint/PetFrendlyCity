create type public.place_area as enum (
  'INDOOR',
  'TERRACE',
  'OUTDOOR',
  'GARDEN'
);

create type public.place_amenity as enum (
  'WATER',
  'DOG_MENU',
  'TREATS',
  'DOG_AREA',
  'OUTDOOR_SEATING'
);

create type public.verification_source as enum (
  'VENUE_MANAGER',
  'VENUE_STAFF',
  'PHONE',
  'EMAIL',
  'OFFICIAL_WEBSITE',
  'FIELD_VISIT'
);

create type public.information_request_status as enum (
  'OPEN',
  'IN_PROGRESS',
  'RESOLVED',
  'CANCELLED'
);

create type public.admin_role as enum (
  'ADMIN',
  'CALLER',
  'EDITOR',
  'EVENT_MANAGER'
);

create type public.analytics_event_type as enum (
  'APP_OPEN',
  'MAP_OPEN',
  'MAP_MOVE',
  'MAP_ZOOM',
  'FILTER_OPEN',
  'FILTER_APPLY',
  'FILTER_CLEAR',
  'SEARCH',
  'SEARCH_RESULT_OPEN',
  'PLACE_IMPRESSION',
  'PLACE_OPEN',
  'PET_INFO_VIEW',
  'PET_INFO_MISSING_VIEW',
  'REQUEST_INFORMATION',
  'GOOGLE_REVIEWS_OPEN',
  'NAVIGATION_CLICK',
  'NAVIGATION_PROVIDER_SELECTED',
  'FAVORITE_ADD',
  'FAVORITE_REMOVE',
  'EVENT_VIEW',
  'EVENT_NAVIGATE',
  'PET_REVIEW_START',
  'PET_REVIEW_SUBMIT',
  'POLICY_REPORT',
  'DOG_PROFILE_CREATE',
  'REGISTRATION_START',
  'REGISTRATION_COMPLETE'
);

create type public.crm_task_type as enum (
  'VERIFY_POLICY',
  'REVERIFY_POLICY',
  'FOLLOW_UP',
  'RESOLVE_REPORT'
);

create type public.crm_task_status as enum (
  'OPEN',
  'IN_PROGRESS',
  'WAITING_CALLBACK',
  'COMPLETED',
  'CANCELLED'
);

create type public.crm_seed_lead_status as enum (
  'NEW',
  'MATCHED',
  'CONTACTING',
  'VERIFIED',
  'REJECTED',
  'DUPLICATE'
);

create type public.crm_contact_channel as enum (
  'PHONE',
  'EMAIL',
  'WEBSITE',
  'SOCIAL',
  'IN_PERSON'
);

create type public.crm_call_outcome as enum (
  'NO_ANSWER',
  'CALLBACK_REQUESTED',
  'POLICY_VERIFIED',
  'POLICY_UNAVAILABLE',
  'WRONG_CONTACT'
);

create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role public.admin_role not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.place_access_rules (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  area public.place_area not null,
  allowed boolean not null,
  max_weight_kg numeric(6, 2),
  leash_required boolean,
  muzzle_required boolean,
  carrier_required boolean,
  max_dogs smallint,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (place_id, area),
  check (max_weight_kg is null or max_weight_kg > 0),
  check (max_dogs is null or max_dogs > 0)
);

create table public.place_amenities (
  place_id uuid not null references public.places(id) on delete cascade,
  amenity public.place_amenity not null,
  created_at timestamptz not null default now(),
  primary key (place_id, amenity)
);

create table public.place_verifications (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  source public.verification_source not null,
  verified_at timestamptz not null default now(),
  verified_by_admin uuid references public.admin_users(user_id) on delete set null,
  contact_role text,
  notes text,
  created_at timestamptz not null default now()
);

create index place_verifications_place_verified_idx
  on public.place_verifications (place_id, verified_at desc);

create table public.place_policy_versions (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  version integer not null check (version > 0),
  changed_by uuid references public.admin_users(user_id) on delete set null,
  reason text not null check (length(trim(reason)) > 0),
  snapshot jsonb not null check (jsonb_typeof(snapshot) = 'object'),
  normalized_differences jsonb not null default '{}'::jsonb
    check (jsonb_typeof(normalized_differences) = 'object'),
  created_at timestamptz not null default now(),
  unique (place_id, version)
);

create table public.place_information_requests (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  anonymous_user_id uuid,
  user_id uuid references auth.users(id) on delete set null,
  status public.information_request_status not null default 'OPEN',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  check (anonymous_user_id is not null or user_id is not null),
  check ((status = 'RESOLVED' and resolved_at is not null) or status <> 'RESOLVED')
);

create unique index place_information_requests_anonymous_uidx
  on public.place_information_requests (place_id, anonymous_user_id)
  where anonymous_user_id is not null;

create unique index place_information_requests_user_uidx
  on public.place_information_requests (place_id, user_id)
  where user_id is not null;

create index place_information_requests_queue_idx
  on public.place_information_requests (status, created_at);

create table public.analytics_events (
  id uuid primary key default extensions.gen_random_uuid(),
  anonymous_user_id uuid,
  user_id uuid references auth.users(id) on delete set null,
  session_id uuid not null,
  event_type public.analytics_event_type not null,
  place_id uuid references public.places(id) on delete set null,
  event_id uuid,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  created_at timestamptz not null default now(),
  check (anonymous_user_id is not null or user_id is not null)
);

create index analytics_events_place_type_created_idx
  on public.analytics_events (place_id, event_type, created_at desc)
  where place_id is not null;

create index analytics_events_session_created_idx
  on public.analytics_events (session_id, created_at);

create table public.crm_seed_leads (
  id uuid primary key default extensions.gen_random_uuid(),
  google_place_id text,
  source text not null check (length(trim(source)) > 0),
  source_url text,
  source_date date,
  source_note text,
  status public.crm_seed_lead_status not null default 'NEW',
  priority integer not null default 0 check (priority >= 0),
  assigned_to uuid references public.admin_users(user_id) on delete set null,
  matched_place_id uuid references public.places(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index crm_seed_leads_google_place_uidx
  on public.crm_seed_leads (google_place_id)
  where google_place_id is not null;

create table public.crm_contacts (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid references public.places(id) on delete cascade,
  seed_lead_id uuid references public.crm_seed_leads(id) on delete cascade,
  channel public.crm_contact_channel not null,
  contact_role text,
  contact_value text not null check (length(trim(contact_value)) > 0),
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (place_id is not null or seed_lead_id is not null)
);

create table public.crm_tasks (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid references public.places(id) on delete cascade,
  seed_lead_id uuid references public.crm_seed_leads(id) on delete cascade,
  task_type public.crm_task_type not null,
  status public.crm_task_status not null default 'OPEN',
  priority_score numeric(12, 2) not null default 0 check (priority_score >= 0),
  assigned_to uuid references public.admin_users(user_id) on delete set null,
  due_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz,
  check (place_id is not null or seed_lead_id is not null),
  check ((status = 'COMPLETED' and completed_at is not null) or status <> 'COMPLETED')
);

create unique index crm_tasks_one_active_verification_per_place_uidx
  on public.crm_tasks (place_id)
  where place_id is not null
    and task_type in ('VERIFY_POLICY', 'REVERIFY_POLICY')
    and status in ('OPEN', 'IN_PROGRESS', 'WAITING_CALLBACK');

create index crm_tasks_queue_idx
  on public.crm_tasks (status, priority_score desc, created_at);

create table public.crm_calls (
  id uuid primary key default extensions.gen_random_uuid(),
  task_id uuid not null references public.crm_tasks(id) on delete cascade,
  caller_id uuid references public.admin_users(user_id) on delete set null,
  contact_id uuid references public.crm_contacts(id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  outcome public.crm_call_outcome,
  callback_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  check (ended_at is null or ended_at >= started_at)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger places_set_updated_at
before update on public.places
for each row execute function public.set_updated_at();

create trigger admin_users_set_updated_at
before update on public.admin_users
for each row execute function public.set_updated_at();

create trigger place_access_rules_set_updated_at
before update on public.place_access_rules
for each row execute function public.set_updated_at();

create trigger crm_seed_leads_set_updated_at
before update on public.crm_seed_leads
for each row execute function public.set_updated_at();

create trigger crm_contacts_set_updated_at
before update on public.crm_contacts
for each row execute function public.set_updated_at();

create trigger crm_tasks_set_updated_at
before update on public.crm_tasks
for each row execute function public.set_updated_at();

create or replace function public.discover_google_place(
  google_place_id text,
  latitude double precision,
  longitude double precision
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  resolved_place_id uuid;
begin
  if google_place_id is null or length(trim(google_place_id)) = 0 then
    raise exception 'google_place_id must not be blank' using errcode = '22023';
  end if;
  if latitude not between -90 and 90 or longitude not between -180 and 180 then
    raise exception 'coordinates are outside WGS84 bounds' using errcode = '22023';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended('GOOGLE:' || google_place_id, 0)
  );

  select ref.place_id
  into resolved_place_id
  from public.external_place_refs ref
  where ref.provider = 'GOOGLE' and ref.external_id = google_place_id;

  if resolved_place_id is null then
    insert into public.places (location)
    values (
      extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
    )
    returning id into resolved_place_id;

    insert into public.external_place_refs (place_id, provider, external_id)
    values (resolved_place_id, 'GOOGLE', google_place_id);
  else
    update public.places
    set last_seen_at = now()
    where id = resolved_place_id;
  end if;

  return resolved_place_id;
end;
$$;

create or replace function public.enqueue_information_request_task()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  insert into public.crm_tasks (place_id, task_type, priority_score)
  values (new.place_id, 'VERIFY_POLICY', 1000)
  on conflict (place_id)
    where place_id is not null
      and task_type in ('VERIFY_POLICY', 'REVERIFY_POLICY')
      and status in ('OPEN', 'IN_PROGRESS', 'WAITING_CALLBACK')
  do update set priority_score = greatest(public.crm_tasks.priority_score, 1000);
  return new;
end;
$$;

create trigger place_information_requests_enqueue_task
after insert on public.place_information_requests
for each row execute function public.enqueue_information_request_task();

create or replace function public.request_place_information(
  requested_place_id uuid,
  requesting_anonymous_user_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  authenticated_user_id uuid := auth.uid();
  request_id uuid;
begin
  if authenticated_user_id is null and requesting_anonymous_user_id is null then
    raise exception 'anonymous_user_id is required without authentication' using errcode = '22023';
  end if;

  if authenticated_user_id is not null then
    insert into public.place_information_requests (place_id, user_id)
    values (requested_place_id, authenticated_user_id)
    on conflict (place_id, user_id) where user_id is not null
    do update set place_id = excluded.place_id
    returning id into request_id;
  else
    insert into public.place_information_requests (place_id, anonymous_user_id)
    values (requested_place_id, requesting_anonymous_user_id)
    on conflict (place_id, anonymous_user_id) where anonymous_user_id is not null
    do update set place_id = excluded.place_id
    returning id into request_id;
  end if;

  return request_id;
end;
$$;

create view public.crm_place_demand as
with request_counts as (
  select
    place_id,
    count(*)::bigint as request_count,
    count(distinct coalesce(user_id::text, 'anonymous:' || anonymous_user_id::text))::bigint
      as unique_requesters
  from public.place_information_requests
  group by place_id
), event_counts as (
  select
    place_id,
    count(*) filter (where event_type = 'PLACE_OPEN')::bigint as place_open_count,
    count(*) filter (where event_type = 'NAVIGATION_CLICK')::bigint as navigation_count
  from public.analytics_events
  where place_id is not null
  group by place_id
)
select
  p.id as place_id,
  coalesce(r.unique_requesters, 0) as unique_requesters,
  coalesce(r.request_count, 0) as request_count,
  coalesce(e.place_open_count, 0) as place_open_count,
  coalesce(e.navigation_count, 0) as navigation_count,
  (
    coalesce(r.unique_requesters, 0) * 1000
    + coalesce(e.navigation_count, 0) * 20
    + coalesce(e.place_open_count, 0) * 5
  )::numeric(14, 2) as priority_score
from public.places p
left join request_counts r on r.place_id = p.id
left join event_counts e on e.place_id = p.id;

alter table public.places enable row level security;
alter table public.external_place_refs enable row level security;
alter table public.place_access_rules enable row level security;
alter table public.place_amenities enable row level security;
alter table public.place_verifications enable row level security;
alter table public.place_policy_versions enable row level security;
alter table public.place_information_requests enable row level security;
alter table public.analytics_events enable row level security;
alter table public.admin_users enable row level security;
alter table public.crm_seed_leads enable row level security;
alter table public.crm_contacts enable row level security;
alter table public.crm_tasks enable row level security;
alter table public.crm_calls enable row level security;

create policy places_public_read on public.places
  for select to anon, authenticated using (true);
create policy external_place_refs_public_read on public.external_place_refs
  for select to anon, authenticated using (true);
create policy place_access_rules_public_read on public.place_access_rules
  for select to anon, authenticated using (true);
create policy place_amenities_public_read on public.place_amenities
  for select to anon, authenticated using (true);
create policy place_verifications_public_read on public.place_verifications
  for select to anon, authenticated using (true);

grant select on public.places, public.external_place_refs, public.place_access_rules,
  public.place_amenities, public.place_verifications to anon, authenticated;
grant execute on function public.places_nearby(double precision, double precision, integer, integer)
  to anon, authenticated;
grant execute on function public.discover_google_place(text, double precision, double precision)
  to anon, authenticated;
grant execute on function public.request_place_information(uuid, uuid)
  to anon, authenticated;

revoke all on public.admin_users, public.crm_seed_leads, public.crm_contacts,
  public.crm_tasks, public.crm_calls from anon, authenticated;

comment on view public.crm_place_demand is
  'Demand-weighted CRM input. User requests intentionally dominate passive analytics.';
