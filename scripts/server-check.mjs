import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";

const failures = [];

function commandVersion(command, args, required = true) {
  const result = spawnSync(command, args, { encoding: "utf8" });
  if (result.status !== 0) {
    const label = required ? "missing" : "optional, unavailable";
    console.log(`${command}: ${label}`);
    if (required) failures.push(command);
    return null;
  }
  const version = (result.stdout || result.stderr).trim().split("\n")[0];
  console.log(`${command}: ${version}`);
  return version;
}

const nodeVersion = commandVersion("node", ["--version"]);
commandVersion("npm", ["--version"]);
commandVersion("git", ["--version"]);
commandVersion("docker", ["--version"], false);
commandVersion("java", ["-version"], false);

if (nodeVersion) {
  const major = Number(nodeVersion.replace(/^v/u, "").split(".")[0]);
  if (!Number.isInteger(major) || major < 20) {
    failures.push("Node.js 20+");
    console.error(`Node.js ${nodeVersion} is unsupported; install Node.js 20 or newer.`);
  }
}

for (const path of ["package-lock.json", ".env.local", "supabase/config.toml"]) {
  if (!existsSync(path)) {
    failures.push(path);
    console.error(`${path}: missing`);
  } else {
    console.log(`${path}: present`);
  }
}

if (failures.length > 0) {
  console.error(`Server check failed: ${failures.join(", ")}`);
  process.exit(1);
}

console.log("Server prerequisites are ready for the current backend phase.");
