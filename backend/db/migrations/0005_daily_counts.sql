-- Replace entry_batches / shared_entry_batches with daily_counts /
-- shared_daily_counts. Per-(koti, date) and per-(koti, device, date)
-- UPSERT rows instead of one row per API POST. At 1000-user scale this
-- is ~5x fewer rows and the Pace calendar becomes a primary-key scan
-- instead of a GROUP BY.

DROP TABLE IF EXISTS "likhita"."entry_batches" CASCADE;
DROP TABLE IF EXISTS "likhita"."shared_entry_batches" CASCADE;

CREATE TABLE "likhita"."daily_counts" (
  "koti_id"           uuid NOT NULL REFERENCES "likhita"."kotis"("id") ON DELETE CASCADE,
  "date"              date NOT NULL,
  "count"             integer NOT NULL,
  "first_seq"         bigint NOT NULL,
  "last_seq"          bigint NOT NULL,
  "client_session_id" uuid,
  "updated_at"        timestamp with time zone NOT NULL DEFAULT NOW(),
  PRIMARY KEY ("koti_id", "date")
);

CREATE TABLE "likhita"."shared_daily_counts" (
  "shared_koti_id" uuid NOT NULL REFERENCES "likhita"."shared_kotis"("id") ON DELETE CASCADE,
  "device_id"      text NOT NULL,
  "date"           date NOT NULL,
  "count"          integer NOT NULL,
  "display_name"   text,
  "place"          text,
  "country"        text,
  "updated_at"     timestamp with time zone NOT NULL DEFAULT NOW(),
  PRIMARY KEY ("shared_koti_id", "device_id", "date")
);

CREATE INDEX "shared_daily_counts_koti_updated"
  ON "likhita"."shared_daily_counts"("shared_koti_id", "updated_at" DESC);

CREATE INDEX "shared_daily_counts_country"
  ON "likhita"."shared_daily_counts"("shared_koti_id", "country");
