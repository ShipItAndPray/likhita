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
import {
  commitEntries,
  findUserByClerkId,
  getKotiById,
  getRecentForKoti,
  lookupIdempotency,
  storeIdempotency,
  type EntryInsert,
} from "@/lib/repo";

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

    // Idempotency: same key + same body hash → return cached response.
    const cached = await lookupIdempotency(id, body.idempotencyKey);
    if (cached) {
      if (cached.hash !== requestHash) {
        return jsonError(
          409,
          "idempotency_conflict",
          "Idempotency key was reused with a different body",
        );
      }
      return NextResponse.json(cached.response);
    }

    const koti = await getKotiById(id);
    if (!koti) return jsonError(404, "not_found", "Koti does not exist");

    const user = await findUserByClerkId(auth.clerkId);
    if (!user || koti.userId !== user.id) {
      return jsonError(403, "forbidden", "You do not own this koti");
    }

    if (koti.completedAt) {
      return jsonError(
        410,
        "koti_complete",
        "This koti has already reached its target. No further entries accepted.",
      );
    }

    const recent = await getRecentForKoti(id);

    const now = Date.now();
    if (isRateLimited(recent.recentCommitsMs, now)) {
      return jsonError(429, "rate_limited", "Slow down. This is sadhana, not a race.");
    }

    const seqNumbers = body.entries.map((e) => e.sequenceNumber);
    const continuity = checkSequenceContinuity(seqNumbers, koti.currentCount + 1);
    if (!continuity.ok) {
      return jsonError(409, continuity.reason, "Sequence numbers must be contiguous");
    }

    const audit = auditBatch({
      entries: body.entries.map((e) => ({
        sequenceNumber: e.sequenceNumber,
        cadence: e.cadenceSignature,
        committedAt: Date.parse(e.committedAt),
      })),
      baselineCadenceMs: koti.baselineCadenceMs,
      baselineVarianceMs: koti.baselineVarianceMs,
      recentCadenceFingerprints: recent.recentCadenceFingerprints,
    });

    if (audit.reject && audit.rejectReason) {
      const reason: AuditReason = audit.rejectReason;
      return jsonError(422, reason, "Anti-cheat rejected this batch");
    }

    if (audit.macroLockoutSuggested) {
      return jsonError(423, "macro_lockout", "Soft lockout for 5 minutes");
    }

    // Cap acceptance at the target count — server is the boundary.
    const accepted = body.entries.length;
    const newCount = Math.min(koti.currentCount + accepted, koti.targetCount);

    const flaggedSet = new Set(
      audit.perEntry.filter((p) => p.flagged).map((p) => p.sequenceNumber),
    );

    const entryRows: EntryInsert[] = body.entries.map((e) => ({
      sequenceNumber: e.sequenceNumber,
      committedAt: e.committedAt,
      cadenceFingerprint: cadenceFingerprint(e.cadenceSignature.gaps),
      clientSessionId: e.clientSessionId,
      flagged: flaggedSet.has(e.sequenceNumber),
    }));

    const commit = await commitEntries({
      kotiId: id,
      expectedCurrentCount: koti.currentCount,
      newCount,
      entries: entryRows,
    });

    if (!commit.ok) {
      return jsonError(
        409,
        "concurrent_update",
        "Koti count changed during submission. Refetch and retry.",
      );
    }

    const milestoneUnlocked = crossesMilestone(
      koti.currentCount,
      commit.currentCount,
      koti.targetCount,
    );

    const response = {
      accepted,
      currentCount: commit.currentCount,
      targetCount: koti.targetCount,
      complete: commit.currentCount >= koti.targetCount,
      milestoneUnlocked: milestoneUnlocked !== null,
      milestoneLabel: milestoneUnlocked,
      flagged: Array.from(flaggedSet),
    };

    await storeIdempotency(id, body.idempotencyKey, requestHash, response);

    return NextResponse.json(response);
  } catch (err) {
    return handleError(err);
  }
}

const MILESTONES: { fraction: number; label: string }[] = [
  { fraction: 0.10, label: "Chitrakoot" },
  { fraction: 0.25, label: "Panchavati" },
  { fraction: 0.50, label: "Kishkindha" },
  { fraction: 0.75, label: "Setu" },
  { fraction: 0.90, label: "Lanka" },
  { fraction: 1.00, label: "Pattabhishekam" },
];

function crossesMilestone(prev: number, next: number, targetCount: number): string | null {
  if (targetCount <= 0) return null;
  for (const m of MILESTONES) {
    const threshold = Math.floor(m.fraction * targetCount);
    if (prev < threshold && next >= threshold) return m.label;
  }
  return null;
}
