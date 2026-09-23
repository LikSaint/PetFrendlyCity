import { loadEnvFile } from "./lib/env-file.mjs";

const profiles = {
  "google-android": ["GOOGLE_MAPS_ANDROID_API_KEY"],
  "google-ios": ["GOOGLE_MAPS_IOS_API_KEY"],
  "supabase-remote": [
    "SUPABASE_URL",
    "SUPABASE_ANON_KEY",
    "SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_PROJECT_REF",
    "SUPABASE_ACCESS_TOKEN",
    "SUPABASE_DB_PASSWORD",
  ],
  email: ["RESEND_API_KEY", "RESEND_FROM_EMAIL"],
  fcm: ["FCM_SERVICE_ACCOUNT_JSON_BASE64"],
  apns: ["APNS_KEY_ID", "APNS_TEAM_ID", "APNS_PRIVATE_KEY_BASE64"],
  r2: [
    "CLOUDFLARE_ACCOUNT_ID",
    "CLOUDFLARE_R2_ACCESS_KEY_ID",
    "CLOUDFLARE_R2_SECRET_ACCESS_KEY",
    "CLOUDFLARE_R2_BUCKET",
  ],
};

const profile = process.argv[2];
if (!profile || !(profile in profiles)) {
  console.error(`Usage: node scripts/secrets.mjs <${Object.keys(profiles).join("|")}>`);
  process.exit(2);
}

let values;
try {
  values = await loadEnvFile(new URL("../.env.local", import.meta.url));
} catch {
  console.error("Missing .env.local. Copy .env.example to .env.local first.");
  process.exit(1);
}

const missing = profiles[profile].filter((key) => !values.get(key));
if (missing.length > 0) {
  console.error(`Missing ${profile} secrets: ${missing.join(", ")}`);
  process.exit(1);
}

console.log(`${profile}: configured (${profiles[profile].join(", ")})`);
