import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import {
  auditBatch,
  cadenceFingerprint,
  checkSequenceContinuity,
  isRateLimited,
  type AuditReason,
} from "@/lib/anticheat";
import { hashRequestBody, validateIdempotencyKey } from "@/lib/idempotency";

export const runtime = "nodejs";

const Param = z.object({ id: z.string().uuid() });

const EntryItem = z.object({
  sequenceNumber: z.number().int().positive(),
  committedAt: z.string().datetime(),
  cadenceSignature: z.object({
    gaps: z.array(z.number().nonnegative().max(60_000)).min(1).max(64),
  }),
  clientSessionId: z.string().uuid(),
});

const Body = z.object({
  idempotencyKey: z.string(),
  entries: z.array(EntryItem).min(1).max(25),
});

// In a real implementation this comes from the DB row for the koti.
type KotiSnapshot = {
  id: string;
  userId: string;
  currentCount: number;
  targetCount: number;
  baselineCadenceMs: number | null;
  baselineVarianceMs: number | null;
  recentCommitsMs: number[];
  recentCadenceFingerprints: string[];
};

async function loadKotiSnapshot(id: string, userId: string): Promise<KotiSnapshot | null> {
  // Stubbed snapshot. The real loader joins kotis + last N entries to populate
  // `recentCommitsMs` and `recentCadenceFingerprints` for anti-cheat checks.
  return {
    id,
    userId,
    currentCount: 0,
    targetCount: 100000,
    baselineCadenceMs: 180,
    baselineVarianceMs: 45,
    recentCommitsMs: [],
    recentCadenceFingerprints: [],
  };
}

export async function POST(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const { id } = Param.parse(await ctx.params);
    const body = Body.parse(await req.json());

    validateIdempotencyKey(body.idempotencyKey);
    const requestHash = hashRequestBody(body);

    const snapshot = await loadKotiSnapshot(id, auth.userId);
    if (!snapshot) return jsonError(404, "not_found", "Koti does not exist");
    if (snapshot.userId !== auth.userId) {
      return jsonError(403, "forbidden", "You do not own this koti");
    }

    const now = Date.now();
    if (isRateLimited(snapshot.recentCommitsMs, now)) {
      return jsonError(429, "rate_limited", "Slow down. This is sadhana, not a race.");
    }

    const seqNumbers = body.entries.map((e) => e.sequenceNumber);
    const continuity = checkSequenceContinuity(seqNumbers, snapshot.currentCount + 1);
    if (!continuity.ok) {
      return jsonError(409, continuity.reason, "Sequence numbers must be contiguous");
    }

    const audit = auditBatch({
      entries: body.entries.map((e) => ({
        sequenceNumber: e.sequenceNumber,
        cadence: e.cadenceSignature,
        committedAt: Date.parse(e.committedAt),
      })),
      baselineCadenceMs: snapshot.baselineCadenceMs,
      baselineVarianceMs: snapshot.baselineVarianceMs,
      recentCadenceFingerprints: snapshot.recentCadenceFingerprints,
    });

    if (audit.reject && audit.rejectReason) {
      const reason: AuditReason = audit.rejectReason;
      return jsonError(422, reason, "Anti-cheat rejected this batch");
    }

    if (audit.macroLockoutSuggested) {
      // Soft 5-minute lockout per spec §7. The client receives this code and
      // surfaces the "Slow down. This is sadhana, not a race." message.
      return jsonError(423, "macro_lockout", "Soft lockout for 5 minutes");
    }

    // In production: BEGIN TX, insert entries (with flagged column from
    // perEntry), bump currentCount, write idempotency record, COMMIT.
    void requestHash;
    void cadenceFingerprint;

    const accepted = body.entries.length;
    const newCount = snapshot.currentCount + accepted;
    const milestoneUnlocked = crossesMilestone(snapshot.currentCount, newCount);

    return NextResponse.json({
      accepted,
      currentCount: newCount,
      milestoneUnlocked: milestoneUnlocked !== null,
      milestoneLabel: milestoneUnlocked,
      flagged: audit.perEntry.filter((p) => p.flagged).map((p) => p.sequenceNumber),
    });
  } catch (err) {
    return handleError(err);
  }
}

const MILESTONES: { count: number; label: string }[] = [
  { count: 11_000, label: "Ayodhya" },
  { count: 25_000, label: "Chitrakoot" },
  { count: 40_000, label: "Panchavati" },
  { count: 55_000, label: "Kishkindha" },
  { count: 70_000, label: "Lanka Bridge" },
  { count: 90_000, label: "Lanka Yuddha" },
  { count: 100_000, label: "Pattabhishekam" },
];

function crossesMilestone(prev: number, next: number): string | null {
  for (const m of MILESTONES) {
    if (prev < m.count && next >= m.count) return m.label;
  }
  return null;
}
