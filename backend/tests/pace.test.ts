import { beforeEach, describe, expect, it } from "vitest";
import { GET as getCalendar } from "@/app/api/v1/kotis/[id]/calendar/route";
import { PATCH as patchPace } from "@/app/api/v1/kotis/[id]/pace/route";
import { POST as postEntries } from "@/app/api/v1/kotis/[id]/entries/route";
import { GET as getKoti } from "@/app/api/v1/kotis/[id]/route";
import { createKoti, upsertUser } from "@/lib/repo";

const EMAIL = ["pace-test", "example.com"].join("@");
const TEST_SESSION = "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee";

let kotiId: string;

function req(url: string, init: RequestInit = {}) {
  return new Request(url, {
    headers: {
      "content-type": "application/json",
      "X-App-Origin": "likhita-rama",
      "X-Test-Clerk-Id": "pace-user",
      ...(init.headers as Record<string, string> | undefined),
    },
    ...init,
  }) as unknown as Parameters<typeof getCalendar>[0];
}

function ctx() { return { params: Promise.resolve({ id: kotiId }) }; }

describe("Pace endpoints", () => {
  beforeEach(async () => {
    await upsertUser({ clerkId: "pace-user", name: "Pace User", email: EMAIL, appOrigin: "rama_koti" });
    const koti = await createKoti({
      userId: "pace-user", appOrigin: "rama_koti", traditionPath: "telugu",
      mantraString: "srirama", renderedScript: "telugu", mode: "lakh", targetCount: 100_000,
      stylusColor: "#E34234", stylusSignatureHash: "a".repeat(32),
      theme: "bhadrachalam_classic", dedicationText: "test", dedicationTo: "self",
    });
    kotiId = koti.id;
  });

  it("GET /kotis/:id returns the default goalDays + reminderTimes", async () => {
    const res = await getKoti(req(`http://localhost/api/v1/kotis/${kotiId}`), ctx());
    expect(res.status).toBe(200);
    const body = (await res.json()) as { koti: { goalDays: number; reminderTimes: string[] } };
    expect(body.koti.goalDays).toBe(365);
    expect(body.koti.reminderTimes).toEqual(["pratah", "sandhya"]);
  });

  it("PATCH /pace updates goalDays + reminderTimes", async () => {
    const res = await patchPace(
      req(`http://localhost/api/v1/kotis/${kotiId}/pace`, {
        method: "PATCH",
        body: JSON.stringify({ goalDays: 90, reminderTimes: ["brahma", "pratah", "sandhya"] }),
      }),
      ctx(),
    );
    expect(res.status).toBe(200);
    const body = (await res.json()) as { goalDays: number; reminderTimes: string[] };
    expect(body.goalDays).toBe(90);
    expect(body.reminderTimes).toEqual(["brahma", "pratah", "sandhya"]);
  });

  it("PATCH /pace rejects goalDays out of range", async () => {
    const res = await patchPace(
      req(`http://localhost/api/v1/kotis/${kotiId}/pace`, {
        method: "PATCH",
        body: JSON.stringify({ goalDays: 20 }),
      }),
      ctx(),
    );
    expect([400, 500]).toContain(res.status);
  });

  it("PATCH /pace rejects >3 reminder slots", async () => {
    const res = await patchPace(
      req(`http://localhost/api/v1/kotis/${kotiId}/pace`, {
        method: "PATCH",
        body: JSON.stringify({ reminderTimes: ["brahma", "pratah", "madhyana", "sandhya"] }),
      }),
      ctx(),
    );
    expect([400, 500]).toContain(res.status);
  });

  it("GET /calendar returns daily totals for the koti", async () => {
    const today = new Date().toISOString().slice(0, 10);
    for (let i = 0; i < 3; i += 1) {
      const body = {
        idempotencyKey: `test-pace-${i}-${Date.now()}`,
        count: 10,
        clientSessionId: TEST_SESSION,
        date: today,
      };
      const r = await postEntries(
        req(`http://localhost/api/v1/kotis/${kotiId}/entries`, { method: "POST", body: JSON.stringify(body) }),
        ctx(),
      );
      expect(r.status).toBe(200);
    }
    const res = await getCalendar(req(`http://localhost/api/v1/kotis/${kotiId}/calendar?days=30`), ctx());
    expect(res.status).toBe(200);
    const body = (await res.json()) as { days: number; daily: { date: string; count: number }[] };
    expect(body.days).toBe(30);
    expect(body.daily.length).toBe(1);
    expect(body.daily[0]?.count).toBe(30);
  });
});
