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
  // Anti-cheat baselines stored on the row (see comments in entries route).
  baselineCadenceMs: number | null;
  baselineVarianceMs: number | null;
};

export type EntryInsert = {
  sequenceNumber: number;
  committedAt: string;
  cadenceFingerprint: string;
  clientSessionId: string;
  flagged: boolean;
};

export type RecentSnapshot = {
  recentCommitsMs: number[];
  recentCadenceFingerprints: string[];
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
  entries: Map<string, EntryInsert[]>; // keyed by koti id
  idem: Map<string, { hash: string; response: unknown }>; // key = `${kotiId}:${idemKey}`
};

function memStore(): Mem {
  const g = globalThis as unknown as { __likhitaMem?: Mem };
  if (!g.__likhitaMem) {
    g.__likhitaMem = {
      users: new Map(),
      kotis: new Map(),
      entries: new Map(),
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
    // Baselines aren't persisted yet; calibration step will set them.
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
      baselineCadenceMs: 180,
      baselineVarianceMs: 45,
    };
    mem.kotis.set(id, row);
    mem.entries.set(id, []);
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

export async function getRecentForKoti(kotiId: string): Promise<RecentSnapshot> {
  if (isTest()) {
    const ents = memStore().entries.get(kotiId) ?? [];
    const last20 = ents.slice(-20);
    return {
      recentCommitsMs: last20.map((e) => Date.parse(e.committedAt)),
      recentCadenceFingerprints: last20.map((e) => e.cadenceFingerprint),
    };
  }
  const db = getDb();
  const rows = await db
    .select({ committedAt: schema.entries.committedAt, cadenceSignature: schema.entries.cadenceSignature })
    .from(schema.entries)
    .where(eq(schema.entries.kotiId, kotiId))
    .orderBy(desc(schema.entries.sequenceNumber))
    .limit(20);
  return {
    recentCommitsMs: rows.map((r) => (r.committedAt instanceof Date ? r.committedAt.getTime() : Date.parse(String(r.committedAt)))),
    recentCadenceFingerprints: rows.map((r) => r.cadenceSignature),
  };
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
// Entries — the monotonic forward-only commit
// ─────────────────────────────────────────────────────────────────────────────

export type CommitEntriesInput = {
  kotiId: string;
  expectedCurrentCount: number;
  newCount: number;
  entries: EntryInsert[];
};

export type CommitEntriesResult = { ok: true; currentCount: number } | { ok: false; reason: "concurrent_update" };

/// Compare-and-swap commit. The UPDATE matches on `current_count = expected`
/// so concurrent submissions cannot double-count or move backwards. If 0 rows
/// are updated, the caller (this is rare, but possible if the same client
/// retries without idempotency or two clients race) is told to re-read and
/// rebase.
export async function commitEntries(input: CommitEntriesInput): Promise<CommitEntriesResult> {
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
    const list = mem.entries.get(input.kotiId) ?? [];
    list.push(...input.entries);
    mem.entries.set(input.kotiId, list);
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

  if (input.entries.length > 0) {
    await db.insert(schema.entries).values(
      input.entries.map((e) => ({
        kotiId: input.kotiId,
        sequenceNumber: e.sequenceNumber,
        committedAt: new Date(e.committedAt),
        cadenceSignature: e.cadenceFingerprint,
        clientSessionId: e.clientSessionId,
        flagged: e.flagged,
      })),
    );
  }

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
  cadenceFingerprints: string[];
  flagged: boolean[];
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
    const entries = mem.entries;
    const uniqueDevices = new Set(entries.map((e) => e.deviceId)).size;
    const uniqueCountries = new Set(entries.map((e) => e.country).filter(Boolean)).size;
    const countByDeviceName = new Map<string, number>();
    const countByCountry = new Map<string, number>();
    for (const e of entries) {
      const key = `${e.displayName ?? "Anonymous"}|${e.place ?? ""}`;
      countByDeviceName.set(key, (countByDeviceName.get(key) ?? 0) + 1);
      if (e.country) countByCountry.set(e.country, (countByCountry.get(e.country) ?? 0) + 1);
    }
    return {
      koti,
      uniqueWriters: uniqueDevices,
      countriesActive: uniqueCountries,
      recentWriters: entries.slice(-12).reverse().map((e) => ({
        name: e.displayName ?? "Anonymous",
        place: e.place ?? "",
        count: 1,
        ago: "live",
        committedAt: e.committedAt,
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

  const [aggRows, recentRows, topRows, countryRows] = await Promise.all([
    db.execute(sql`
      SELECT
        COUNT(DISTINCT device_id) AS unique_writers,
        COUNT(DISTINCT country) FILTER (WHERE country IS NOT NULL AND country <> '') AS countries_active
      FROM likhita.shared_entries
      WHERE shared_koti_id = ${koti.id}
    `),
    db.execute(sql`
      SELECT
        COALESCE(display_name, 'Anonymous') AS name,
        COALESCE(place, '') AS place,
        committed_at
      FROM likhita.shared_entries
      WHERE shared_koti_id = ${koti.id}
      ORDER BY committed_at DESC
      LIMIT 12
    `),
    db.execute(sql`
      SELECT
        COALESCE(
          (SELECT display_name FROM likhita.shared_entries e2
             WHERE e2.device_id = e.device_id AND display_name IS NOT NULL
             ORDER BY committed_at DESC LIMIT 1),
          'Anonymous'
        ) AS name,
        COALESCE(
          (SELECT place FROM likhita.shared_entries e3
             WHERE e3.device_id = e.device_id AND place IS NOT NULL
             ORDER BY committed_at DESC LIMIT 1),
          ''
        ) AS place,
        COUNT(*) AS count,
        MIN(committed_at) AS joined
      FROM likhita.shared_entries e
      WHERE shared_koti_id = ${koti.id}
      GROUP BY device_id
      ORDER BY count DESC
      LIMIT 6
    `),
    db.execute(sql`
      SELECT country, COUNT(*) AS count
      FROM likhita.shared_entries
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

  type RecentRow = { name: string; place: string; committed_at: string | Date };
  const recent = ((recentRows.rows ?? recentRows) as unknown as RecentRow[]).map((r) => {
    const t = r.committed_at instanceof Date ? r.committed_at : new Date(r.committed_at);
    return {
      name: r.name || "Anonymous",
      place: r.place || "",
      count: 1,
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

/// Append N entries to the shared koti. Atomic UPDATE caps `current_count`
/// at `target_count` — once the 1 crore ceiling is hit, the route returns
/// 410 koti_complete on next call.
export async function appendSharedEntries(input: SharedAppendInput): Promise<SharedAppendResult> {
  const desiredCount = input.cadenceFingerprints.length;
  if (desiredCount === 0) throw new Error("appendSharedEntries: empty batch");

  if (isTest()) {
    const mem = sharedMemStore();
    const koti = await getActiveSharedKoti();
    const before = koti.currentCount;
    const newCount = Math.min(before + desiredCount, koti.targetCount);
    const acceptedHere = newCount - before;
    if (mem.koti) mem.koti.currentCount = newCount;
    for (let i = 0; i < acceptedHere; i += 1) {
      mem.entries.push({
        deviceId: input.deviceId,
        displayName: input.displayName,
        place: input.place,
        country: input.country,
        cadenceSignature: input.cadenceFingerprints[i] ?? "",
        flagged: input.flagged[i] ?? false,
        committedAt: new Date().toISOString(),
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
      currentCount: sql`LEAST(current_count + ${desiredCount}, target_count)`,
      updatedAt: sql`NOW()`,
    })
    .where(eq(schema.sharedKotis.id, koti.id))
    .returning({ currentCount: schema.sharedKotis.currentCount });

  const after = updated[0] ? Number(updated[0].currentCount) : koti.currentCount;
  const acceptedHere = after - koti.currentCount;
  if (acceptedHere <= 0) {
    return { acceptedHere: 0, currentCount: after, remaining: 0, complete: after >= koti.targetCount };
  }

  await db.insert(schema.sharedEntries).values(
    Array.from({ length: acceptedHere }).map((_, i) => ({
      sharedKotiId: koti.id,
      deviceId: input.deviceId,
      displayName: input.displayName,
      place: input.place,
      country: input.country,
      cadenceSignature: input.cadenceFingerprints[i] ?? "",
      flagged: input.flagged[i] ?? false,
    })),
  );

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

type SharedMem = {
  koti: SharedKotiRow | null;
  entries: {
    deviceId: string;
    displayName: string | null;
    place: string | null;
    country: string | null;
    cadenceSignature: string;
    flagged: boolean;
    committedAt: string;
  }[];
};

function sharedMemStore(): SharedMem {
  const g = globalThis as unknown as { __likhitaSharedMem?: SharedMem };
  if (!g.__likhitaSharedMem) {
    g.__likhitaSharedMem = { koti: null, entries: [] };
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
