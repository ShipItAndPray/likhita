import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { findUserByClerkId, getDailyCounts, getKotiById } from "@/lib/repo";

export const runtime = "nodejs";

const Param = z.object({ id: z.string().uuid() });

/// GET /api/v1/kotis/:id/calendar?days=180
/// Returns per-day mantra contributions for the Pace screen's calendar.
/// Window is capped at 365 days; default 180.
export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const { id } = Param.parse(await ctx.params);

    const koti = await getKotiById(id);
    if (!koti) return jsonError(404, "not_found", "Koti does not exist");

    const user = await findUserByClerkId(auth.clerkId);
    if (!user || koti.userId !== user.id) {
      return jsonError(403, "forbidden", "You do not own this koti");
    }

    const rawDays = new URL(req.url).searchParams.get("days");
    const days = Math.min(365, Math.max(1, Number(rawDays ?? 180)));
    const daily = await getDailyCounts(id, days);

    return NextResponse.json({ days, daily });
  } catch (err) {
    return handleError(err);
  }
}
