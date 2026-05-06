import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError } from "@/lib/http";

export const runtime = "nodejs";

const SyncBody = z.object({
  name: z.string().min(1).max(120),
  email: z.string().email(),
  gotra: z.string().max(120).optional(),
  nativePlace: z.string().max(120).optional(),
  phone: z.string().max(40).optional(),
  uiLanguage: z.enum(["te", "hi", "en"]).optional(),
});

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const body = SyncBody.parse(await req.json());

    // In a full implementation this upserts into `users` keyed on clerkId and
    // appends `appOrigin` to linkedApps. Stubbed here so the route is type-safe
    // and tested without a live DB.
    return NextResponse.json({
      ok: true,
      user: {
        clerkId: auth.clerkId,
        name: body.name,
        email: body.email,
        primaryApp: appOrigin,
      },
    });
  } catch (err) {
    return handleError(err);
  }
}
