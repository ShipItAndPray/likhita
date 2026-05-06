import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError } from "@/lib/http";

export const runtime = "nodejs";

const Param = z.object({ id: z.string().uuid() });
const Body = z.object({
  pledgeAcknowledged: z.literal(true),
  affirmedAt: z.string().datetime(),
});

export async function POST(
  req: NextRequest,
  ctx: { params: Promise<{ id: string }> },
): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    await requireAuth(req);
    const { id } = Param.parse(await ctx.params);
    const body = Body.parse(await req.json());

    return NextResponse.json({
      kotiId: id,
      affirmedAt: body.affirmedAt,
      sessionResumed: true,
    });
  } catch (err) {
    return handleError(err);
  }
}
