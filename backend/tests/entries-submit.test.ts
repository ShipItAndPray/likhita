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

function entry(seq: number, gaps: number[]) {
  return {
    sequenceNumber: seq,
    committedAt: new Date().toISOString(),
    cadenceSignature: { gaps },
    clientSessionId: sessionId,
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

  it("accepts a valid contiguous human-cadence batch", async () => {
    const body = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}`,
      entries: [
        entry(1, [180, 220, 195, 240, 175, 200]),
        entry(2, [205, 175, 240, 195, 220, 180]),
        entry(3, [190, 215, 180, 235, 210, 195]),
      ],
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(200);
    const json = (await res.json()) as {
      accepted: number;
      currentCount: number;
    };
    expect(json.accepted).toBe(3);
    expect(json.currentCount).toBe(3);
  });

  it("rejects a batch with sub-30ms inter-key gaps", async () => {
    const body = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-fast`,
      entries: [entry(1, [10, 12, 9, 11, 10, 12])],
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(422);
  });

  it("rejects a batch with zero variance (macro)", async () => {
    const body = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-macro`,
      entries: [
        entry(1, [200, 200, 200, 200]),
        entry(2, [200, 200, 200, 200]),
        entry(3, [200, 200, 200, 200]),
      ],
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(422);
  });

  it("rejects a non-contiguous sequence", async () => {
    const body = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-gap`,
      entries: [
        entry(1, [180, 220, 195, 240, 175, 200]),
        entry(3, [205, 175, 240, 195, 220, 180]),
      ],
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(409);
  });

  it("rejects malformed idempotency key", async () => {
    const body = {
      idempotencyKey: "short",
      entries: [entry(1, [180, 220, 195, 240, 175, 200])],
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(500);
  });

  it("is monotonic: cannot replay entries to go backward", async () => {
    const key1 = `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-mono-a`;
    const body1 = {
      idempotencyKey: key1,
      entries: [entry(1, [180, 220, 195, 240, 175, 200])],
    };
    const r1 = await POST(makeRequest(body1), ctx());
    expect(r1.status).toBe(200);
    const j1 = (await r1.json()) as { currentCount: number };
    expect(j1.currentCount).toBe(1);

    // Try to submit sequenceNumber 1 again with a fresh idempotency key.
    // Server must reject — count is at 1 so expected next is 2.
    const body2 = {
      idempotencyKey: `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-mono-b`,
      entries: [entry(1, [180, 220, 195, 240, 175, 200])],
    };
    const r2 = await POST(makeRequest(body2), ctx());
    expect(r2.status).toBe(409);
  });

  it("idempotency: same key + same body returns the same response", async () => {
    const key = `${IDEMPOTENCY_KEY_BASE}-${Date.now()}-idem`;
    const body = {
      idempotencyKey: key,
      entries: [entry(1, [180, 220, 195, 240, 175, 200])],
    };
    const r1 = await POST(makeRequest(body), ctx());
    expect(r1.status).toBe(200);
    const j1 = (await r1.json()) as { currentCount: number };

    // Replay — must return 200 with same cached result, not bump count.
    const r2 = await POST(makeRequest(body), ctx());
    expect(r2.status).toBe(200);
    const j2 = (await r2.json()) as { currentCount: number };
    expect(j2.currentCount).toBe(j1.currentCount);
  });
});
