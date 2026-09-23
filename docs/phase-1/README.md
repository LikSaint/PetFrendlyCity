# Phase 1 — Backend / Schema

Phase 1 starts by turning the PostGIS spike into the normalized backend core from
GDD v0.1. The migration remains provider-neutral: Supabase supplies PostgreSQL,
Auth and API, while business rules live in SQL/domain contracts.

## Implemented

- stable Place discovery through a Google external reference;
- idempotent discovery under concurrent requests;
- area-specific pet access rules and normalized amenities;
- verification history and versioned policy snapshots;
- anti-spam information requests for anonymous and authenticated users;
- automatic aggregation into one active verification CRM task per Place;
- typed analytics event storage and demand-weighted CRM view;
- seed leads, contacts, tasks and call history;
- admin roles and public/internal RLS boundaries;
- migration, lint and pgTAP coverage in CI.

## Deliberately deferred

- reviews, community reports and events belong to the public MVP slices that
  consume this foundation;
- account profiles and favorites remain Phase 6;
- provider keys are not embedded in database objects and stay in `.env.local`;
- policy editing RPCs arrive with Phase 2 Admin/CRM authorization workflows.

## Invariants

1. Google content is referenced by `google_place_id`, not copied into the core.
2. A repeated user request does not increase demand more than once.
3. One Place has at most one active verification/reverification task.
4. Explicit user requests outweigh passive opens and navigation in CRM priority.
5. Internal CRM relations have RLS enabled and no anonymous grants.
