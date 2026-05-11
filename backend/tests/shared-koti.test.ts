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

function entry(gaps: number[]) {
  return {
    committedAt: new Date().toISOString(),
    cadenceSignature: { gaps },
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
  it("appends entries and bumps the live count", async () => {
    const res = await POST(
      postReq({
        deviceId: "device-test-001",
        displayName: "Anon Tester",
        place: "Bengaluru",
        country: "India",
        entries: [
          entry([180, 220, 195, 240, 175, 200]),
          entry([205, 175, 240, 195, 220, 180]),
        ],
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

  it("rejects a macro batch (zero variance) before appending", async () => {
    const res = await POST(
      postReq({
        deviceId: "device-macro",
        entries: [
          entry([200, 200, 200, 200]),
          entry([200, 200, 200, 200]),
        ],
      }),
    );
    expect(res.status).toBe(422);
    const get = await GET(getReq());
    const snap = (await get.json()) as { koti: { currentCount: number } };
    expect(snap.koti.currentCount).toBe(0);
  });

  it("rejects sub-30ms inter-key gaps (hold-key macro)", async () => {
    const res = await POST(
      postReq({
        deviceId: "device-fast",
        entries: [entry([10, 12, 9, 11, 8, 10])],
      }),
    );
    expect(res.status).toBe(422);
  });

  it("accepts batches from multiple devices and counts unique writers", async () => {
    for (let i = 0; i < 3; i += 1) {
      const r = await POST(
        postReq({
          deviceId: `device-${i}`,
          displayName: `Devotee ${i}`,
          country: i === 0 ? "India" : "United States",
          entries: [entry([180, 220, 195, 240, 175, 200])],
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

  it("validates malformed body", async () => {
    const res = await POST(
      postReq({
        deviceId: "x", // too short
        entries: [entry([180, 220, 195])],
      }),
    );
    expect(res.status).toBe(400);
  });

  it("requires X-App-Origin", async () => {
    const res = await POST(
      postReq(
        { deviceId: "device-no-origin", entries: [entry([180, 220, 195])] },
        { "X-App-Origin": "" },
      ),
    );
    expect(res.status).toBe(400);
  });
});
