import type { Config } from "drizzle-kit";

const url = process.env.DATABASE_URL ?? "postgres://placeholder@localhost:5432/likhita";

export default {
  schema: "./db/schema.ts",
  out: "./db/migrations",
  dialect: "postgresql",
  dbCredentials: { url },
  strict: true,
  verbose: true,
} satisfies Config;
