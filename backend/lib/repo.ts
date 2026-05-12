// Repository seam between route handlers and storage.
//
// Two implementations:
//   - Drizzle/Neon — used in dev + production.
//   - In-memory stub — used in `LIKHITA_RUNTIME=test` so existing route tests
//     don't need a live Postgres.
//
// Routes never import drizzle directly. They call functions from this module,
// which dispatches to one of the two backends based on the environment.

import { eq, and, sql, desc, gt } from "drizzle-orm";
import { getDb, schema } from "@/db/client";
import type { AppOrigin } from "@/db/schema";

// ─────────────────────────────────────────────────────────────────────────────
// Public types
// ─────────────────────────────────────────────────────────────────────────────

export type UpsertUserInput = {
  clerkId: string;
  name: string;
  email: string;
  gotra?: string;
  nativePlace?: string;
  phone?: string;
  uiLanguage?: string;
  appOrigin: AppOrigin;
};

export type UserRow = {
  id: string;
  clerkId: string;
  name: string;
  email: string;
  primaryApp: string | null;
  linkedApps: string[];
};

export type CreateKotiInput = {
  userId: string;
  appOrigin: AppOrigin;
  traditionPath: string;
  mantraString: string;
  renderedScript: string;
  mode: string;
  targetCount: number;
  stylusColor: string;
  stylusSignatureHash: string;
  theme: string;
  dedicationText: string;
  dedicationTo: string;
};

export type KotiRow = {
  id: string;
  userId: string;
  appOrigin: string;
  traditionPath: string;
  mantraString: string;
  renderedScript: string;
  mode: string;
  targetCount: number;
  currentCount: number;
  stylusColor: string | null;
  stylusSignatureHash: string | null;
  theme: string | null;
  dedicationText: string | null;
  dedicationTo: string | null;
  startedAt: string;
  completedAt: string | null;
  locked: boolean;
  // Pace screen — user-chosen completion horizon + notification slots.
  // reminderTimes is a JSONB array of ids: subset of
  // {brahma, pratah, madhyana, sandhya}, at most 3 enforced client-side.
  goalDays: number;
  reminderTimes: string[];
  // Legacy anti-cheat baselines — anti-cheat was removed, kept on the
  // type as null for backward compat with code that reads them.
  baselineCadenceMs: number | null;
  baselineVarianceMs: number | null;
};

/// One day's mantra contribution to a koti. Used by the Pace screen's
/// calendar — `committed_first_at` truncated to a day, with the count
/// SUM'd across batches that landed on that day.
export type DailyCount = {
  /// ISO date `YYYY-MM-DD` in UTC.
  date: string;
  count: number;
};

// One write batch as it arrives from iOS. `date` is the user's local
// calendar date (YYYY-MM-DD); the server UPSERTs into daily_counts so
// multiple writing sessions on the same day collapse into one row.
export type EntryBatchInsert = {
  startSequence: number;
  endSequence: number;
  count: number;
  clientSessionId: string;
  date: string;   // YYYY-MM-DD, local
};

// ─────────────────────────────────────────────────────────────────────────────
// Dispatch
// ─────────────────────────────────────────────────────────────────────────────

function isTest(): boolean {
  return process.env.LIKHITA_RUNTIME === "test";
}

// ─────────────────────────────────────────────────────────────────────────────
// In-memory store (test-only)
// ─────────────────────────────────────────────────────────────────────────────

type Mem = {
  users: Map<string, UserRow & { gotra?: string; nativePlace?: string; phone?: string; uiLanguage?: string }>;
  kotis: Map<string, KotiRow>;
  /// koti id → (date → count). Mirrors the daily_counts table for tests.
  dailyCounts: Map<string, Map<string, number>>;
  idem: Map<string, { hash: string; response: unknown }>; // key = `${kotiId}:${idemKey}`
};

