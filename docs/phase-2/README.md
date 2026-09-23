# Phase 2 — Admin / CRM

Phase 2 is being delivered as vertical slices so an operator can start working
while the remaining CRM screens are built.

## Implemented in the first slice

- Angular Admin/CRM application with Supabase email/password login;
- active `ADMIN` and `CALLER` role gate backed by `admin_users`;
- demand-prioritized CRM queue;
- one-click, race-safe task claim;
- user-request, place-open and navigation demand indicators;
- responsive operator UI;
- production multi-stage Docker image and Nginx health endpoint;
- runtime browser configuration from the server-side `.env.local`;
- RLS/RPC pgTAP coverage, Angular unit tests and container smoke tests in CI.

The first slice intentionally does not expose the service-role key to the
browser. The Admin application uses the anon key plus the signed-in operator's
JWT; PostgreSQL remains the authorization boundary.

## Next slices

1. Place detail and contact history.
2. Structured verification questionnaire and policy version creation.
3. Call outcomes, callback scheduling and task completion.
4. Information-request and seed-lead queues.
5. Reports, re-verification and the operational analytics dashboard.

These items follow the order in GDD v0.1. The current queue is already driven
by the Phase 1 demand score, where explicit information requests outweigh
passive opens and navigation.

## Local checks

```bash
cd web/admin
npm ci
npm test -- --watch=false
npm run build
```

For the production-shaped Docker workflow and first operator bootstrap, see
[`docs/server-runbook.md`](../server-runbook.md).
