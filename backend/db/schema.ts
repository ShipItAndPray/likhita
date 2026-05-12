import {
  pgSchema,
  uuid,
  text,
  bigint,
  boolean,
  timestamp,
  date,
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

// One row per (koti, local-date). UPSERT-style write: the route handler
// adds the incoming batch's `count` to whatever already exists for that
// day, atomically. Replaces the previous `entry_batches` design (one
// row per API POST) because at the 1000-user target it produces ~5x
// more rows than necessary. With this design:
//   - Lakh user: ~200 rows (one per active day)
//   - Crore user: ~3,650 rows (one per active day)
//   - Calendar query is a primary-key range scan, no GROUP BY.
//   - Timezone is owned by the client — `date` is a DATE column stored
//     in whatever local calendar the user is writing under, set at
//     write time. No `AT TIME ZONE` math at read time.
export const dailyCounts = pgTable(
  "daily_counts",
  {
    kotiId: uuid("koti_id")
      .notNull()
      .references(() => kotis.id, { onDelete: "cascade" }),
    date: date("date").notNull(),
    count: integer("count").notNull(),
    firstSeq: bigint("first_seq", { mode: "number" }).notNull(),
    lastSeq: bigint("last_seq", { mode: "number" }).notNull(),
    clientSessionId: uuid("client_session_id"),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => ({
    pk: primaryKey({ columns: [t.kotiId, t.date] }),
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

// Sangha equivalent of `daily_counts`. One row per
// (shared_koti, device, local-date). Display fields (name, place,
// country) are denormalized so the hub's writer ticker + country tile
// don't need to join anything. Row count for 1000 active devotees
// writing daily for a year: 365,000 rows, ~30 MB.
export const sharedDailyCounts = pgTable(
  "shared_daily_counts",
  {
    sharedKotiId: uuid("shared_koti_id")
      .notNull()
      .references(() => sharedKotis.id, { onDelete: "cascade" }),
    deviceId: text("device_id").notNull(),
    date: date("date").notNull(),
    count: integer("count").notNull(),
    displayName: text("display_name"),
    place: text("place"),
    country: text("country"),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (t) => ({
    pk: primaryKey({ columns: [t.sharedKotiId, t.deviceId, t.date] }),
    kotiUpdated: index("shared_daily_counts_koti_updated").on(t.sharedKotiId, t.updatedAt),
    countryIdx: index("shared_daily_counts_country").on(t.sharedKotiId, t.country),
  }),
);

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Koti = typeof kotis.$inferSelect;
export type NewKoti = typeof kotis.$inferInsert;
export type DailyCount = typeof dailyCounts.$inferSelect;
export type NewDailyCount = typeof dailyCounts.$inferInsert;
export type Payment = typeof payments.$inferSelect;
export type ShipBatch = typeof shipBatches.$inferSelect;
export type Device = typeof devices.$inferSelect;
export type SharedKoti = typeof sharedKotis.$inferSelect;
export type NewSharedKoti = typeof sharedKotis.$inferInsert;
export type SharedDailyCount = typeof sharedDailyCounts.$inferSelect;
export type NewSharedDailyCount = typeof sharedDailyCounts.$inferInsert;
