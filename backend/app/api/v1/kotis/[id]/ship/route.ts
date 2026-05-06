import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError } from "@/lib/http";
import { TEMPLE_DESTINATIONS } from "@/db/schema";

export const runtime = "nodejs";

const Param = z.object({ id: z.string().uuid() });
const Body = z.object({
  shipTemple: z.boolean(),
  templeDestination: z.enum(TEMPLE_DESTINATIONS).optional(),
  shipHome: z.boolean(),
  shippingAddress: z
    .object({
      line1: z.string().min(1).max(200),
      line2: z.string().max(200).optional(),
      city: z.string().min(1).max(100),
      region: z.string().min(1).max(100),
      postalCode: z.string().min(2).max(20),
      country: z.string().length(2),
      recipientName: z.string().min(1).max(120),
      recipientPhone: z.string().min(6).max(40),
    })
    .optional(),
  paymentProvider: z.enum(["stripe", "razorpay", "apple_iap"]),
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
      paymentIntent: {
        provider: body.paymentProvider,
        clientToken: "stub-payment-intent",
        amountCents: priceFor(body),
        currency: body.paymentProvider === "razorpay" ? "inr" : "usd",
      },
      pipeline: {
        status: "awaiting_payment",
        nextStep: "client_completes_payment_then_webhook_advances",
      },
    });
  } catch (err) {
    return handleError(err);
  }
}

function priceFor(body: z.infer<typeof Body>): number {
  let cents = 0;
  if (body.shipTemple) cents += 4900;
  if (body.shipHome) cents += 3900;
  return cents;
}
