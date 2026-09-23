import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { loadEnvFile, requireValues } from "./lib/env-file.mjs";

const apply = process.argv.includes("--apply");
const envPath = resolve(".env.local");
const cliPath = resolve(
  "node_modules",
  ".bin",
  process.platform === "win32" ? "supabase.cmd" : "supabase",
);

if (!existsSync(cliPath)) {
  console.error("Supabase CLI is missing. Run npm ci first.");
  process.exit(1);
}

let values;
try {
  values = await loadEnvFile(envPath);
} catch {
  console.error("Missing .env.local. Copy .env.example and fill Supabase credentials.");
  process.exit(1);
}

let credentials;
try {
  credentials = requireValues(
    values,
    ["SUPABASE_PROJECT_REF", "SUPABASE_ACCESS_TOKEN", "SUPABASE_DB_PASSWORD"],
    "Supabase deployment credentials",
  );
} catch (error) {
  console.error(error.message);
  process.exit(1);
}

const childEnv = {
  ...process.env,
  SUPABASE_ACCESS_TOKEN: credentials.SUPABASE_ACCESS_TOKEN,
  SUPABASE_DB_PASSWORD: credentials.SUPABASE_DB_PASSWORD,
};

function run(args) {
  const result = spawnSync(cliPath, args, {
    cwd: resolve("."),
    env: childEnv,
    stdio: "inherit",
  });
  if (result.error) throw result.error;
  if (result.status !== 0) process.exit(result.status ?? 1);
}

console.log(`Linking Supabase project ${credentials.SUPABASE_PROJECT_REF}...`);
run(["link", "--project-ref", credentials.SUPABASE_PROJECT_REF, "--yes"]);

if (!apply) {
  console.log("Dry run: no remote migration will be applied.");
  run(["db", "push", "--linked", "--include-all", "--skip-vault", "--dry-run"]);
  console.log("Dry run complete. Use npm run db:deploy only after reviewing the plan.");
} else {
  console.log("Applying pending migrations to the linked Supabase project...");
  run(["db", "push", "--linked", "--include-all", "--skip-vault", "--yes"]);
  console.log("Database deployment complete.");
}
