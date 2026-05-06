import { type NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { randomUUID } from "node:crypto";
import { readAppOrigin } from "@/lib/app-origin";
import { requireAuth } from "@/lib/auth";
import { handleError } from "@/lib/http";

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

export async function POST(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    const body = CreateKotiBody.parse(await req.json());

    return NextResponse.json(
      {
        koti: {
          id: randomUUID(),
          userId: auth.userId,
          appOrigin,
          ...body,
          currentCount: 0,
          locked: true,
          startedAt: new Date().toISOString(),
        },
      },
      { status: 201 },
    );
  } catch (err) {
    return handleError(err);
  }
}

export async function GET(req: NextRequest): Promise<NextResponse> {
  try {
    const appOrigin = readAppOrigin(req.headers);
    const auth = await requireAuth(req);
    return NextResponse.json({ kotis: [], appOrigin, userId: auth.userId });
  } catch (err) {
    return handleError(err);
  }
}
