# Pet-Friendly City Admin / CRM

Phase 2 operator application. Product scope and rollout status are documented
in [`docs/phase-2/README.md`](../../docs/phase-2/README.md).

## Development server

Install dependencies and start the local server:

```bash
npm ci
npm start
```

Set a local Supabase URL and anon key in `public/config/runtime-config.js` when
needed. Never put the service-role key in this browser application. Open
`http://localhost:4200/`; the application reloads when source files change.

## Checks

```bash
npm test -- --watch=false
npm run build
```

The production build is written to `dist/`.

## Production container

The repository-level Compose service writes runtime configuration from the
ignored `.env.local` when the container starts. The same immutable image can
therefore be used in every environment. See
[`docs/server-runbook.md`](../../docs/server-runbook.md) for deployment,
health-check and reverse-proxy instructions.
