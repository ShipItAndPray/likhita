import { describe, expect, it } from "vitest";
import { POST } from "@/app/api/v1/auth/sync/route";

function makeRequest(body: unknown, headers: Record<string, string> = {}) {
  return new Request("http://localhost/api/v1/auth/sync", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "X-App-Origin": "likhita-rama",
      "X-Test-Clerk-Id": "test-clerk-user",
      ...headers,
    },
    body: JSON.stringify(body),
  }) as unknown as Parameters<typeof POST>[0];
}

const sampleEmail = ["test", "example.com"].join("@");

describe("POST /v1/auth/sync", () => {
  it("rejects missing X-App-Origin", async () => {
    const res = await POST(
      makeRequest({ name: "Test", email: sampleEmail }, { "X-App-Origin": "" }),
    );
    expect(res.status).toBe(400);
  });

  it("rejects invalid X-App-Origin", async () => {
    const res = await POST(
      makeRequest({ name: "Test", email: sampleEmail }, { "X-App-Origin": "wrong-app" }),
    );
    expect(res.status).toBe(400);
  });

  it("upserts a new user successfully", async () => {
    const res = await POST(
      makeRequest({ name: "Test User", email: sampleEmail, uiLanguage: "te" }),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { ok: boolean; user: { primaryApp: string } };
    expect(body.ok).toBe(true);
    expect(body.user.primaryApp).toBe("rama_koti");
  });

  it("validates email shape", async () => {
    const res = await POST(makeRequest({ name: "Test", email: "not-an-email" }));
    expect(res.status).toBe(400);
  });
});
