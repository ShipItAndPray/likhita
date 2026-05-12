import { beforeEach, describe, expect, it } from "vitest";
import { GET } from "@/app/api/v1/shared/koti/route";
import { POST } from "@/app/api/v1/shared/entries/route";

function getReq(headers: Record<string, string> = {}) {
  return new Request("http://localhost/api/v1/shared/koti", {
    method: "GET",
    headers: { "X-App-Origin": "likhita-rama", ...headers },
  }) as unknown as Parameters<typeof GET>[0];
}

function postReq(body: unknown, headers: Record<string, string> = {}) {
  return new Request("http://localhost/api/v1/shared/entries", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "X-App-Origin": "likhita-rama",
      ...headers,
    },
    body: JSON.stringify(body),
  }) as unknown as Parameters<typeof POST>[0];
}

function batchBody(count: number) {
  const now = new Date();
  const first = new Date(now.getTime() - count * 1000);
  return {
    count,
    committedFirstAt: first.toISOString(),
    committedLastAt: now.toISOString(),
  };
}

beforeEach(() => {
  // Reset the in-memory shared store between tests so counts don't bleed.
  const g = globalThis as unknown as { __likhitaSharedMem?: unknown };
  g.__likhitaSharedMem = undefined;
});

describe("GET /v1/shared/koti", () => {
  it("returns the foundation koti snapshot with zero writers initially", async () => {
    const res = await GET(getReq());
    expect(res.status).toBe(200);
    const body = (await res.json()) as {
      koti: { name: string; targetCount: number; currentCount: number };
      uniqueWriters: number;
      countriesActive: number;
      recentWriters: unknown[];
      topWriters: unknown[];
      countries: unknown[];
    };
    expect(body.koti.name).toBe("The Foundation Koti");
    expect(body.koti.targetCount).toBe(10_000_000);
    expect(body.koti.currentCount).toBe(0);
    expect(body.uniqueWriters).toBe(0);
    expect(body.recentWriters).toHaveLength(0);
  });

  it("rejects when X-App-Origin is missing", async () => {
    const res = await GET(getReq({ "X-App-Origin": "" }));
    expect(res.status).toBe(400);
  });
});

describe("POST /v1/shared/entries", () => {
  it("appends a batch and bumps the live count by `count`", async () => {
    const res = await POST(
      postReq({
        deviceId: "device-test-001",
        displayName: "Anon Tester",
        place: "Bengaluru",
        country: "India",
        ...batchBody(2),
      }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { acceptedHere: number; currentCount: number };
    expect(body.acceptedHere).toBe(2);
    expect(body.currentCount).toBe(2);

    // Subsequent GET reflects the new count + unique writer
    const get = await GET(getReq());
    const snap = (await get.json()) as {
      koti: { currentCount: number };
      uniqueWriters: number;
      topWriters: { name: string; count: number }[];
    };
    expect(snap.koti.currentCount).toBe(2);
    expect(snap.uniqueWriters).toBe(1);
    expect(snap.topWriters[0]?.count).toBe(2);
  });

  it("accepts batches from multiple devices and counts unique writers", async () => {
    for (let i = 0; i < 3; i += 1) {
      const r = await POST(
        postReq({
          deviceId: `device-${i}`,
          displayName: `Devotee ${i}`,
          country: i === 0 ? "India" : "United States",
          ...batchBody(1),
        }),
      );
      expect(r.status).toBe(200);
    }
    const get = await GET(getReq());
    const snap = (await get.json()) as { koti: { currentCount: number }; uniqueWriters: number; countriesActive: number };
    expect(snap.koti.currentCount).toBe(3);
    expect(snap.uniqueWriters).toBe(3);
    expect(snap.countriesActive).toBe(2);
  });

  it("rejects count > 1008 (Nitya cap)", async () => {
    const res = await POST(
      postReq({
        deviceId: "device-overflow",
        ...batchBody(1009),
      }),
    );
    expect([400, 422, 500]).toContain(res.status);
  });

  it("validates malformed body", async () => {
    const res = await POST(
      postReq({
        deviceId: "x", // too short
        ...batchBody(1),
      }),
    );
    expect(res.status).toBe(400);
  });

  it("requires X-App-Origin", async () => {
    const res = await POST(
      postReq(
        { deviceId: "device-no-origin", ...batchBody(1) },
        { "X-App-Origin": "" },
      ),
    );
    expect(res.status).toBe(400);
  });
});
