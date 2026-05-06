import { type NextRequest, NextResponse } from "next/server";
import { handleError, jsonError } from "@/lib/http";
import { verifyRazorpaySignature } from "@/lib/payments";

export const runtime = "nodejs";

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    const secret = process.env.RAZORPAY_WEBHOOK_SECRET;
    if (!secret) return jsonError(500, "misconfigured", "RAZORPAY_WEBHOOK_SECRET not set");

    const raw = await req.text();
    const sig = req.headers.get("x-razorpay-signature");
    if (!verifyRazorpaySignature(raw, sig, secret)) {
      return jsonError(400, "invalid_signature", "Razorpay signature verification failed");
    }

    const event = JSON.parse(raw) as { event: string; payload: unknown };

    switch (event.event) {
      case "payment.captured":
      case "order.paid":
      case "refund.processed":
        return NextResponse.json({ received: true });
      default:
        return NextResponse.json({ received: true, ignored: true });
    }
  } catch (err) {
    return handleError(err);
  }
}
