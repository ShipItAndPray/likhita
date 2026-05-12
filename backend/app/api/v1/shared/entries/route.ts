import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { handleError, jsonError } from "@/lib/http";
import { appendSharedBatch } from "@/lib/repo";

export const runtime = "nodejs";

// Optional + nullable: iOS sends explicit null for fields it doesn't have.
const optionalNullableString = (min: number, max: number) =>
  z.union([z.string().min(min).max(max), z.null()]).optional();

// Sangha write batch. One row per POST. No anti-cheat, no rate limit —
// the practice is voluntary devotion. `count` capped at 1008 (Nitya).
const Body = z.object({
  deviceId: z.string().min(4).max(128),
  displayName: optionalNullableString(1, 80),
  place: optionalNullableString(1, 80),
  country: optionalNullableString(2, 80),
  count: z.number().int().positive().max(1008),
  committedFirstAt: z.string().datetime(),
  committedLastAt: z.string().datetime(),
});

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const body = Body.parse(await req.json());

    const result = await appendSharedBatch({
      deviceId: body.deviceId,
      displayName: body.displayName ?? null,
      place: body.place ?? null,
      country: body.country ?? null,
      count: body.count,
      committedFirstAt: body.committedFirstAt,
      committedLastAt: body.committedLastAt,
    });

    if (result.acceptedHere === 0 && result.complete) {
      return jsonError(410, "koti_complete", "The Foundation Koti is complete. No further entries accepted.");
    }

    return NextResponse.json(result);
  } catch (err) {
    return handleError(err);
  }
}
