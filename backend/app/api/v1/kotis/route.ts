import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { createKoti, findUserByClerkId, listKotisForUser } from "@/lib/repo";

export const runtime = "nodejs";

const CreateKotiBody = z.object({
  traditionPath: z.enum(["telugu", "hindi_ram", "hindi_sitaram"]),
  mantraString: z.enum(["srirama", "ram", "sitaram"]),
  renderedScript: z.enum(["telugu", "devanagari"]),
  mode: z.enum(["trial", "lakh", "crore", "ten_lakh", "fifty_lakh", "custom"]),
  targetCount: z.number().int().positive(),
  stylusColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  stylusSignatureHash: z.string().min(16).max(256),
  theme: z.string(),
  dedicationText: z.string().max(280),
  dedicationTo: z.enum(["self", "parent", "child", "departed", "deity", "community"]),
});

// Fail fast if a Telugu app submits with a non-srirama mantra (or vice versa).
function validateTraditionMantraMatch(traditionPath: string, mantraString: string): boolean {
  if (traditionPath === "telugu") return mantraString === "srirama";
  if (traditionPath === "hindi_ram") return mantraString === "ram";
  if (traditionPath === "hindi_sitaram") return mantraString === "sitaram";
  return false;
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const body = CreateKotiBody.parse(await req.json());

    if (!validateTraditionMantraMatch(body.traditionPath, body.mantraString)) {
      return jsonError(
        400,
        "tradition_mantra_mismatch",
        "mantraString does not match traditionPath",
      );
    }

    const user = await findUserByClerkId(auth.clerkId);
    const userId = user?.id ?? auth.clerkId;

    const koti = await createKoti({
      userId,
      appOrigin,
      traditionPath: body.traditionPath,
      mantraString: body.mantraString,
      renderedScript: body.renderedScript,
      mode: body.mode,
      targetCount: body.targetCount,
      stylusColor: body.stylusColor,
      stylusSignatureHash: body.stylusSignatureHash,
      theme: body.theme,
      dedicationText: body.dedicationText,
      dedicationTo: body.dedicationTo,
    });

    return NextResponse.json({ koti: { ...koti, appOrigin } }, { status: 201 });
  } catch (err) {
    return handleError(err);
  }
}

export async function GET(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const user = await findUserByClerkId(auth.clerkId);
    const userId = user?.id ?? auth.clerkId;
    const kotis = await listKotisForUser(userId, appOrigin);
    return NextResponse.json({ kotis, appOrigin, userId });
  } catch (err) {
    return handleError(err);
  }
}
