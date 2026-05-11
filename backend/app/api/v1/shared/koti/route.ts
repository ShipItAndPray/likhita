import { type NextRequest, NextResponse } from "next/server";
import { readAppOrigin } from "@/lib/app-origin";
import { handleError } from "@/lib/http";
import { getSharedHubSnapshot } from "@/lib/repo";

export const runtime = "nodejs";

// GET /api/v1/shared/koti — public, no auth. Returns the live Foundation
// Koti snapshot (count, unique writers, country breakdown, recent ticker,
// leaderboard) from the `likhita.shared_kotis` + `likhita.shared_entries`
// tables. All aggregates are computed at read time — small enough volume
// that materialized views would be premature.

export async function GET(req: NextRequest): Promise<NextResponse> {
  try {
    readAppOrigin(req.headers);
    const snapshot = await getSharedHubSnapshot();
    return NextResponse.json(snapshot);
  } catch (err) {
    return handleError(err);
  }
}
