import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { findUserByClerkId, getKotiById, updateKotiPace } from "@/lib/repo";

export const runtime = "nodejs";

const Param = z.object({ id: z.string().uuid() });

const REMINDER_IDS = ["brahma", "pratah", "madhyana", "sandhya"] as const;

/// PATCH /api/v1/kotis/:id/pace
/// Updates the Pace fields: goalDays (30..730) and reminderTimes
/// (subset of {brahma, pratah, madhyana, sandhya}, at most 3).
/// Both fields are independently optional.
const Body = z.object({
  goalDays: z.number().int().min(30).max(730).optional(),
  reminderTimes: z.array(z.enum(REMINDER_IDS)).max(3).optional(),
});

export async function PATCH(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const { id } = Param.parse(await ctx.params);
    const body = Body.parse(await req.json());

    const existing = await getKotiById(id);
    if (!existing) return jsonError(404, "not_found", "Koti does not exist");

    const user = await findUserByClerkId(auth.clerkId);
    if (!user || existing.userId !== user.id) {
      return jsonError(403, "forbidden", "You do not own this koti");
    }

    const updated = await updateKotiPace(id, body);
    if (!updated) return jsonError(404, "not_found", "Koti does not exist");

    return NextResponse.json({
      goalDays: updated.goalDays,
      reminderTimes: updated.reminderTimes,
    });
  } catch (err) {
    return handleError(err);
  }
}
