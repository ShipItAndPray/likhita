import {
  pgTable,
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
  },
  (t) => ({
    userIdx: index("kotis_user").on(t.userId),
  }),
);

export const entries = pgTable(
  "entries",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    kotiId: uuid("koti_id")
      .notNull()
      .references(() => kotis.id, { onDelete: "cascade" }),
    sequenceNumber: bigint("sequence_number", { mode: "number" }).notNull(),
    committedAt: timestamp("committed_at", { withTimezone: true }).notNull(),
    cadenceSignature: text("cadence_signature").notNull(),
    clientSessionId: uuid("client_session_id"),
    flagged: boolean("flagged").notNull().default(false),
  },
  (t) => ({
    kotiSeq: index("entries_koti_seq").on(t.kotiId, t.sequenceNumber),
    uniqueSeq: unique("entries_unique_seq").on(t.kotiId, t.sequenceNumber),
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

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Koti = typeof kotis.$inferSelect;
export type NewKoti = typeof kotis.$inferInsert;
export type Entry = typeof entries.$inferSelect;
export type NewEntry = typeof entries.$inferInsert;
export type Payment = typeof payments.$inferSelect;
export type ShipBatch = typeof shipBatches.$inferSelect;
export type Device = typeof devices.$inferSelect;
