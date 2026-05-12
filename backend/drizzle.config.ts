import type { Config } from "drizzle-kit";

const url = process.env.DATABASE_URL ?? "postgres://placeholder@localhost:5432/likhita";

// CRITICAL — DO NOT REMOVE schemaFilter
// ----------------------------------------------------------------------
// This Neon database is SHARED with other projects (chain911 in `public`,
// rocket-merch's `waitlist` table in `public`, …). On 2026-05-12 a
// `drizzle-kit push --force` introspected the entire DB and dropped every
// `public.*` table not present in our schema definition (reporters, teams,
// alerts, decisions, audit_log, webhooks, waitlist — all gone, taking real
// user signups with them).
//
// `schemaFilter: ["likhita"]` scopes every introspection + diff to OUR
// schema only. drizzle-kit push and drizzle-kit generate will not even
// SEE tables outside `likhita.*`, so they cannot propose dropping them.
//
// If you ever need to introspect outside `likhita`, do it as a one-off
// raw SQL query — never broaden this filter.
export default {
  schema: "./db/schema.ts",
  out: "./db/migrations",
  dialect: "postgresql",
  dbCredentials: { url },
  strict: true,
  verbose: true,
  schemaFilter: ["likhita"],
  tablesFilter: ["likhita.*"],
} satisfies Config;
