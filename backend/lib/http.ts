import { NextResponse } from "next/server";
import { ZodError, type ZodIssue } from "zod";
import { AppOriginError } from "./app-origin";
import { AuthError } from "./auth";

export type ApiError = {
  error: string;
  message: string;
  details?: unknown;
};

export function jsonError(
  status: number,
  error: string,
  message: string,
  details?: unknown,
): NextResponse<ApiError> {
  const body: ApiError = { error, message };
  if (details !== undefined) body.details = details;
  return NextResponse.json(body, { status });
}

export function fromZodError(err: ZodError): NextResponse<ApiError> {
  const details: { path: (string | number)[]; message: string }[] = err.issues.map(
    (i: ZodIssue) => ({ path: i.path, message: i.message }),
  );
  return jsonError(400, "validation_error", "Request body failed validation", details);
}

// Standard error envelope. Routes call this in their catch block so we get a
// uniform error shape for the iOS clients. Anything not classified surfaces as
// 500 with a generic message; the underlying error is logged server-side.
export function handleError(err: unknown): NextResponse<ApiError> {
  if (err instanceof ZodError) return fromZodError(err);
  if (err instanceof AppOriginError) {
    return jsonError(400, "invalid_app_origin", err.message);
  }
  if (err instanceof AuthError) {
    return jsonError(401, "unauthenticated", err.message);
  }
  if (err instanceof Error) {
    if (process.env.LIKHITA_RUNTIME !== "production") {
      return jsonError(500, "internal_error", err.message);
    }
  }
  return jsonError(500, "internal_error", "An unexpected error occurred");
}
