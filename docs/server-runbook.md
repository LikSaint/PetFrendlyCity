# Server runbook

The MVP follows GDD v0.1: application processes run on our server, while the
initial PostgreSQL/PostGIS/Auth/API instance is managed by Supabase Cloud. This
keeps migration paths open without taking on self-hosted Supabase operations.

## Server prerequisites

- Linux server with Git;
- Node.js 20 or newer and npm;
- outbound HTTPS access to GitHub, npm and Supabase;
- Docker for later Web/Admin containers (not required for remote DB migrations);
- JDK 21 only if the server should run KMP checks.

## First checkout

```bash
git clone git@github.com:LikSaint/PetFrendlyCity.git
cd PetFrendlyCity
cp .env.example .env.local
npm ci
npm run server:check
```

Fill `.env.local` directly on the server. Never copy it back into Git. File mode
should be restricted to the deployment user:

```bash
chmod 600 .env.local
npm run secrets:check -- supabase-remote
```

## Database deployment

Always preview pending migrations first:

```bash
npm run db:deploy:dry
```

After reviewing the output:

```bash
npm run db:deploy
```

The script passes passwords through environment variables, not command-line
arguments, and never logs secret values. Supabase migration history makes
repeated deployments idempotent.

## Updating the server

```bash
git pull --ff-only
npm ci
npm run server:check
npm run db:deploy:dry
npm run db:deploy
```

There is no long-running Web/Admin process yet: the repository is currently in
the backend/schema phase. Phase 2 will add the Admin/CRM service, its production
container and health check; Phase 5 will add the public SSR service.

## Production boundaries

- `.env.local` exists only on the target server;
- the service-role key is server-only and never enters mobile or browser builds;
- mobile/browser clients receive only the Supabase anon key;
- database changes are applied only from committed migrations;
- `db reset --linked` and remote seed deployment are forbidden in production.
