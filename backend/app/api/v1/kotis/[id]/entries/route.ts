import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { hashRequestBody, validateIdempotencyKey } from "@/lib/idempotency";
import {
  commitBatch,
  findUserByClerkId,
  getKotiById,
  lookupIdempotency,
  storeIdempotency,
} from "@/lib/repo";

export const runtime = "nodejs";

const Param = z.object({ id: z.string().uuid() });

// One write batch per POST. Body is a summary, not a per-mantra payload —
// anti-cheat was removed, so we no longer need cadence signatures or
// individual entry timestamps. The server derives sequence numbers
// from the current count + 1 (no client-side sequence input needed).
//
// `count` upper bound is 1008 (a Nitya), the largest devotional batch
// pattern. Anything above that is almost certainly a script — and even
// if it's not, the client should split.
/// Personal koti write batch. `date` is the user's local date as
/// YYYY-MM-DD — the server UPSERTs into daily_counts keyed on
/// (koti_id, date) so multiple sessions on the same day produce one
/// row, not N. iOS must derive `date` from the device's local calendar
/// before posting (`DateFormatter` with `Locale.current` + `Calendar.current`).
const Body = z.object({
  idempotencyKey: z.string(),
  count: z.number().int().positive().max(1008),
  clientSessionId: z.string().uuid(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "expected YYYY-MM-DD"),
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

    // Cap acceptance at the target — server is the boundary.
    const requested = body.count;
    const accepted = Math.min(requested, koti.targetCount - koti.currentCount);
    if (accepted <= 0) {
      return jsonError(
        410,
        "koti_complete",
        "This koti has already reached its target. No further entries accepted.",
      );
    }

    const startSequence = koti.currentCount + 1;
    const endSequence = koti.currentCount + accepted;
    const newCount = endSequence;

    const commit = await commitBatch({
      kotiId: id,
      expectedCurrentCount: koti.currentCount,
      newCount,
      batch: {
        startSequence,
        endSequence,
        count: accepted,
        clientSessionId: body.clientSessionId,
        date: body.date,
      },
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
