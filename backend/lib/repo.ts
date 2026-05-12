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

// One write batch as it arrives from iOS — no per-mantra payload anymore,
// just the count + the time range covered. Anti-cheat was removed (the
// practice is voluntary; "it's the god who is going to enforce it").
export type EntryBatchInsert = {
  startSequence: number;
  endSequence: number;
  count: number;
  clientSessionId: string;
  committedFirstAt: string;
  committedLastAt: string;
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
  batches: Map<string, EntryBatchInsert[]>; // keyed by koti id
  idem: Map<string, { hash: string; response: unknown }>; // key = `${kotiId}:${idemKey}`
};

function memStore(): Mem {
  const g = globalThis as unknown as { __likhitaMem?: Mem };
  if (!g.__likhitaMem) {
    g.__likhitaMem = {
      users: new Map(),
      kotis: new Map(),
      batches: new Map(),
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
    mem.batches.set(id, []);
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
export async function getDailyCounts(kotiId: string, days: number): Promise<DailyCount[]> {
  if (isTest()) {
    const mem = memStore();
    const batches = mem.batches.get(kotiId) ?? [];
    const totals = new Map<string, number>();
    for (const b of batches) {
      const date = (new Date(b.committedFirstAt)).toISOString().slice(0, 10);
      totals.set(date, (totals.get(date) ?? 0) + b.count);
    }
    return Array.from(totals.entries())
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }
  const db = getDb();
  const rows = await db.execute(sql`
    SELECT to_char(date_trunc('day', committed_first_at AT TIME ZONE 'UTC'), 'YYYY-MM-DD') AS date,
           SUM(count)::int AS count
    FROM likhita.entry_batches
    WHERE koti_id = ${kotiId}
      AND committed_first_at >= NOW() - (${days} || ' days')::interval
    GROUP BY 1
    ORDER BY 1
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
    const list = mem.batches.get(input.kotiId) ?? [];
    list.push(input.batch);
    mem.batches.set(input.kotiId, list);
    return { ok: true, currentCount: k.currentCount };
  }

  const db = getDb();
  // CAS update — returns the row only if expected count matched.
  const updated = await db
    .update(schema.kotis)
    .set({
      currentCount: input.newCount,
      // Stamp completion atomically when target is reached.
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

  await db.insert(schema.entryBatches).values({
    kotiId: input.kotiId,
    startSequence: input.batch.startSequence,
    endSequence: input.batch.endSequence,
    count: input.batch.count,
    clientSessionId: input.batch.clientSessionId,
    committedFirstAt: new Date(input.batch.committedFirstAt),
    committedLastAt: new Date(input.batch.committedLastAt),
  });

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
  committedFirstAt: string;
  committedLastAt: string;
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
    const batches = mem.batches;
    const uniqueDevices = new Set(batches.map((b) => b.deviceId)).size;
    const uniqueCountries = new Set(batches.map((b) => b.country).filter(Boolean)).size;
    const countByDeviceName = new Map<string, number>();
    const countByCountry = new Map<string, number>();
    for (const b of batches) {
      const key = `${b.displayName ?? "Anonymous"}|${b.place ?? ""}`;
      countByDeviceName.set(key, (countByDeviceName.get(key) ?? 0) + b.count);
      if (b.country) countByCountry.set(b.country, (countByCountry.get(b.country) ?? 0) + b.count);
    }
    return {
      koti,
      uniqueWriters: uniqueDevices,
      countriesActive: uniqueCountries,
      recentWriters: batches.slice(-12).reverse().map((b) => ({
        name: b.displayName ?? "Anonymous",
        place: b.place ?? "",
        count: b.count,
        ago: "live",
        committedAt: b.committedLastAt,
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

  // All aggregations now read from shared_entry_batches. The `count` column
  // on each row holds the mantras posted in that batch; SUM(count) gives
  // the actual mantra contribution per device/country.
  const [aggRows, recentRows, topRows, countryRows] = await Promise.all([
    db.execute(sql`
      SELECT
        COUNT(DISTINCT device_id) AS unique_writers,
        COUNT(DISTINCT country) FILTER (WHERE country IS NOT NULL AND country <> '') AS countries_active
      FROM likhita.shared_entry_batches
      WHERE shared_koti_id = ${koti.id}
    `),
    db.execute(sql`
      SELECT
        COALESCE(display_name, 'Anonymous') AS name,
        COALESCE(place, '') AS place,
        count,
        committed_last_at AS committed_at
      FROM likhita.shared_entry_batches
      WHERE shared_koti_id = ${koti.id}
      ORDER BY committed_last_at DESC
      LIMIT 12
    `),
    db.execute(sql`
      SELECT
        COALESCE(
          (SELECT display_name FROM likhita.shared_entry_batches b2
             WHERE b2.device_id = b.device_id AND display_name IS NOT NULL
             ORDER BY committed_last_at DESC LIMIT 1),
          'Anonymous'
        ) AS name,
        COALESCE(
          (SELECT place FROM likhita.shared_entry_batches b3
             WHERE b3.device_id = b.device_id AND place IS NOT NULL
             ORDER BY committed_last_at DESC LIMIT 1),
          ''
        ) AS place,
        SUM(count)::int AS count,
        MIN(committed_first_at) AS joined
      FROM likhita.shared_entry_batches b
      WHERE shared_koti_id = ${koti.id}
      GROUP BY device_id
      ORDER BY count DESC
      LIMIT 6
    `),
    db.execute(sql`
      SELECT country, SUM(count)::int AS count
      FROM likhita.shared_entry_batches
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

/// Append ONE batch to the shared koti. Atomic UPDATE caps `current_count`
/// at `target_count` — once the 1 crore ceiling is hit, the route returns
/// 410 koti_complete on next call. One row written per call.
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
      mem.batches.push({
        deviceId: input.deviceId,
        displayName: input.displayName,
        place: input.place,
        country: input.country,
        count: acceptedHere,
        committedFirstAt: input.committedFirstAt,
        committedLastAt: input.committedLastAt,
      });
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

  await db.insert(schema.sharedEntryBatches).values({
    sharedKotiId: koti.id,
    deviceId: input.deviceId,
    displayName: input.displayName,
    place: input.place,
    country: input.country,
    count: acceptedHere,
    committedFirstAt: new Date(input.committedFirstAt),
    committedLastAt: new Date(input.committedLastAt),
  });

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

type SharedMemBatch = {
  deviceId: string;
  displayName: string | null;
  place: string | null;
  country: string | null;
  count: number;
  committedFirstAt: string;
  committedLastAt: string;
};

type SharedMem = {
  koti: SharedKotiRow | null;
  batches: SharedMemBatch[];
};

function sharedMemStore(): SharedMem {
  const g = globalThis as unknown as { __likhitaSharedMem?: SharedMem };
  if (!g.__likhitaSharedMem) {
    g.__likhitaSharedMem = { koti: null, batches: [] };
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
