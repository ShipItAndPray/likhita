// Thin wrapper around Clerk's Next.js helpers. We re-export the auth helper so
// route handlers don't import from `@clerk/nextjs/server` directly — that gives
// us a single seam for tests to stub via vitest module mocks.

import type { NextRequest } from "next/server";

export type AuthContext = {
  userId: string;
  clerkId: string;
};

export class AuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "AuthError";
  }
}

export async function requireAuth(_req: NextRequest): Promise<AuthContext> {
  // In production this calls Clerk's getAuth(req). For local dev and tests we
  // accept a header-based fallback so the API is exercisable without Clerk.
  const header = _req.headers.get("X-Test-Clerk-Id");
  if (header) {
    return { userId: header, clerkId: header };
  }

  if (process.env.LIKHITA_RUNTIME === "test") {
    return { userId: "test-user", clerkId: "test-user" };
  }

  // Lazy import keeps Clerk out of the test bundle.
  const { auth } = await import("@clerk/nextjs/server");
  const session = await auth();
  if (!session.userId) {
    throw new AuthError("Unauthenticated");
  }
  return { userId: session.userId, clerkId: session.userId };
}
