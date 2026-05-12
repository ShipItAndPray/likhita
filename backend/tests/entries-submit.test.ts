import { beforeEach, describe, expect, it } from "vitest";
import { POST } from "@/app/api/v1/kotis/[id]/entries/route";
import { createKoti, upsertUser } from "@/lib/repo";

const IDEMPOTENCY_KEY_BASE = "test-idem-key-zz-yy";
const SAMPLE_EMAIL = ["test", "example.com"].join("@");

let kotiId: string;

function makeRequest(body: unknown, headers: Record<string, string> = {}, kid: string = kotiId) {
  return new Request(`http://localhost/api/v1/kotis/${kid}/entries`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "X-App-Origin": "likhita-rama",
      "X-Test-Clerk-Id": "test-user",
      ...headers,
    },
    body: JSON.stringify(body),
  }) as unknown as Parameters<typeof POST>[0];
}

function ctx(kid: string = kotiId) {
  return { params: Promise.resolve({ id: kid }) };
}

const sessionId = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

function batch(count: number) {
  const now = new Date();
  const start = new Date(now.getTime() - count * 1000);
  return {
    count,
    clientSessionId: sessionId,
    committedFirstAt: start.toISOString(),
    committedLastAt: now.toISOString(),
  };
}

describe("POST /v1/kotis/:id/entries", () => {
  beforeEach(async () => {
    await upsertUser({
      clerkId: "test-user",
      name: "Test User",
      email: SAMPLE_EMAIL,
      appOrigin: "rama_koti",
    });
    const koti = await createKoti({
      userId: "test-user",
      appOrigin: "rama_koti",
      traditionPath: "telugu",
      mantraString: "srirama",
      renderedScript: "telugu",
      mode: "lakh",
      targetCount: 100_000,
      stylusColor: "#E34234",
      stylusSignatureHash: "abcd1234567890ef".repeat(2),
      theme: "bhadrachalam_classic",
      dedicationText: "test",
      dedicationTo: "self",
    });
    kotiId = koti.id;
  });

  it("accepts a batch summary and bumps current_count by `count`", async () => {
    const body = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}`,
      ...batch(3),
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(200);
    const json = (await res.json()) as { accepted: number; currentCount: number };
    expect(json.accepted).toBe(3);
    expect(json.currentCount).toBe(3);
  });

  it("rejects a batch with count > 1008 (Nitya cap)", async () => {
    const body = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-over`,
      ...batch(1009),
    };
    const res = await POST(makeRequest(body), ctx());
    // Zod validation failure surfaces as 500 (caught by handleError).
    expect([400, 422, 500]).toContain(res.status);
  });

  it("rejects malformed idempotency key", async () => {
    const body = {
      idempotencyKey: "short",
      ...batch(1),
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(500);
  });

  it("is monotonic: a second batch goes on top of the first", async () => {
    const r1 = await POST(makeRequest({ idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-a`, ...batch(5) }), ctx());
    expect(r1.status).toBe(200);
    const j1 = (await r1.json()) as { currentCount: number };
    expect(j1.currentCount).toBe(5);

    const r2 = await POST(makeRequest({ idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-b`, ...batch(3) }), ctx());
    expect(r2.status).toBe(200);
    const j2 = (await r2.json()) as { currentCount: number };
    expect(j2.currentCount).toBe(8);
  });

  it("idempotency: same key + same body returns the same response", async () => {
    const key = `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-idem`;
    const body = { idempotencyKey: key, ...batch(1) };
    const r1 = await POST(makeRequest(body), ctx());
    expect(r1.status).toBe(200);
    const j1 = (await r1.json()) as { currentCount: number };

    // Replay — must return 200 with same cached result, not bump count.
    const r2 = await POST(makeRequest(body), ctx());
    expect(r2.status).toBe(200);
    const j2 = (await r2.json()) as { currentCount: number };
    expect(j2.currentCount).toBe(j1.currentCount);
  });

  it("caps acceptance at target_count and returns complete=true", async () => {
    // Target is 100,000 — submit a chain of large-ish batches to approach it.
    // Easier: create a fresh koti with a tiny target.
    const small = await createKoti({
      userId: "test-user",
      appOrigin: "rama_koti",
      traditionPath: "telugu",
      mantraString: "srirama",
      renderedScript: "telugu",
      mode: "lakh",
      targetCount: 10,
      stylusColor: "#E34234",
      stylusSignatureHash: "abcd1234567890ef".repeat(2),
      theme: "bhadrachalam_classic",
      dedicationText: "test",
      dedicationTo: "self",
    });
    const body = { idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-cap-${Date.now()}`, ...batch(50) };
    const res = await POST(makeRequest(body, {}, small.id), ctx(small.id));
    expect(res.status).toBe(200);
    const json = (await res.json()) as { accepted: number; currentCount: number; complete: boolean };
    expect(json.accepted).toBe(10);
    expect(json.currentCount).toBe(10);
    expect(json.complete).toBe(true);
  });
});
