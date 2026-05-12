-- Migration: switch entry storage from per-mantra rows to per-API-call
-- summary rows. Anti-cheat was removed (devotional practice, no need
-- to enforce server-side). One row per writing-session POST instead
-- of N rows.

DROP TABLE IF EXISTS "likhita"."entries" CASCADE;
DROP TABLE IF EXISTS "likhita"."shared_entries" CASCADE;

CREATE TABLE "likhita"."entry_batches" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "koti_id" uuid NOT NULL REFERENCES "likhita"."kotis"("id") ON DELETE CASCADE,
  "start_sequence" bigint NOT NULL,
  "end_sequence" bigint NOT NULL,
  "count" integer NOT NULL,
  "client_session_id" uuid,
  "committed_first_at" timestamp with time zone NOT NULL,
  "committed_last_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX "entry_batches_koti_start" ON "likhita"."entry_batches"("koti_id","start_sequence");
ALTER TABLE "likhita"."entry_batches"
  ADD CONSTRAINT "entry_batches_koti_start_unique" UNIQUE("koti_id","start_sequence");

CREATE TABLE "likhita"."shared_entry_batches" (
  "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  "shared_koti_id" uuid NOT NULL REFERENCES "likhita"."shared_kotis"("id") ON DELETE CASCADE,
  "device_id" text NOT NULL,
  "display_name" text,
  "place" text,
  "country" text,
  "count" integer NOT NULL,
  "committed_first_at" timestamp with time zone NOT NULL,
  "committed_last_at" timestamp with time zone NOT NULL,
  "created_at" timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX "shared_entry_batches_koti_ts" ON "likhita"."shared_entry_batches"("shared_koti_id","committed_last_at");
CREATE INDEX "shared_entry_batches_device" ON "likhita"."shared_entry_batches"("device_id");
CREATE INDEX "shared_entry_batches_country" ON "likhita"."shared_entry_batches"("shared_koti_id","country");
