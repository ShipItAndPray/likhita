import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError } from "@/lib/http";
import { upsertUser } from "@/lib/repo";

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

    const user = await upsertUser({
      clerkId: auth.clerkId,
      name: body.name,
      email: body.email,
      gotra: body.gotra,
      nativePlace: body.nativePlace,
      phone: body.phone,
      uiLanguage: body.uiLanguage,
      appOrigin,
    });

    return NextResponse.json({
      ok: true,
      user: {
        id: user.id,
        clerkId: user.clerkId,
        name: user.name,
        email: user.email,
        primaryApp: user.primaryApp ?? appOrigin,
        linkedApps: user.linkedApps,
      },
    });
  } catch (err) {
    return handleError(err);
  }
}
