import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError, jsonError } from "@/lib/http";
import { createKoti, findUserByClerkId, listKotisForUser, upsertUser } from "@/lib/repo";

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

    // Auto-create a stub user on first koti POST so iOS clients don't need
    // to call /v1/auth/sync first. The user enriches their profile later via
    // sync; until then we have a usable UUID foreign key and a placeholder
    // name/email tied to the Clerk identity.
    let user = await findUserByClerkId(auth.clerkId);
    if (!user) {
      user = await upsertUser({
        clerkId: auth.clerkId,
        name: "A devotee",
        email: `${auth.clerkId}@placeholder.likhita.org`,
        appOrigin,
      });
    }
    const userId = user.id;

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
    if (!user) return NextResponse.json({ kotis: [], appOrigin });
    const kotis = await listKotisForUser(user.id, appOrigin);
    return NextResponse.json({ kotis, appOrigin, userId: user.id });
  } catch (err) {
    return handleError(err);
  }
}
