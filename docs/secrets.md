# Keys and credentials

`.env.local` is the single source of local keys and credentials. It is ignored by
Git. `.env.example` contains the complete variable inventory without values and
is safe to commit.

The same convention is used on the deployment server. The file should be owned
by the deployment user with mode `600`.

Rules:

1. Never place real values in Gradle files, `Info.plist`, Angular environments,
   Supabase migrations, documentation, issues, or CI logs.
2. Use a separate restricted Google key for Android, iOS, and server workloads.
3. CI values must use repository/environment secrets with the same names.
4. Generated platform configuration must be derived from `.env.local`; it must
   stay ignored and must not become another source of truth.
5. Rotate a key immediately if it appears in Git history or logs.

Validate only the credentials needed for the current workflow:

```bash
npm run secrets:check -- google-android
npm run secrets:check -- google-ios
npm run secrets:check -- supabase-remote
npm run secrets:check -- email
```

The validator prints variable names only, never values.
