import { createHmac, timingSafeEqual } from "node:crypto";

// Razorpay signature verification: HMAC-SHA256(body, webhook_secret) compared
// to the X-Razorpay-Signature header. See https://razorpay.com/docs/webhooks/.
export function verifyRazorpaySignature(
  rawBody: string,
  signature: string | null,
  secret: string,
): boolean {
  if (!signature) return false;
  const expected = createHmac("sha256", secret).update(rawBody).digest("hex");
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(signature, "hex");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}

// Stripe-style signature verification kept simple for the stub — production
// uses stripe.webhooks.constructEvent which handles timestamp tolerance and
// scheme parsing. We mimic the structure so the route can swap implementations
// without changing the call site.
export function verifyStripeSignature(
  rawBody: string,
  signatureHeader: string | null,
  secret: string,
  toleranceSeconds: number = 300,
): boolean {
  if (!signatureHeader) return false;
  const parts = Object.fromEntries(
    signatureHeader.split(",").map((p) => {
      const [k, v] = p.split("=");
      return [k ?? "", v ?? ""];
    }),
  );
  const t = parts["t"];
  const v1 = parts["v1"];
  if (!t || !v1) return false;
  const ageSec = Math.abs(Math.floor(Date.now() / 1000) - Number(t));
  if (Number.isNaN(ageSec) || ageSec > toleranceSeconds) return false;
  const signed = `${t}.${rawBody}`;
  const expected = createHmac("sha256", secret).update(signed).digest("hex");
  const a = Buffer.from(expected, "hex");
  const b = Buffer.from(v1, "hex");
  if (a.length !== b.length) return false;
  return timingSafeEqual(a, b);
}
