import { describe, expect, it } from "vitest";
import { POST } from "@/app/api/v1/kotis/route";

function makeRequest(body: unknown, headers: Record<string, string> = {}) {
  return new Request("http://localhost/api/v1/kotis", {
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

const validBody = {
  traditionPath: "telugu",
  mantraString: "srirama",
  renderedScript: "telugu",
  mode: "lakh",
  targetCount: 100_000,
  stylusColor: "#E34234",
  stylusSignatureHash: "abcd1234567890ef".repeat(2),
  theme: "bhadrachalam_classic",
  dedicationText: "For my mother",
  dedicationTo: "parent",
};

describe("POST /v1/kotis", () => {
  it("creates a koti for the authenticated user", async () => {
    const res = await POST(makeRequest(validBody));
    expect(res.status).toBe(201);
    const body = (await res.json()) as { koti: { id: string; appOrigin: string } };
    expect(body.koti.appOrigin).toBe("rama_koti");
    expect(body.koti.id).toMatch(/[0-9a-f-]{36}/);
  });

  it("rejects an invalid mantraString for the rama path", async () => {
    const res = await POST(makeRequest({ ...validBody, mantraString: "om" }));
    expect(res.status).toBe(400);
  });

  it("rejects target count of zero", async () => {
    const res = await POST(makeRequest({ ...validBody, targetCount: 0 }));
    expect(res.status).toBe(400);
  });
});
