import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";

export const runtime = "nodejs";

// Apple StoreKit 2 sends a JWS-signed transaction. In production we verify the
// JWS against Apple's published public keys, decode the payload, and check
// bundleId + transactionId. The full pipeline lives in lib/apple.ts in v1.1;
// for now we accept the JWS string and return a stub validation result so the
// mobile clients can wire the flow end-to-end.
const Body = z.object({
  signedTransaction: z.string().min(20),
  productId: z.string().min(1),
});

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    await requireAuth(req);
    const body = Body.parse(await req.json());

    // After the 2026-05-14 merger ([[likhita-merger-decision]]) both
    // traditions ship from a single bundle (`org.likhita.rama`). The legacy
    // `org.likhita.ram` bundle is being pulled from sale but may linger on
    // already-installed devices for a while — accept either bundle until
    // those installs age out. Receipt verification (v1.1, in lib/apple.ts)
    // must accept any bundle id in `expectedBundles`, not exactly one.
    const expectedBundles = [
      process.env.APPLE_BUNDLE_ID_RAMA, // merged app — primary
      process.env.APPLE_BUNDLE_ID_RAM,  // legacy, retiring; accept until uninstalled everywhere
    ].filter((b): b is string => typeof b === "string" && b.length > 0);

    if (expectedBundles.length === 0) {
      return jsonError(500, "misconfigured", "Apple bundle id not configured");
    }

    return NextResponse.json({
      valid: true,
      productId: body.productId,
      appOrigin,
      bundleIds: expectedBundles,
    });
  } catch (err) {
    return handleError(err);
  }
}
