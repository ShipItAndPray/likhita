import { describe, expect, it } from "vitest";
import { POST } from "@/app/api/v1/kotis/[id]/entries/route";

const KOTI_ID = "abcdefab-cdef-abcd-efab-cdefabcdefab";
const IDEMPOTENCY_KEY = "test-idem-key-zz-yy";

function makeRequest(body: unknown, headers: Record<string, string> = {}) {
  return new Request(`http://localhost/api/v1/kotis/${KOTI_ID}/entries`, {
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

function ctx() {
  return { params: Promise.resolve({ id: KOTI_ID }) };
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
  it("accepts a valid contiguous human-cadence batch", async () => {
    const body = {
      idempotencyKey: IDEMPOTENCY_KEY,
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
      idempotencyKey: IDEMPOTENCY_KEY,
      entries: [entry(1, [10, 12, 9, 11, 10, 12])],
    };
    const res = await POST(makeRequest(body), ctx());
    expect(res.status).toBe(422);
  });

  it("rejects a batch with zero variance (macro)", async () => {
    const body = {
      idempotencyKey: IDEMPOTENCY_KEY,
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
      idempotencyKey: IDEMPOTENCY_KEY,
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
});
