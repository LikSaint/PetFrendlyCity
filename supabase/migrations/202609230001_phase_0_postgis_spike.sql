create extension if not exists pgcrypto with schema extensions;
create extension if not exists postgis with schema extensions;

create type public.place_status as enum (
  'DISCOVERED',
  'COMMUNITY_DATA',
  'VERIFIED',
  'NEEDS_REVERIFICATION'
);

create type public.pet_policy_status as enum (
  'UNKNOWN',
  'COMMUNITY_REPORTED',
  'VERIFIED',
  'NEEDS_REVERIFICATION'
);

create table public.places (
  id uuid primary key default extensions.gen_random_uuid(),
  status public.place_status not null default 'DISCOVERED',
  pet_policy_status public.pet_policy_status not null default 'UNKNOWN',
  location extensions.geography(Point, 4326) not null,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index places_location_gix on public.places using gist (location);

create table public.external_place_refs (
  id uuid primary key default extensions.gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  provider text not null check (provider in ('GOOGLE')),
  external_id text not null check (length(trim(external_id)) > 0),
  created_at timestamptz not null default now(),
  unique (provider, external_id)
);

create or replace function public.places_nearby(
  latitude double precision,
  longitude double precision,
  radius_meters integer default 3000,
  result_limit integer default 100
)
returns table (
  place_id uuid,
  status public.place_status,
  pet_policy_status public.pet_policy_status,
  latitude double precision,
  longitude double precision,
  distance_meters double precision
)
language sql
stable
set search_path = ''
as $$
  select
    p.id,
    p.status,
    p.pet_policy_status,
    extensions.st_y(p.location::extensions.geometry),
    extensions.st_x(p.location::extensions.geometry),
    extensions.st_distance(
      p.location,
      extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
    )
  from public.places p
  where radius_meters between 1 and 50000
    and result_limit between 1 and 500
    and latitude between -90 and 90
    and longitude between -180 and 180
    and extensions.st_dwithin(
      p.location,
      extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography,
      radius_meters
    )
  order by p.location operator(extensions.<->)
    extensions.st_setsrid(extensions.st_makepoint(longitude, latitude), 4326)::extensions.geography
  limit result_limit;
$$;

comment on function public.places_nearby is
  'Phase 0 spike: returns our pet-layer places around a WGS84 point.';
