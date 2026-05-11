import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { findUserByClerkId, getKotiById } from "@/lib/repo";

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

    const koti = await getKotiById(id);
    if (!koti) {
      return jsonError(404, "not_found", "Koti does not exist");
    }
    const user = await findUserByClerkId(auth.clerkId);
    if (!user || koti.userId !== user.id) {
      return jsonError(403, "forbidden", "You do not own this koti");
    }
    return NextResponse.json({ koti });
  } catch (err) {
    return handleError(err);
  }
}
