begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(14);

select extensions.has_table('public', 'place_access_rules', 'pet-policy access rules exist');
select extensions.has_table('public', 'place_verifications', 'verification history exists');
select extensions.has_table('public', 'place_information_requests', 'information requests exist');
select extensions.has_table('public', 'analytics_events', 'analytics storage exists');
select extensions.has_table('public', 'crm_tasks', 'CRM task queue exists');

select public.discover_google_place('ChIJ-phase-1', 40.4093, 49.8671);
select public.discover_google_place('ChIJ-phase-1', 40.4093, 49.8671);

select extensions.is(
  (
    select count(*)::integer
    from public.external_place_refs
    where provider = 'GOOGLE' and external_id = 'ChIJ-phase-1'
  ),
  1,
  'Google discovery is idempotent'
);

select public.request_place_information(
  (select place_id from public.external_place_refs where external_id = 'ChIJ-phase-1'),
  '10000000-0000-0000-0000-000000000001'::uuid
);
select public.request_place_information(
  (select place_id from public.external_place_refs where external_id = 'ChIJ-phase-1'),
  '10000000-0000-0000-0000-000000000001'::uuid
);

select extensions.is(
  (select count(*)::integer from public.place_information_requests),
  1,
  'repeated information request does not inflate demand'
);

select extensions.is(
  (select count(*)::integer from public.crm_tasks where status = 'OPEN'),
  1,
  'information request creates one aggregated CRM task'
);

insert into public.place_access_rules (
  place_id, area, allowed, max_weight_kg, leash_required
)
select place_id, 'INDOOR', true, 10, true
from public.external_place_refs
where external_id = 'ChIJ-phase-1';

insert into public.place_amenities (place_id, amenity)
select place_id, 'WATER'
from public.external_place_refs
where external_id = 'ChIJ-phase-1';

select extensions.is(
  (select max_weight_kg from public.place_access_rules limit 1),
  10.00::numeric,
  'normalized policy stores area-specific weight limit'
);

select extensions.is(
  (select count(*)::integer from public.place_amenities where amenity = 'WATER'),
  1,
  'normalized amenities are stored independently'
);

insert into public.analytics_events (
  anonymous_user_id,
  session_id,
  event_type,
  place_id
)
select
  '10000000-0000-0000-0000-000000000001'::uuid,
  '20000000-0000-0000-0000-000000000001'::uuid,
  event_type,
  place_id
from public.external_place_refs
cross join (values
  ('PLACE_OPEN'::public.analytics_event_type),
  ('NAVIGATION_CLICK'::public.analytics_event_type)
) as events(event_type)
where external_id = 'ChIJ-phase-1';

select extensions.is(
  (select place_open_count::integer from public.crm_place_demand limit 1),
  1,
  'CRM demand aggregates place opens'
);

select extensions.is(
  (select navigation_count::integer from public.crm_place_demand limit 1),
  1,
  'CRM demand aggregates navigation clicks'
);

select extensions.ok(
  (select priority_score >= 1025 from public.crm_place_demand limit 1),
  'explicit request dominates passive analytics in priority score'
);

select extensions.is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'public' and tablename = 'places' and policyname = 'places_public_read'
  ),
  1,
  'public place reads are explicitly protected by RLS policy'
);

select * from extensions.finish();
rollback;
