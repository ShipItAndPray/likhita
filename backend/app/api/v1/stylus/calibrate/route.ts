import { createHash } from "node:crypto";
import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError } from "@/lib/http";
import { mean, stddev } from "@/lib/anticheat";

export const runtime = "nodejs";

const Body = z.object({
  strokes: z
    .array(
      z.object({
        gaps: z.array(z.number().nonnegative().max(60_000)).min(1).max(64),
        dwells: z.array(z.number().nonnegative().max(2_000)).min(1).max(64),
      }),
    )
    .length(5),
  inkColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
});

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    await requireAuth(req);
    const body = Body.parse(await req.json());

    const allGaps = body.strokes.flatMap((s) => s.gaps);
    const allDwells = body.strokes.flatMap((s) => s.dwells);
    const baseCadenceMs = mean(allGaps);
    const cadenceVarianceMs = stddev(allGaps);
    const dwellMeanMs = mean(allDwells);

    // The signature hash is a stable digest of the rounded cadence/dwell stats.
    // Rounded so minor session-to-session noise doesn't change it; the iOS app
    // resubmits this hash with each koti to bind ink + rhythm together.
    const signatureSource = JSON.stringify({
      cadence: Math.round(baseCadenceMs),
      variance: Math.round(cadenceVarianceMs),
      dwell: Math.round(dwellMeanMs),
      ink: body.inkColor,
    });
    const signatureHash = createHash("sha256").update(signatureSource).digest("hex");

    return NextResponse.json({
      signatureHash,
      baseCadenceMs: Math.round(baseCadenceMs),
      cadenceVarianceMs: Math.round(cadenceVarianceMs),
      dwellMeanMs: Math.round(dwellMeanMs),
    });
  } catch (err) {
    return handleError(err);
  }
}
