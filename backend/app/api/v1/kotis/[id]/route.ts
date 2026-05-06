import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";

export const runtime = "nodejs";

const KotiIdParam = z.object({ id: z.string().uuid() });

export async function GET(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const { id } = KotiIdParam.parse(await ctx.params);

    // Stubbed lookup: in production this loads the koti row + entry counts and
    // verifies ownership against `auth.userId`.
    const fakeKoti = {
      id,
      userId: auth.userId,
      currentCount: 0,
      targetCount: 100000,
      locked: true,
    };
    if (!fakeKoti) {
      return jsonError(404, "not_found", "Koti does not exist");
    }
    return NextResponse.json({ koti: fakeKoti });
  } catch (err) {
    return handleError(err);
  }
}
