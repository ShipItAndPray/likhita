import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { findTheme } from "@/lib/themes";

export const runtime = "nodejs";

const Param = z.object({ key: z.string().min(1).max(64) });
const Body = z.object({
  paymentProvider: z.enum(["stripe", "razorpay", "apple_iap"]),
});

export async function POST(
  req: NextRequest,
  ctx: { params: Promise<{ key: string }> },
): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    await requireAuth(req);
    const { key } = Param.parse(await ctx.params);
    const body = Body.parse(await req.json());

    const theme = findTheme(key);
    if (!theme) return jsonError(404, "not_found", "Theme not found");
    if (theme.free) return jsonError(409, "already_free", "Theme is already free");

    const amountCents =
      body.paymentProvider === "razorpay"
        ? theme.priceInrPaise
        : theme.priceUsdCents;

    return NextResponse.json({
      themeKey: theme.key,
      paymentIntent: {
        provider: body.paymentProvider,
        amountCents,
        currency: body.paymentProvider === "razorpay" ? "inr" : "usd",
      },
    });
  } catch (err) {
    return handleError(err);
  }
}
