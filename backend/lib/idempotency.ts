import { createHash } from "node:crypto";

// SHA-256 of the canonical JSON body. We compute this server-side so a client
// retrying with a slightly different payload (e.g. additional entries appended)
// is treated as a new request, not a duplicate.
export function hashRequestBody(body: unknown): string {
  const canonical = JSON.stringify(body, Object.keys(body ?? {}).sort());
  return createHash("sha256").update(canonical).digest("hex");
}

export function validateIdempotencyKey(raw: unknown): string {
  if (typeof raw !== "string" || raw.length < 8 || raw.length > 128) {
    throw new Error("Idempotency key must be a string between 8 and 128 chars");
  }
  if (!/^[A-Za-z0-9_-]+$/.test(raw)) {
    throw new Error("Idempotency key must be URL-safe base64 chars only");
  }
  return raw;
}
