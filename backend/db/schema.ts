import {
  pgSchema,
  uuid,
  text,
  bigint,
  boolean,
  timestamp,
  jsonb,
  integer,
  index,
  unique,
  primaryKey,
} from "drizzle-orm/pg-core";

// All Likhita tables live in a dedicated Postgres schema. This isolates them
// from any other project that happens to share the same Neon database
// (specifically: chain911 owns the `public` schema in the shared instance).
// `pgSchema("likhita")` makes every table reference resolve to `likhita.<name>`
// without sprinkling the namespace through every query.
export const likhitaSchema = pgSchema("likhita");
const pgTable = likhitaSchema.table.bind(likhitaSchema);

// X-App-Origin values used across tables. Kept as TEXT in DB to allow future apps
// without a schema migration; validated at the route layer with Zod.
export const APP_ORIGINS = ["rama_koti", "ram_naam_lekhan"] as const;
export type AppOrigin = (typeof APP_ORIGINS)[number];

export const TEMPLE_DESTINATIONS = [
  "bhadrachalam",
  "ram_naam_bank",
  "ayodhya",
] as const;
export type TempleDestination = (typeof TEMPLE_DESTINATIONS)[number];

export const PAYMENT_PROVIDERS = ["stripe", "razorpay", "apple_iap"] as const;
export type PaymentProvider = (typeof PAYMENT_PROVIDERS)[number];

export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  clerkId: text("clerk_id").notNull().unique(),
  name: text("name").notNull(),
  gotra: text("gotra"),
  nativePlace: text("native_place"),
  email: text("email").notNull(),
  phone: text("phone"),
  uiLanguage: text("ui_language"),
  primaryApp: text("primary_app"),
  linkedApps: text("linked_apps").array(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const kotis = pgTable(
  "kotis",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    appOrigin: text("app_origin").notNull(),
    traditionPath: text("tradition_path").notNull(),
    mantraString: text("mantra_string").notNull(),
    renderedScript: text("rendered_script").notNull(),
    inputMode: text("input_mode").notNull().default("romanized"),
    mode: text("mode").notNull(),
    targetCount: bigint("target_count", { mode: "number" }).notNull(),
    currentCount: bigint("current_count", { mode: "number" }).notNull().default(0),
    stylusColor: text("stylus_color"),
    stylusSignatureHash: text("stylus_signature_hash"),
    theme: text("theme"),
    dedicationText: text("dedication_text"),
    dedicationTo: text("dedication_to"),
    startedAt: timestamp("started_at", { withTimezone: true }).notNull().defaultNow(),
    completedAt: timestamp("completed_at", { withTimezone: true }),
    locked: boolean("locked").notNull().default(true),
    shipTemple: boolean("ship_temple").notNull().default(false),
    templeDestination: text("temple_destination"),
    shipHome: boolean("ship_home").notNull().default(false),
    shippingAddress: jsonb("shipping_address"),
    paymentId: text("payment_id"),
    printedAt: timestamp("printed_at", { withTimezone: true }),
    shippedAt: timestamp("shipped_at", { withTimezone: true }),
    deliveredAt: timestamp("delivered_at", { withTimezone: true }),
    photoUrl: text("photo_url"),
    receiptUrl: text("receipt_url"),
    // Pace screen — user-picked completion horizon and notification slots.
    // goalDays defaults to a year; reminderTimes is an array of slot ids
    // chosen from {brahma, pratah, madhyana, sandhya} — at most 3.
    goalDays: integer("goal_days").notNull().default(365),
    reminderTimes: jsonb("reminder_times").notNull().default(["pratah", "sandhya"] as unknown as object),
  },
  (t) => ({
    userIdx: index("kotis_user").on(t.userId),
  }),
);

// Batched entry storage. One row per API POST. Each row is a *summary*
// of all the mantras typed in that batch — count + sequence range + time
// range — not a JSONB blob of per-mantra records. Anti-cheat was dropped
// because the practice is voluntary and devotional (the user noted: "it's
// the god who is going to enforce it"), so we no longer need cadence
// fingerprints or per-entry rows. Storage: ~80 bytes/row, ~200 rows for
// a Lakh koti.
//
// `start_sequence`..`end_sequence` is inclusive. The UNIQUE constraint
// on (koti_id, start_sequence) keeps batch heads distinct; the route
// handler enforces continuity (the next batch's start must equal the
// koti's current_count + 1).
export const entryBatches = pgTable(
  "entry_batches",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    kotiId: uuid("koti_id")
      .notNull()
      .references(() => kotis.id, { onDelete: "cascade" }),
    startSequence: bigint("start_sequence", { mode: "number" }).notNull(),
    endSequence: bigint("end_sequence", { mode: "number" }).notNull(),
    count: integer("count").notNull(),
    clientSessionId: uuid("client_session_id"),
    committedFirstAt: timestamp("committed_first_at", { withTimezone: true }).notNull(),
    committedLastAt: timestamp("committed_last_at", { withTimezone: true }).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => ({
    kotiStart: index("entry_batches_koti_start").on(t.kotiId, t.startSequence),
    uniqueStart: unique("entry_batches_koti_start_unique").on(t.kotiId, t.startSequence),
  }),
);

