import { describe, expect, it } from "vitest";
import {
  auditBatch,
  auditEntry,
  cadenceFingerprint,
  checkSequenceContinuity,
  isRateLimited,
  mean,
  stddev,
} from "@/lib/anticheat";

describe("anticheat: math primitives", () => {
  it("computes mean and stddev correctly", () => {
    expect(mean([100, 200, 300])).toBe(200);
    expect(stddev([100, 200, 300])).toBeCloseTo(100, 5);
  });
});

describe("anticheat: per-entry audit", () => {
  it("does not flag a healthy human-typed entry", () => {
    const result = auditEntry(
      {
        sequenceNumber: 1,
        committedAt: Date.now(),
        cadence: { gaps: [180, 220, 195, 240, 175, 200] },
      },
      180,
    );
    expect(result.flagged).toBe(false);
    expect(result.reasons).toEqual([]);
  });

  it("flags an entry with sub-30ms inter-key gaps", () => {
    const result = auditEntry(
      {
        sequenceNumber: 1,
        committedAt: Date.now(),
        cadence: { gaps: [10, 12, 9, 11, 10, 12] },
      },
      180,
    );
    expect(result.reasons).toContain("inter_key_gap_too_low");
  });

  it("flags signature drift when mean cadence diverges from baseline", () => {
    const result = auditEntry(
      {
        sequenceNumber: 1,
        committedAt: Date.now(),
        cadence: { gaps: [600, 620, 590, 610, 605, 595] },
      },
      180,
    );
    expect(result.reasons).toContain("signature_drift");
  });
});

describe("anticheat: batch audit", () => {
  it("rejects a batch with effectively zero variance (macro)", () => {
    const result = auditBatch({
      entries: [
        { sequenceNumber: 1, committedAt: 0, cadence: { gaps: [200, 200, 200, 200] } },
        { sequenceNumber: 2, committedAt: 0, cadence: { gaps: [200, 200, 200, 200] } },
      ],
      baselineCadenceMs: 200,
      baselineVarianceMs: 50,
      recentCadenceFingerprints: [],
    });
    expect(result.reject).toBe(true);
    expect(result.rejectReason).toBe("cadence_variance_too_low");
  });

  it("rejects a batch with hold-key gaps below floor", () => {
    const result = auditBatch({
      entries: [
        {
          sequenceNumber: 1,
          committedAt: 0,
          cadence: { gaps: [180, 5, 200, 220, 190, 175] },
        },
      ],
      baselineCadenceMs: 200,
      baselineVarianceMs: 50,
      recentCadenceFingerprints: [],
    });
    expect(result.reject).toBe(true);
    expect(result.rejectReason).toBe("inter_key_gap_too_low");
  });

  it("accepts a normal human batch", () => {
    const result = auditBatch({
      entries: [
        { sequenceNumber: 1, committedAt: 0, cadence: { gaps: [180, 220, 195, 240, 175, 200] } },
        { sequenceNumber: 2, committedAt: 0, cadence: { gaps: [205, 175, 240, 195, 220, 180] } },
      ],
      baselineCadenceMs: 200,
      baselineVarianceMs: 50,
      recentCadenceFingerprints: [],
    });
    expect(result.reject).toBe(false);
    expect(result.rejectReason).toBe(null);
  });

  it("flags potential macro replay after lookback fingerprint repeats", () => {
    const gaps = [180, 220, 195, 240, 175, 200];
    const fp = cadenceFingerprint(gaps);
    const recent = Array.from({ length: 9 }, () => fp);
    const result = auditBatch({
      entries: [{ sequenceNumber: 1, committedAt: 0, cadence: { gaps } }],
      baselineCadenceMs: 200,
      baselineVarianceMs: 50,
      recentCadenceFingerprints: recent,
    });
    expect(result.reject).toBe(false);
    expect(result.macroLockoutSuggested).toBe(true);
  });
});

describe("anticheat: rate limiting and continuity", () => {
  it("rate-limits when 4 commits land in 1s", () => {
    const now = 10_000;
    const recent = [9_400, 9_600, 9_700, 9_900];
    expect(isRateLimited(recent, now)).toBe(true);
  });

  it("does not rate-limit sparse commits", () => {
    const now = 10_000;
    const recent = [5_000, 7_000, 9_000];
    expect(isRateLimited(recent, now)).toBe(false);
  });

  it("accepts a contiguous sequence", () => {
    expect(checkSequenceContinuity([5, 6, 7, 8], 5)).toEqual({ ok: true });
  });

  it("rejects a sequence with a gap", () => {
    const r = checkSequenceContinuity([5, 6, 8], 5);
    expect(r.ok).toBe(false);
  });
});
