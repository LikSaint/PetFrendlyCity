import { readFile } from "node:fs/promises";

export async function loadEnvFile(path) {
  const source = await readFile(path, "utf8");
  const values = new Map();

  for (const rawLine of source.split(/\r?\n/u)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const separator = line.indexOf("=");
    if (separator < 1) continue;
    const key = line.slice(0, separator).trim();
    const value = line.slice(separator + 1).trim().replace(/^(["'])(.*)\1$/u, "$2");
    values.set(key, value);
  }

  return values;
}

export function requireValues(values, keys, context) {
  const missing = keys.filter((key) => !values.get(key));
  if (missing.length > 0) {
    throw new Error(`Missing ${context}: ${missing.join(", ")}`);
  }
  return Object.fromEntries(keys.map((key) => [key, values.get(key)]));
}
