import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { handleError, jsonError } from "@/lib/http";
import { appendSharedBatch } from "@/lib/repo";

export const runtime = "nodejs";

// Optional + nullable: iOS sends explicit null for fields it doesn't have.
const optionalNullableString = (min: number, max: number) =>
  z.union([z.string().min(min).max(max), z.null()]).optional();

// Sangha write batch. `date` = user's local YYYY-MM-DD. UPSERT keyed on
// (shared_koti_id, device_id, date). Same-day sessions collapse into
// one row, so the table grows at most 1 row per devotee per day.
const Body = z.object({
  deviceId: z.string().min(4).max(128),
  displayName: optionalNullableString(1, 80),
  place: optionalNullableString(1, 80),
  country: optionalNullableString(2, 80),
  count: z.number().int().positive().max(1008),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "expected YYYY-MM-DD"),
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
      date: body.date,
    });

    if (result.acceptedHere === 0 && result.complete) {
      return jsonError(410, "koti_complete", "The Foundation Koti is complete. No further entries accepted.");
    }

    return NextResponse.json(result);
  } catch (err) {
    return handleError(err);
  }
}