function memStore(): Mem {
  const g = globalThis as unknown as { __likhitaMem?: Mem };
  if (!g.__likhitaMem) {
    g.__likhitaMem = {
      users: new Map(),
      kotis: new Map(),
      dailyCounts: new Map(),
      idem: new Map(),
    };
  }
  return g.__likhitaMem;
}

// ─────────────────────────────────────────────────────────────────────────────
// Users
// ─────────────────────────────────────────────────────────────────────────────

export async function upsertUser(input: UpsertUserInput): Promise<UserRow> {
  if (isTest()) {
    const mem = memStore();
    const existing = Array.from(mem.users.values()).find((u) => u.clerkId === input.clerkId);
    if (existing) {
      existing.name = input.name;
      existing.email = input.email;
      existing.gotra = input.gotra;
      existing.nativePlace = input.nativePlace;
      existing.phone = input.phone;
      existing.uiLanguage = input.uiLanguage;
      if (existing.primaryApp == null) existing.primaryApp = input.appOrigin;
      if (!existing.linkedApps.includes(input.appOrigin)) {
        existing.linkedApps.push(input.appOrigin);
      }
      return existing;
    }
    const row: UserRow = {
      id: input.clerkId, // identity in test mode
      clerkId: input.clerkId,
      name: input.name,
      email: input.email,
      primaryApp: input.appOrigin,
      linkedApps: [input.appOrigin],
    };
    mem.users.set(row.id, { ...row, gotra: input.gotra, nativePlace: input.nativePlace, phone: input.phone, uiLanguage: input.uiLanguage });
    return row;
  }

  const db = getDb();
  // Insert if missing, else update mutable fields and append app to linked_apps.
  const existing = await db
    .select()
    .from(schema.users)
    .where(eq(schema.users.clerkId, input.clerkId))
    .limit(1);

  if (existing.length === 0) {
    const inserted = await db
      .insert(schema.users)
      .values({
        clerkId: input.clerkId,
        name: input.name,
        email: input.email,
        gotra: input.gotra,
        nativePlace: input.nativePlace,
        phone: input.phone,
        uiLanguage: input.uiLanguage,
        primaryApp: input.appOrigin,
        linkedApps: [input.appOrigin],
      })
      .returning();
    const row = inserted[0];
    if (!row) throw new Error("upsertUser: insert returned no rows");
    return {
      id: row.id,
      clerkId: row.clerkId,
      name: row.name,
      email: row.email,
      primaryApp: row.primaryApp,
      linkedApps: row.linkedApps ?? [],
    };
  }

  const current = existing[0];
  if (!current) throw new Error("upsertUser: existing lookup returned no rows");
  const linked = new Set(current.linkedApps ?? []);
  linked.add(input.appOrigin);
  await db
    .update(schema.users)
    .set({
      name: input.name,
      email: input.email,
      gotra: input.gotra,
      nativePlace: input.nativePlace,
      phone: input.phone,
      uiLanguage: input.uiLanguage,
      primaryApp: current.primaryApp ?? input.appOrigin,
      linkedApps: Array.from(linked),
    })
    .where(eq(schema.users.id, current.id));

  return {
    id: current.id,
    clerkId: current.clerkId,
    name: input.name,
    email: input.email,
    primaryApp: current.primaryApp ?? input.appOrigin,
    linkedApps: Array.from(linked),
  };
}

