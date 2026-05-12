import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { handleError, jsonError } from "@/lib/http";
import {
  auditBatch,
  cadenceFingerprint,
  isRateLimited,
  type AuditReason,
} from "@/lib/anticheat";
import { appendSharedEntries } from "@/lib/repo";

export const runtime = "nodejs";

// POST /api/v1/shared/entries — anonymous append into the Foundation Koti.
//
// No ownership check. No sequence continuity (concurrent writers from
// everywhere). Anti-cheat (cadence variance, sub-30ms inter-key floor)
// still runs because the goal is real human writing — macro replays
// dilute the ledger's authenticity.
//
// Atomic UPDATE caps `current_count` at the 1-crore target. Once full,
// the route returns 410 koti_complete.

const EntryItem = z.object({
  committedAt: z.string().datetime(),
  cadenceSignature: z.object({
    gaps: z.array(z.number().nonnegative().max(60_000)).min(1).max(64),
  }),
});

// Optional + nullable: iOS Swift's default Encodable emits `null` for nil
// Optionals by default; accept that as equivalent to absence so anonymous
// posts from the device don't fail validation.
const optionalNullableString = (min: number, max: number) =>
  z.union([z.string().min(min).max(max), z.null()]).optional();

const Body = z.object({
  deviceId: z.string().min(4).max(128),
  displayName: optionalNullableString(1, 80),
  place: optionalNullableString(1, 80),
  country: optionalNullableString(2, 80),
  // 500 to match the personal endpoint — see kotis/[id]/entries/route.ts.
  entries: z.array(EntryItem).min(1).max(500),
});

// In-memory per-device cadence history so we can apply the macro-replay
// fingerprint check even without persisting recent fingerprints. Reset
// on cold start — that's fine for the soft signal it provides.
const recentByDevice = new Map<string, { ts: number[]; fingerprints: string[] }>();
function trackDevice(deviceId: string, now: number, fp: string): { ts: number[]; fingerprints: string[] } {
  const entry = recentByDevice.get(deviceId) ?? { ts: [], fingerprints: [] };
  entry.ts.push(now);
  entry.fingerprints.push(fp);
  // Keep only the last 30 of each
  if (entry.ts.length > 30) entry.ts.shift();
  if (entry.fingerprints.length > 30) entry.fingerprints.shift();
  recentByDevice.set(deviceId, entry);
  return entry;
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const body = Body.parse(await req.json());

    // Rate-limit per device: ~4 mantras/sec equivalent.
    const tracked = recentByDevice.get(body.deviceId) ?? { ts: [], fingerprints: [] };
    const now = Date.now();
    if (isRateLimited(tracked.ts, now)) {
      return jsonError(429, "rate_limited", "Slow down. This is sadhana, not a race.");
    }

    const audit = auditBatch({
      entries: body.entries.map((e, idx) => ({
        sequenceNumber: idx + 1, // synthetic — sequence isn't meaningful here
        cadence: e.cadenceSignature,
        committedAt: Date.parse(e.committedAt),
      })),
      // Baselines are per-user — we don't track them for anonymous shared
      // writes. Drift detection therefore doesn't fire; the variance floor
      // and inter-key floor still catch hard macros.
      baselineCadenceMs: null,
      baselineVarianceMs: null,
      recentCadenceFingerprints: tracked.fingerprints,
    });

    if (audit.reject && audit.rejectReason) {
      const reason: AuditReason = audit.rejectReason;
      return jsonError(422, reason, "Anti-cheat rejected this batch");
    }

    // Build fingerprints + flagged arrays
    const flaggedSet = new Set(audit.perEntry.filter((p) => p.flagged).map((p) => p.sequenceNumber));
    const fingerprints = body.entries.map((e) => cadenceFingerprint(e.cadenceSignature.gaps));
    const flagged = body.entries.map((_, idx) => flaggedSet.has(idx + 1));

    // Record one timestamp per entry into the device-rate tracker.
    for (const fp of fingerprints) trackDevice(body.deviceId, now, fp);

    const result = await appendSharedEntries({
      deviceId: body.deviceId,
      displayName: body.displayName ?? null,
      place: body.place ?? null,
      country: body.country ?? null,
      cadenceFingerprints: fingerprints,
      flagged,
    });

    if (result.acceptedHere === 0 && result.complete) {
      return jsonError(410, "koti_complete", "The Foundation Koti is complete. No further entries accepted.");
    }

    return NextResponse.json(result);
  } catch (err) {
    return handleError(err);
  }
}
