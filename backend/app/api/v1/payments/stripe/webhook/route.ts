import { type NextRequest, NextResponse } from "next/server";
import { handleError, jsonError } from "@/lib/http";
import { verifyStripeSignature } from "@/lib/payments";

export const runtime = "nodejs";

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    const secret = process.env.STRIPE_WEBHOOK_SECRET;
    if (!secret) return jsonError(500, "misconfigured", "STRIPE_WEBHOOK_SECRET not set");

    const raw = await req.text();
    const sig = req.headers.get("stripe-signature");
    if (!verifyStripeSignature(raw, sig, secret)) {
      return jsonError(400, "invalid_signature", "Stripe signature verification failed");
    }

    const event = JSON.parse(raw) as { type: string; data: { object: unknown } };

    // Stub dispatcher. The full implementation enqueues an Inngest event so
    // payment side effects (mark koti paid, advance ship pipeline) stay async.
    switch (event.type) {
      case "payment_intent.succeeded":
      case "checkout.session.completed":
      case "charge.refunded":
        return NextResponse.json({ received: true });
      default:
        return NextResponse.json({ received: true, ignored: true });
    }
  } catch (err) {
    return handleError(err);
  }
}
