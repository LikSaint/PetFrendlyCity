# Server runbook

The MVP follows GDD v0.1: application processes run on our server, while the
initial PostgreSQL/PostGIS/Auth/API instance is managed by Supabase Cloud. This
keeps migration paths open without taking on self-hosted Supabase operations.

## Server prerequisites

- Linux server with Git;
- Node.js 20 or newer and npm;
- outbound HTTPS access to GitHub, npm and Supabase;
- Docker Engine with the Compose plugin;
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

Restart the Admin/CRM service after applying migrations:

```bash
npm run docker:up
curl --fail http://127.0.0.1:8088/healthz
```

The public SSR service is planned for Phase 5.

## Docker workflow

The current Compose project is intentionally isolated from other server projects:

- project name: `pet-friendly-city`;
- network name: `pet-friendly-city-internal`;
- Admin binds only to `127.0.0.1:8088` by default;
- no persistent or shared volumes;
- no Docker daemon restart;
- database-operation containers are one-shot and removed after the command;
- the Admin container is the only long-running Phase 2 service.

Build the pinned ops image:

```bash
npm run docker:build
```

Start or update Admin/CRM:

```bash
npm run docker:up
npm run docker:logs
```

The Admin container exposes an HTTP health endpoint at
`http://127.0.0.1:8088/healthz`. Put the existing server reverse proxy in front
of this address and terminate TLS there. To use another loopback port, change
`ADMIN_HTTP_PORT` in `.env.local`; do not expose the port publicly unless the
server firewall and TLS proxy are configured for it.

Preview database migrations from the container:

```bash
npm run docker:db:plan
```

Apply only after reviewing the preview:

```bash
npm run docker:db:deploy
```

Compose reads the same server-side `.env.local`; it is excluded from the image
build context. The container runs as a non-root user with a read-only filesystem,
dropped Linux capabilities and no host mounts.

## First Admin user

1. Create the operator in Supabase Authentication with an email and a strong
   password. Do not store the password in `.env.local` or Git.
2. In the Supabase SQL editor, assign an application role to that auth user:

```sql
insert into public.admin_users (user_id, role)
select id, 'ADMIN'::public.admin_role
from auth.users
where email = 'replace-with-admin-email@example.com'
on conflict (user_id) do update
set role = excluded.role, active = true;
```

Use `CALLER` instead of `ADMIN` for operators who should only see unassigned
tasks and tasks assigned to themselves. The browser receives only
`SUPABASE_ANON_KEY`; authorization remains enforced by database RLS and RPCs.

## Production boundaries

- `.env.local` exists only on the target server;
- the service-role key is server-only and never enters mobile or browser builds;
- mobile/browser clients receive only the Supabase anon key;
- database changes are applied only from committed migrations;
- `db reset --linked` and remote seed deployment are forbidden in production.
