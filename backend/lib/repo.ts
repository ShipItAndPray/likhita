// Repository seam between route handlers and storage.
//
// Two implementations:
//   - Drizzle/Neon — used in dev + production.
//   - In-memory stub — used in `LIKHITA_RUNTIME=test` so existing route tests
//     don't need a live Postgres.
//
// Routes never import drizzle directly. They call functions from this module,
// which dispatches to one of the two backends based on the environment.

import { eq, and, sql, desc } from "drizzle-orm";
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
