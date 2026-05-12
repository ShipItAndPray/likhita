-- Pace screen support.
-- - goal_days: user-chosen completion horizon (30..730), drives the
--   daily target calculation on the writing surface.
-- - reminder_times: subset of {brahma, pratah, madhyana, sandhya}.
--   Stored as JSONB array; client enforces "at most 3".

ALTER TABLE "likhita"."kotis"
  ADD COLUMN IF NOT EXISTS "goal_days" integer NOT NULL DEFAULT 365;

ALTER TABLE "likhita"."kotis"
  ADD COLUMN IF NOT EXISTS "reminder_times" jsonb NOT NULL DEFAULT '["pratah", "sandhya"]'::jsonb;
