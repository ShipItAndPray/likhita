import { createHmac } from "node:crypto";
import { describe, expect, it } from "vitest";
import { verifyRazorpaySignature, verifyStripeSignature } from "@/lib/payments";

describe("Razorpay signature verification", () => {
  it("accepts a correctly-signed body", () => {
    const secret = "test-razorpay-webhook";
    const body = JSON.stringify({ event: "payment.captured" });
    const sig = createHmac("sha256", secret).update(body).digest("hex");
    expect(verifyRazorpaySignature(body, sig, secret)).toBe(true);
  });

  it("rejects a tampered body", () => {
    const secret = "test-razorpay-webhook";
    const body = JSON.stringify({ event: "payment.captured" });
    const sig = createHmac("sha256", secret).update(body).digest("hex");
    const tampered = JSON.stringify({ event: "refund.processed" });
    expect(verifyRazorpaySignature(tampered, sig, secret)).toBe(false);
  });

  it("rejects a missing signature header", () => {
    expect(verifyRazorpaySignature("body", null, "secret")).toBe(false);
  });
});

describe("Stripe signature verification", () => {
  it("accepts a correctly-signed body within tolerance", () => {
    const secret = "test-stripe-webhook";
    const body = JSON.stringify({ type: "payment_intent.succeeded" });
    const t = Math.floor(Date.now() / 1000);
    const v1 = createHmac("sha256", secret).update(`${t}.${body}`).digest("hex");
    const header = `t=${t},v1=${v1}`;
    expect(verifyStripeSignature(body, header, secret)).toBe(true);
  });

  it("rejects an expired timestamp", () => {
    const secret = "test-stripe-webhook";
    const body = JSON.stringify({ type: "payment_intent.succeeded" });
    const t = Math.floor(Date.now() / 1000) - 10_000;
    const v1 = createHmac("sha256", secret).update(`${t}.${body}`).digest("hex");
    const header = `t=${t},v1=${v1}`;
    expect(verifyStripeSignature(body, header, secret)).toBe(false);
  });

  it("rejects a forged signature", () => {
    const secret = "test-stripe-webhook";
    const body = JSON.stringify({ type: "payment_intent.succeeded" });
    const t = Math.floor(Date.now() / 1000);
    const header = `t=${t},v1=${"0".repeat(64)}`;
    expect(verifyStripeSignature(body, header, secret)).toBe(false);
  });
});
