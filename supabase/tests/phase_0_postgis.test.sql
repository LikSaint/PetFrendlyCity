begin;

create extension if not exists pgtap with schema extensions;

select extensions.plan(4);

insert into public.places (id, location)
values
  (
    '00000000-0000-0000-0000-000000000001',
    extensions.st_setsrid(extensions.st_makepoint(49.8671, 40.4093), 4326)::extensions.geography
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    extensions.st_setsrid(extensions.st_makepoint(49.7000, 40.3000), 4326)::extensions.geography
  );

select extensions.is(
  (select count(*)::integer from public.places_nearby(40.4093, 49.8671, 3000, 100)),
  1,
  '3 km query returns only the nearby Baku place'
);

select extensions.is(
  (select place_id from public.places_nearby(40.4093, 49.8671, 3000, 100) limit 1),
  '00000000-0000-0000-0000-000000000001'::uuid,
  'nearby query returns the expected stable place id'
);

select extensions.ok(
  (select distance_meters < 1 from public.places_nearby(40.4093, 49.8671, 3000, 100) limit 1),
  'distance is calculated in meters'
);

select extensions.is(
  (select count(*)::integer from public.places_nearby(91, 49.8671, 3000, 100)),
  0,
  'invalid latitude is rejected with an empty result'
);

select * from extensions.finish();
rollback;