// Idempotency keys are scoped per koti to keep the index small. We store the
// SHA-256 of the request body so duplicate retries with mutated bodies are
// rejected rather than silently merged.
export const idempotencyKeys = pgTable(
  "idempotency_keys",
  {
    kotiId: uuid("koti_id")
      .notNull()
      .references(() => kotis.id, { onDelete: "cascade" }),
    key: text("key").notNull(),
    requestHash: text("request_hash").notNull(),
    responseJson: jsonb("response_json").notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => ({
    pk: primaryKey({ columns: [t.kotiId, t.key] }),
  }),
);

export const shipBatches = pgTable("ship_batches", {
  id: uuid("id").primaryKey().defaultRandom(),
  batchQuarter: text("batch_quarter").notNull(),
  templeDestination: text("temple_destination").notNull(),
  status: text("status").notNull().default("pending"),
  representativeId: uuid("representative_id"),
  tripStartedAt: timestamp("trip_started_at", { withTimezone: true }),
  tripCompletedAt: timestamp("trip_completed_at", { withTimezone: true }),
  photosUrl: text("photos_url"),
  receiptUrl: text("receipt_url"),
});

export const kotiShipBatches = pgTable(
  "koti_ship_batches",
  {
    kotiId: uuid("koti_id")
      .notNull()
      .references(() => kotis.id, { onDelete: "cascade" }),
    batchId: uuid("batch_id")
      .notNull()
      .references(() => shipBatches.id, { onDelete: "cascade" }),
    positionInBatch: integer("position_in_batch"),
    individualPhotoUrl: text("individual_photo_url"),
    individualReceiptUrl: text("individual_receipt_url"),
  },
  (t) => ({
    pk: primaryKey({ columns: [t.kotiId, t.batchId] }),
  }),
);

export const payments = pgTable("payments", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  kotiId: uuid("koti_id").references(() => kotis.id, { onDelete: "set null" }),
  provider: text("provider").notNull(),
  providerId: text("provider_id").notNull(),
  amountCents: integer("amount_cents").notNull(),
  currency: text("currency").notNull(),
  type: text("type").notNull(),
  status: text("status").notNull().default("pending"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

export const devices = pgTable("devices", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  apnsToken: text("apns_token").notNull(),
  appOrigin: text("app_origin").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

// ─────────────────────────────────────────────────────────────────────────────
// The Sangha — communal Foundation Koti shared across all devotees.
// Append-only, no per-user ownership, 1-crore ceiling. One row in
// `shared_kotis`; every devotee's mantra appends to `shared_entries`.
// Aggregates (top writers, country breakdown) are computed by GROUP BY at
// read time — small enough volume that materialized views are overkill.
// ─────────────────────────────────────────────────────────────────────────────

export const sharedKotis = pgTable("shared_kotis", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  nameLocal: text("name_local").notNull(),
  targetCount: bigint("target_count", { mode: "number" }).notNull(),
  currentCount: bigint("current_count", { mode: "number" }).notNull().default(0),
  custodian: text("custodian").notNull(),
  destination: text("destination").notNull(),
  estimatedShipDate: text("estimated_ship_date").notNull(),
  startedAt: timestamp("started_at", { withTimezone: true }).notNull().defaultNow(),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

// Sangha equivalent of entry_batches. One row per API POST. Summary
// only — no per-mantra JSONB, no cadence fingerprint. Includes the
// device/identity fields required for the Sangha hub's writer ticker
// and country breakdown.
export const sharedEntryBatches = pgTable(
  "shared_entry_batches",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    sharedKotiId: uuid("shared_koti_id")
      .notNull()
      .references(() => sharedKotis.id, { onDelete: "cascade" }),
    // Stable per-device identifier — used to compute unique-writer count
    // without requiring authentication. iOS sends KotiStore.stableUserId().
    deviceId: text("device_id").notNull(),
    // Display name + place are optional and per-batch (the user may
    // change them between writing sessions). If both blank we render
    // the contribution as "Anonymous".
    displayName: text("display_name"),
    place: text("place"),
    country: text("country"),
    count: integer("count").notNull(),
    committedFirstAt: timestamp("committed_first_at", { withTimezone: true }).notNull(),
    committedLastAt: timestamp("committed_last_at", { withTimezone: true }).notNull(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => ({
    kotiTs: index("shared_entry_batches_koti_ts").on(t.sharedKotiId, t.committedLastAt),
    deviceIdx: index("shared_entry_batches_device").on(t.deviceId),
    countryIdx: index("shared_entry_batches_country").on(t.sharedKotiId, t.country),
  }),
);

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Koti = typeof kotis.$inferSelect;
export type NewKoti = typeof kotis.$inferInsert;
export type EntryBatch = typeof entryBatches.$inferSelect;
export type NewEntryBatch = typeof entryBatches.$inferInsert;
export type Payment = typeof payments.$inferSelect;
export type ShipBatch = typeof shipBatches.$inferSelect;
export type Device = typeof devices.$inferSelect;
export type SharedKoti = typeof sharedKotis.$inferSelect;
export type NewSharedKoti = typeof sharedKotis.$inferInsert;
export type SharedEntryBatch = typeof sharedEntryBatches.$inferSelect;
export type NewSharedEntryBatch = typeof sharedEntryBatches.$inferInsert;