export async function findUserByClerkId(clerkId: string): Promise<UserRow | null> {
  if (isTest()) {
    const mem = memStore();
    const u = Array.from(mem.users.values()).find((x) => x.clerkId === clerkId);
    if (!u) return null;
    return {
      id: u.id, clerkId: u.clerkId, name: u.name, email: u.email,
      primaryApp: u.primaryApp, linkedApps: u.linkedApps,
    };
  }
  const db = getDb();
  const rows = await db
    .select()
    .from(schema.users)
    .where(eq(schema.users.clerkId, clerkId))
    .limit(1);
  const r = rows[0];
  if (!r) return null;
  return {
    id: r.id, clerkId: r.clerkId, name: r.name, email: r.email,
    primaryApp: r.primaryApp, linkedApps: r.linkedApps ?? [],
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Kotis
// ─────────────────────────────────────────────────────────────────────────────

function kotiRowFromDb(r: typeof schema.kotis.$inferSelect): KotiRow {
  return {
    id: r.id,
    userId: r.userId,
    appOrigin: r.appOrigin,
    traditionPath: r.traditionPath,
    mantraString: r.mantraString,
    renderedScript: r.renderedScript,
    mode: r.mode,
    targetCount: Number(r.targetCount),
    currentCount: Number(r.currentCount),
    stylusColor: r.stylusColor,
    stylusSignatureHash: r.stylusSignatureHash,
    theme: r.theme,
    dedicationText: r.dedicationText,
    dedicationTo: r.dedicationTo,
    startedAt: r.startedAt instanceof Date ? r.startedAt.toISOString() : String(r.startedAt),
    completedAt: r.completedAt instanceof Date ? r.completedAt.toISOString() : (r.completedAt ?? null) as string | null,
    locked: r.locked,
    goalDays: r.goalDays ?? 365,
    reminderTimes: Array.isArray(r.reminderTimes) ? (r.reminderTimes as string[]) : ["pratah", "sandhya"],
    baselineCadenceMs: null,
    baselineVarianceMs: null,
  };
}

export async function createKoti(input: CreateKotiInput): Promise<KotiRow> {
  if (isTest()) {
    const mem = memStore();
    const id = crypto.randomUUID();
    const row: KotiRow = {
      id,
      userId: input.userId,
      appOrigin: input.appOrigin,
      traditionPath: input.traditionPath,
      mantraString: input.mantraString,
      renderedScript: input.renderedScript,
      mode: input.mode,
      targetCount: input.targetCount,
      currentCount: 0,
      stylusColor: input.stylusColor,
      stylusSignatureHash: input.stylusSignatureHash,
      theme: input.theme,
      dedicationText: input.dedicationText,
      dedicationTo: input.dedicationTo,
      startedAt: new Date().toISOString(),
      completedAt: null,
      locked: true,
      goalDays: 365,
      reminderTimes: ["pratah", "sandhya"],
      baselineCadenceMs: null,
      baselineVarianceMs: null,
    };
    mem.kotis.set(id, row);
    mem.dailyCounts.set(id, new Map());
    return row;
  }

  const db = getDb();
  const inserted = await db
    .insert(schema.kotis)
    .values({
      userId: input.userId,
      appOrigin: input.appOrigin,
      traditionPath: input.traditionPath,
      mantraString: input.mantraString,
      renderedScript: input.renderedScript,
      mode: input.mode,
      targetCount: input.targetCount,
      currentCount: 0,
      stylusColor: input.stylusColor,
      stylusSignatureHash: input.stylusSignatureHash,
      theme: input.theme,
      dedicationText: input.dedicationText,
      dedicationTo: input.dedicationTo,
    })
    .returning();
  const row = inserted[0];
  if (!row) throw new Error("createKoti: insert returned no rows");
  return kotiRowFromDb(row);
}

export async function listKotisForUser(userId: string, appOrigin: AppOrigin): Promise<KotiRow[]> {
  if (isTest()) {
    return Array.from(memStore().kotis.values())
      .filter((k) => k.userId === userId && k.appOrigin === appOrigin);
  }
  const db = getDb();
  const rows = await db
    .select()
    .from(schema.kotis)
    .where(and(eq(schema.kotis.userId, userId), eq(schema.kotis.appOrigin, appOrigin)))
    .orderBy(desc(schema.kotis.startedAt));
  return rows.map(kotiRowFromDb);
}

export async function getKotiById(id: string): Promise<KotiRow | null> {
  if (isTest()) {
    return memStore().kotis.get(id) ?? null;
  }
  const db = getDb();
  const rows = await db.select().from(schema.kotis).where(eq(schema.kotis.id, id)).limit(1);
  const r = rows[0];
  if (!r) return null;
  return kotiRowFromDb(r);
}

/// Per-day mantra totals for the Pace screen's calendar. Aggregates the
/// `entry_batches.count` column by the UTC date of `committed_first_at`
/// (a batch never spans more than one writing session, so first ≈ last
/// in practice — using `first` is enough). `days` caps the window; the
/// design currently asks for 180.
/// Per-day mantra totals for the Pace screen. Reads directly from
/// `daily_counts` — no GROUP BY at query time, no aggregation. The
/// daily row is the source of truth (UPSERT'd at write time), so the
/// calendar is always a primary-key range scan.
export async function getDailyCounts(kotiId: string, days: number): Promise<DailyCount[]> {
  if (isTest()) {
    const rows = memStore().dailyCounts.get(kotiId) ?? new Map<string, number>();
    return Array.from(rows.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }
  const db = getDb();
  const rows = await db.execute(sql`
    SELECT to_char(date, 'YYYY-MM-DD') AS date, count
    FROM likhita.daily_counts
    WHERE koti_id = ${kotiId}
      AND date >= (CURRENT_DATE - (${days} || ' days')::interval)
    ORDER BY date
  `);
  type Row = { date: string; count: number };
  const out = (rows.rows ?? rows) as unknown as Row[];
  return out.map((r) => ({ date: r.date, count: Number(r.count) }));
}

/// Partial-update the Pace fields on a koti. Both fields are independently
/// optional; pass undefined for the ones you don't want to touch. Returns
/// the post-update row (or null if the koti doesn't exist).
export async function updateKotiPace(
  id: string,
  patch: { goalDays?: number; reminderTimes?: string[] },
): Promise<KotiRow | null> {
  if (isTest()) {
    const mem = memStore();
    const k = mem.kotis.get(id);
    if (!k) return null;
    if (patch.goalDays !== undefined) k.goalDays = patch.goalDays;
    if (patch.reminderTimes !== undefined) k.reminderTimes = patch.reminderTimes;
    return k;
  }
  const db = getDb();
  const set: Record<string, unknown> = {};
  if (patch.goalDays !== undefined) set.goalDays = patch.goalDays;
  if (patch.reminderTimes !== undefined) set.reminderTimes = patch.reminderTimes;
  if (Object.keys(set).length === 0) {
    return getKotiById(id);
  }
  const updated = await db.update(schema.kotis).set(set).where(eq(schema.kotis.id, id)).returning();
  const r = updated[0];
  if (!r) return null;
  return kotiRowFromDb(r);
}

// ─────────────────────────────────────────────────────────────────────────────
// Idempotency
// ─────────────────────────────────────────────────────────────────────────────

export type IdempotencyHit = {
  hash: string;
  response: unknown;
};

export async function lookupIdempotency(kotiId: string, key: string): Promise<IdempotencyHit | null> {
  if (isTest()) {
    return memStore().idem.get(`${kotiId}:${key}`) ?? null;
  }
  const db = getDb();
  const rows = await db
    .select()
    .from(schema.idempotencyKeys)
    .where(and(eq(schema.idempotencyKeys.kotiId, kotiId), eq(schema.idempotencyKeys.key, key)))
    .limit(1);
  const r = rows[0];
  if (!r) return null;
  return { hash: r.requestHash, response: r.responseJson };
}

export async function storeIdempotency(
  kotiId: string,
  key: string,
  hash: string,
  response: unknown,
): Promise<void> {
  if (isTest()) {
    memStore().idem.set(`${kotiId}:${key}`, { hash, response });
    return;
  }
  const db = getDb();
  await db.insert(schema.idempotencyKeys).values({
    kotiId,
    key,
    requestHash: hash,
    responseJson: response,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry batches — one row per API POST, summary only
// ─────────────────────────────────────────────────────────────────────────────

export type CommitBatchInput = {
  kotiId: string;
  expectedCurrentCount: number;
  newCount: number;
  batch: EntryBatchInsert;
};

export type CommitBatchResult = { ok: true; currentCount: number } | { ok: false; reason: "concurrent_update" };

/// Compare-and-swap commit. UPDATE kotis matches on `current_count = expected`
/// so concurrent submissions cannot double-count or move backwards. On success
/// inserts ONE batch row summarizing the write (count + sequence range +
/// time range). Anti-cheat / cadence storage was removed — devotion is
/// voluntary.
export async function commitBatch(input: CommitBatchInput): Promise<CommitBatchResult> {
  if (isTest()) {
    const mem = memStore();
    const k = mem.kotis.get(input.kotiId);
    if (!k) return { ok: false, reason: "concurrent_update" };
    if (k.currentCount !== input.expectedCurrentCount) {
      return { ok: false, reason: "concurrent_update" };
    }
    k.currentCount = input.newCount;
    if (k.currentCount >= k.targetCount && !k.completedAt) {
      k.completedAt = new Date().toISOString();
    }
    const byDay = mem.dailyCounts.get(input.kotiId) ?? new Map<string, number>();
    byDay.set(input.batch.date, (byDay.get(input.batch.date) ?? 0) + input.batch.count);
    mem.dailyCounts.set(input.kotiId, byDay);
    return { ok: true, currentCount: k.currentCount };
  }

  const db = getDb();
  // CAS update — returns the row only if expected count matched.
  const updated = await db
    .update(schema.kotis)
    .set({
      currentCount: input.newCount,
      completedAt: sql`CASE WHEN ${input.newCount} >= target_count AND completed_at IS NULL THEN NOW() ELSE completed_at END`,
    })
    .where(
      and(
        eq(schema.kotis.id, input.kotiId),
        eq(schema.kotis.currentCount, input.expectedCurrentCount),
      ),
    )
    .returning({ currentCount: schema.kotis.currentCount });

  const updatedRow = updated[0];
  if (!updatedRow) {
    return { ok: false, reason: "concurrent_update" };
  }

  // UPSERT into daily_counts. Multiple writing sessions on the same local
  // day collapse into one row, so a Lakh user has ~200 rows total
  // (one per active day) instead of one per POST.
  await db.execute(sql`
    INSERT INTO likhita.daily_counts
      (koti_id, date, count, first_seq, last_seq, client_session_id, updated_at)
    VALUES
      (${input.kotiId}, ${input.batch.date}, ${input.batch.count},
       ${input.batch.startSequence}, ${input.batch.endSequence},
       ${input.batch.clientSessionId}, NOW())
    ON CONFLICT (koti_id, date) DO UPDATE
      SET count = likhita.daily_counts.count + EXCLUDED.count,
          last_seq = EXCLUDED.last_seq,
          updated_at = NOW()
  `);

  return { ok: true, currentCount: Number(updatedRow.currentCount) };
}

// ─────────────────────────────────────────────────────────────────────────────
// The Sangha — Foundation Koti reads + appends.
// One row, no per-user ownership, no sequence enforcement, 1 crore ceiling.
// ─────────────────────────────────────────────────────────────────────────────

export type SharedKotiRow = {
  id: string;
  name: string;
  nameLocal: string;
  targetCount: number;
  currentCount: number;
  custodian: string;
  destination: string;
  estimatedShipDate: string;
  startedAt: string;
};

export type SharedHubSnapshot = {
  koti: SharedKotiRow;
  uniqueWriters: number;
  countriesActive: number;
  recentWriters: { name: string; place: string; count: number; ago: string; committedAt: string }[];
  topWriters: { name: string; count: number; joined: string }[];
  countries: { country: string; count: number }[];
};

export type SharedAppendInput = {
  deviceId: string;
  displayName: string | null;
  place: string | null;
  country: string | null;
  count: number;
  /// User's local date for this batch (YYYY-MM-DD). The row is UPSERT'd
  /// into shared_daily_counts keyed on (shared_koti_id, device_id, date)
  /// so multiple sessions on the same day collapse.
  date: string;
};

export type SharedAppendResult = {
  acceptedHere: number;
  currentCount: number;
  remaining: number;
  complete: boolean;
};

function rowToSharedKoti(r: typeof schema.sharedKotis.$inferSelect): SharedKotiRow {
  return {
    id: r.id,
    name: r.name,
    nameLocal: r.nameLocal,
    targetCount: Number(r.targetCount),
    currentCount: Number(r.currentCount),
    custodian: r.custodian,
    destination: r.destination,
    estimatedShipDate: r.estimatedShipDate,
    startedAt: r.startedAt instanceof Date ? r.startedAt.toISOString() : String(r.startedAt),
  };
}

const TEST_SHARED_KOTI_ID = "feedface-cafe-babe-0042-deadbeefcafe";

/// Returns the single active foundation koti row. Throws if none seeded.
export async function getActiveSharedKoti(): Promise<SharedKotiRow> {
  if (isTest()) {
    const mem = sharedMemStore();
    if (!mem.koti) {
      mem.koti = {
        id: TEST_SHARED_KOTI_ID,
        name: "The Foundation Koti",
        nameLocal: "సర్వజన రామ కోటి",
        targetCount: 10_000_000,
        currentCount: 0,
        custodian: "Likhita Foundation",
        destination: "Sri Sita Ramachandra Swamy Temple, Bhadrachalam",
        estimatedShipDate: "Vaikuntha Ekadashi · Dec 31, 2026",
        startedAt: new Date("2026-01-14T00:00:00Z").toISOString(),
      };
    }
    return { ...mem.koti };
  }
  const db = getDb();
  const rows = await db.select().from(schema.sharedKotis).limit(1);
  const r = rows[0];
  if (!r) throw new Error("No shared koti seeded. Run the seed script.");
  return rowToSharedKoti(r);
}

/// Pull a full hub snapshot: koti row + aggregated stats (unique writers,
/// countries active, recent ticker, top contributors, country breakdown).
/// All aggregations live in single round-trip parallel queries against the
/// shared_entries table.
export async function getSharedHubSnapshot(): Promise<SharedHubSnapshot> {
  const koti = await getActiveSharedKoti();

  if (isTest()) {
    const mem = sharedMemStore();
    const rows = mem.rows;
    const uniqueDevices = new Set(rows.map((r) => r.deviceId)).size;
    const uniqueCountries = new Set(rows.map((r) => r.country).filter(Boolean)).size;
    const countByDeviceName = new Map<string, number>();
    const countByCountry = new Map<string, number>();
    for (const r of rows) {
      const key = `${r.displayName ?? "Anonymous"}|${r.place ?? ""}`;
      countByDeviceName.set(key, (countByDeviceName.get(key) ?? 0) + r.count);
      if (r.country) countByCountry.set(r.country, (countByCountry.get(r.country) ?? 0) + r.count);
    }
    return {
      koti,
      uniqueWriters: uniqueDevices,
      countriesActive: uniqueCountries,
      recentWriters: rows.slice(-12).reverse().map((r) => ({
        name: r.displayName ?? "Anonymous",
        place: r.place ?? "",
        count: r.count,
        ago: "live",
        committedAt: r.updatedAt,
      })),
      topWriters: Array.from(countByDeviceName.entries())
        .map(([k, count]) => {
          const name = k.split("|")[0] ?? "Anonymous";
          return { name, count, joined: "" };
        })
        .sort((a, b) => b.count - a.count)
        .slice(0, 6),
      countries: Array.from(countByCountry.entries())
        .map(([country, count]) => ({ country, count }))
        .sort((a, b) => b.count - a.count),
    };
  }

  const db = getDb();

  // All aggregations now read from shared_daily_counts (one row per
  // (koti, device, date)). Recent writers = most recent updated_at rows;
  // top writers + countries = SUM(count) per device / per country.
  const [aggRows, recentRows, topRows, countryRows] = await Promise.all([
    db.execute(sql`
      SELECT
        COUNT(DISTINCT device_id) AS unique_writers,
        COUNT(DISTINCT country) FILTER (WHERE country IS NOT NULL AND country <> '') AS countries_active
      FROM likhita.shared_daily_counts
      WHERE shared_koti_id = ${koti.id}
    `),
    db.execute(sql`
      SELECT
        COALESCE(display_name, 'Anonymous') AS name,
        COALESCE(place, '') AS place,
        count,
        updated_at AS committed_at
      FROM likhita.shared_daily_counts
      WHERE shared_koti_id = ${koti.id}
      ORDER BY updated_at DESC
      LIMIT 12
    `),
    db.execute(sql`
      SELECT
        COALESCE(
          (SELECT display_name FROM likhita.shared_daily_counts d2
             WHERE d2.device_id = d.device_id AND display_name IS NOT NULL
             ORDER BY updated_at DESC LIMIT 1),
          'Anonymous'
        ) AS name,
        COALESCE(
          (SELECT place FROM likhita.shared_daily_counts d3
             WHERE d3.device_id = d.device_id AND place IS NOT NULL
             ORDER BY updated_at DESC LIMIT 1),
          ''
        ) AS place,
        SUM(count)::int AS count,
        MIN(date) AS joined
      FROM likhita.shared_daily_counts d
      WHERE shared_koti_id = ${koti.id}
      GROUP BY device_id
      ORDER BY count DESC
      LIMIT 6
    `),
    db.execute(sql`
      SELECT country, SUM(count)::int AS count
      FROM likhita.shared_daily_counts
      WHERE shared_koti_id = ${koti.id}
        AND country IS NOT NULL AND country <> ''
      GROUP BY country
      ORDER BY count DESC
      LIMIT 16
    `),
  ]);

  const aggRow = (aggRows.rows ?? aggRows)[0] as { unique_writers: bigint | number; countries_active: bigint | number } | undefined;
  const uniqueWriters = aggRow ? Number(aggRow.unique_writers) : 0;
  const countriesActive = aggRow ? Number(aggRow.countries_active) : 0;

  type RecentRow = { name: string; place: string; count: number; committed_at: string | Date };
  const recent = ((recentRows.rows ?? recentRows) as unknown as RecentRow[]).map((r) => {
    const t = r.committed_at instanceof Date ? r.committed_at : new Date(r.committed_at);
    return {
      name: r.name || "Anonymous",
      place: r.place || "",
      count: Number(r.count) || 1,
      ago: humanAgo(t.getTime()),
      committedAt: t.toISOString(),
    };
  });

  type TopRow = { name: string; place: string; count: bigint | number; joined: string | Date };
  const top = ((topRows.rows ?? topRows) as unknown as TopRow[]).map((r) => {
    const joinedDate = r.joined instanceof Date ? r.joined : new Date(r.joined);
    return {
      name: r.place ? `${r.name} · ${r.place}` : r.name,
      count: Number(r.count),
      joined: joinedDate.toLocaleString("en-US", { month: "short", day: "2-digit" }),
    };
  });

  type CountryRow = { country: string; count: bigint | number };
  const countries = ((countryRows.rows ?? countryRows) as unknown as CountryRow[]).map((r) => ({
    country: r.country,
    count: Number(r.count),
  }));

  return {
    koti,
    uniqueWriters,
    countriesActive,
    recentWriters: recent,
    topWriters: top,
    countries,
  };
}

/// UPSERT one batch into the Sangha's per-(device, date) ledger.
/// `LEAST(current_count + N, target_count)` on the shared_kotis row
/// gives us the 1-crore cap atomically. One row written per
/// (device, date) — multiple writing sessions on the same local day
/// collapse, so the table grows by at most 1 row per devotee per day.
export async function appendSharedBatch(input: SharedAppendInput): Promise<SharedAppendResult> {
  if (input.count <= 0) throw new Error("appendSharedBatch: empty batch");

  if (isTest()) {
    const mem = sharedMemStore();
    const koti = await getActiveSharedKoti();
    const before = koti.currentCount;
    const newCount = Math.min(before + input.count, koti.targetCount);
    const acceptedHere = newCount - before;
    if (mem.koti) mem.koti.currentCount = newCount;
    if (acceptedHere > 0) {
      const key = `${input.deviceId}|${input.date}`;
      const existing = mem.rows.find((r) => `${r.deviceId}|${r.date}` === key);
      const now = new Date().toISOString();
      if (existing) {
        existing.count += acceptedHere;
        existing.updatedAt = now;
        existing.displayName = input.displayName ?? existing.displayName;
        existing.place = input.place ?? existing.place;
        existing.country = input.country ?? existing.country;
      } else {
        mem.rows.push({
          deviceId: input.deviceId,
          displayName: input.displayName,
          place: input.place,
          country: input.country,
          count: acceptedHere,
          date: input.date,
          updatedAt: now,
        });
      }
    }
    return {
      acceptedHere,
      currentCount: newCount,
      remaining: koti.targetCount - newCount,
      complete: newCount >= koti.targetCount,
    };
  }

  const db = getDb();
  const koti = await getActiveSharedKoti();

  const updated = await db
    .update(schema.sharedKotis)
    .set({
      currentCount: sql`LEAST(current_count + ${input.count}, target_count)`,
      updatedAt: sql`NOW()`,
    })
    .where(eq(schema.sharedKotis.id, koti.id))
    .returning({ currentCount: schema.sharedKotis.currentCount });

  const after = updated[0] ? Number(updated[0].currentCount) : koti.currentCount;
  const acceptedHere = after - koti.currentCount;
  if (acceptedHere <= 0) {
    return { acceptedHere: 0, currentCount: after, remaining: 0, complete: after >= koti.targetCount };
  }

  await db.execute(sql`
    INSERT INTO likhita.shared_daily_counts
      (shared_koti_id, device_id, date, count, display_name, place, country, updated_at)
    VALUES
      (${koti.id}, ${input.deviceId}, ${input.date}, ${acceptedHere},
       ${input.displayName}, ${input.place}, ${input.country}, NOW())
    ON CONFLICT (shared_koti_id, device_id, date) DO UPDATE
      SET count = likhita.shared_daily_counts.count + EXCLUDED.count,
          display_name = COALESCE(EXCLUDED.display_name, likhita.shared_daily_counts.display_name),
          place = COALESCE(EXCLUDED.place, likhita.shared_daily_counts.place),
          country = COALESCE(EXCLUDED.country, likhita.shared_daily_counts.country),
          updated_at = NOW()
  `);

  return {
    acceptedHere,
    currentCount: after,
    remaining: koti.targetCount - after,
    complete: after >= koti.targetCount,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Test in-memory store for shared koti
// ─────────────────────────────────────────────────────────────────────────────

type SharedMemRow = {
  deviceId: string;
  displayName: string | null;
  place: string | null;
  country: string | null;
  count: number;
  date: string;
  updatedAt: string;
};

type SharedMem = {
  koti: SharedKotiRow | null;
  rows: SharedMemRow[];
};

function sharedMemStore(): SharedMem {
  const g = globalThis as unknown as { __likhitaSharedMem?: SharedMem };
  if (!g.__likhitaSharedMem) {
    g.__likhitaSharedMem = { koti: null, rows: [] };
  }
  return g.__likhitaSharedMem;
}

function humanAgo(timestampMs: number): string {
  const diffSec = Math.max(0, Math.floor((Date.now() - timestampMs) / 1000));
  if (diffSec < 60) return `${diffSec}s`;
  const diffMin = Math.floor(diffSec / 60);
  if (diffMin < 60) return `${diffMin}m`;
  const diffHr = Math.floor(diffMin / 60);
  if (diffHr < 24) return `${diffHr}h`;
  return `${Math.floor(diffHr / 24)}d`;
}
