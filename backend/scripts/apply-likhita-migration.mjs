// Apply a likhita migration via raw SQL — no drizzle introspection.
// Usage: DATABASE_URL=... node scripts/apply-likhita-migration.mjs db/migrations/0002_batch_storage.sql
//
// Why this exists: drizzle-kit push compares the LIVE database against
// our schema definition and proposes DROP TABLE for anything not in our
// schema. The Neon DB is shared (chain911 in `public`, rocket-merch's
// `waitlist` in `public`), so push has dropped their tables in the past.
// This script reads a single .sql file and applies it — no introspection,
// no cross-schema awareness, no chance of touching public.* or any other
// project's schema.
import { neon } from "@neondatabase/serverless";
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) {
  console.error("Usage: node scripts/apply-likhita-migration.mjs <migration.sql>");
  process.exit(1);
}

const url = process.env.DATABASE_URL;
if (!url) {
  console.error("DATABASE_URL is required");
  process.exit(1);
}

const sqlText = readFileSync(file, "utf8");

// Quick sanity check — refuse anything that references public.* tables we
// don't own. This is a belt-and-suspenders guard; the file should only
// touch likhita.* tables.
const FORBIDDEN_PATTERNS = [
  /\bDROP\s+TABLE\s+(?!IF\s+EXISTS\s+["']?likhita)["']?(?!likhita)/i,
  /\bDROP\s+SCHEMA\s+(?!likhita)/i,
  /\bTRUNCATE\s+(?:TABLE\s+)?(?!["']?likhita)/i,
];
for (const re of FORBIDDEN_PATTERNS) {
  const m = sqlText.match(re);
  if (m) {
    console.error(`Refusing — migration touches non-likhita schema at: ${m[0]}`);
    console.error("If this is intentional, run the SQL by hand against the right project's DB.");
    process.exit(2);
  }
}

const sql = neon(url);
console.log(`Applying ${file} (${sqlText.length} bytes) …`);
// Strip whole-line `--` comments before splitting so a statement that
// happens to start the file or follow a comment block isn't swallowed
// by the post-split `startsWith("--")` filter.
const sanitized = sqlText
  .split("\n")
  .filter((line) => !line.trim().startsWith("--"))
  .join("\n");
const statements = sanitized
  .split(/;\s*$/m)
  .map((s) => s.trim())
  .filter((s) => s.length > 0);

let i = 0;
for (const stmt of statements) {
  i += 1;
  const preview = stmt.replace(/\s+/g, " ").slice(0, 100);
  process.stdout.write(`  [${i}/${statements.length}] ${preview} … `);
  try {
    // The Neon serverless `sql` tag accepts a string template, but for
    // multi-line DDL we need the raw-string escape hatch. `sql([raw])`
    // bypasses parameterization (which is what we want for DDL).
    await sql(stmt);
    console.log("ok");
  } catch (err) {
    console.log("FAILED");
    console.error(err);
    process.exit(3);
  }
}
console.log("done.");
