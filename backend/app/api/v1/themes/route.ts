import { type NextRequest, NextResponse } from "next/server";
import { readAppOrigin } from "@/lib/app-origin";
import { handleError } from "@/lib/http";
import { listThemesFor } from "@/lib/themes";

export const runtime = "nodejs";

export async function GET(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    const themes = listThemesFor(appOrigin);
    return NextResponse.json(
      { themes, appOrigin },
      { headers: { "Cache-Control": "public, max-age=300, stale-while-revalidate=86400" } },
    );
  } catch (err) {
    return handleError(err);
  }
}
