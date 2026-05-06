// Anti-cheat algorithms for entry submission. See SPEC §7.
//
// The contract: clients send a small batch of entries (5-25). Each entry carries
// a `cadence_signature` — an ordered list of inter-keystroke gaps (ms) collected
// on-device. The server cannot trust the client, so it inspects the cadence
// distribution and enforces three rules:
//
//   1. Cadence entropy — humans don't type at perfectly uniform intervals. If
//      stddev across a batch is below CADENCE_VARIANCE_FLOOR_MS, it's a macro.
//      Real human typing at ~200ms cadence shows ~20–80ms stddev across an
//      entire batch; the floor is set conservatively at 10ms so only true
//      zero-jitter macros are rejected. Single entries below this floor are
//      *flagged* per-entry rather than reject the whole batch.
//   2. Hold-key suppression — a single held key on iOS would emit gaps near
//      zero. Any gap below INTER_KEY_FLOOR_MS within an entry is suspect.
//   3. Signature drift — once a stylus is calibrated, the user's mean cadence
//      should stay within DRIFT_TOLERANCE_RATIO of the calibration baseline.
//      Sustained drift suggests another person is writing on the device.
//
// The system is deliberately soft: we *flag* entries instead of rejecting them
// outright. Hard rejection only happens for the entropy and inter-key floors,
// where the signal is unambiguous (no human types at <30ms gaps consistently).

export const CADENCE_VARIANCE_FLOOR_MS = 10;
export const INTER_KEY_FLOOR_MS = 30;
export const DRIFT_TOLERANCE_RATIO = 0.6;
export const MACRO_PATTERN_LOOKBACK = 10;
export const RATE_LIMIT_PER_USER_PER_SEC = 4;

export type CadenceSample = {
  // Inter-key gaps in ms, length = mantra_string.length - 1. Order matters.
  gaps: number[];
};

export type EntryAuditInput = {
  sequenceNumber: number;
  cadence: CadenceSample;
  committedAt: number;
};

export type EntryAuditResult = {
  sequenceNumber: number;
  flagged: boolean;
  reasons: AuditReason[];
};

export type BatchAuditInput = {
  entries: EntryAuditInput[];
  baselineCadenceMs: number | null;
  baselineVarianceMs: number | null;
  recentCadenceFingerprints: string[];
};

export type BatchAuditResult = {
  // True if the entire batch must be rejected (hard violation).
  reject: boolean;
  rejectReason: AuditReason | null;
  // Per-entry soft flags. A flagged entry is still accepted but marked for review.
  perEntry: EntryAuditResult[];
  // True if the cadence pattern of this batch matches recent history closely
  // enough to suggest macro replay.
  macroLockoutSuggested: boolean;
};

export type AuditReason =
  | "cadence_variance_too_low"
  | "inter_key_gap_too_low"
  | "signature_drift"
  | "macro_pattern_repeat"
  | "rate_limit_exceeded"
  | "sequence_discontinuity";

export function mean(values: readonly number[]): number {
  if (values.length === 0) return 0;
  let sum = 0;
  for (const v of values) sum += v;
  return sum / values.length;
}

export function stddev(values: readonly number[]): number {
  if (values.length < 2) return 0;
  const m = mean(values);
  let acc = 0;
  for (const v of values) acc += (v - m) ** 2;
  return Math.sqrt(acc / (values.length - 1));
}

// A coarse cadence fingerprint: bucket each gap into 25ms bins and join.
// Two batches sharing a fingerprint are statistically similar; ten in a row
// matching is the macro-replay signal called out in SPEC §7.
export function cadenceFingerprint(gaps: readonly number[]): string {
  return gaps.map((g) => Math.floor(Math.max(0, g) / 25)).join("-");
}

export function auditEntry(
  input: EntryAuditInput,
  baselineCadenceMs: number | null,
): EntryAuditResult {
  const reasons: AuditReason[] = [];
  const { gaps } = input.cadence;

  if (gaps.some((g) => g < INTER_KEY_FLOOR_MS)) {
    reasons.push("inter_key_gap_too_low");
  }

  if (baselineCadenceMs !== null && gaps.length > 0) {
    const observed = mean(gaps);
    const ratio = Math.abs(observed - baselineCadenceMs) / baselineCadenceMs;
    if (ratio > DRIFT_TOLERANCE_RATIO) {
      reasons.push("signature_drift");
    }
  }

  return {
    sequenceNumber: input.sequenceNumber,
    flagged: reasons.length > 0,
    reasons,
  };
}

export function auditBatch(input: BatchAuditInput): BatchAuditResult {
  const perEntry = input.entries.map((e) =>
    auditEntry(e, input.baselineCadenceMs),
  );

  // Cross-entry cadence variance: pool every gap across the batch.
  const allGaps = input.entries.flatMap((e) => e.cadence.gaps);
  const variance = stddev(allGaps);
  if (allGaps.length >= 4 && variance < CADENCE_VARIANCE_FLOOR_MS) {
    return {
      reject: true,
      rejectReason: "cadence_variance_too_low",
      perEntry,
      macroLockoutSuggested: false,
    };
  }

  // Hard floor: if any entry has a sub-30ms inter-key gap, reject the batch.
  // Soft per-entry flags above will already note this; we promote it to hard
  // rejection because hold-key/macro is the most common cheat vector.
  const hasFloorViolation = input.entries.some((e) =>
    e.cadence.gaps.some((g) => g < INTER_KEY_FLOOR_MS),
  );
  if (hasFloorViolation) {
    return {
      reject: true,
      rejectReason: "inter_key_gap_too_low",
      perEntry,
      macroLockoutSuggested: false,
    };
  }

  const fp = cadenceFingerprint(allGaps);
  const repeats = input.recentCadenceFingerprints.filter((f) => f === fp).length;
  const macroLockoutSuggested = repeats + 1 >= MACRO_PATTERN_LOOKBACK;

  return {
    reject: false,
    rejectReason: null,
    perEntry,
    macroLockoutSuggested,
  };
}

// Pure rate-limit check. Caller supplies recent commit timestamps (ms epoch);
// we count how many fall within the last 1000ms window relative to `nowMs`.
export function isRateLimited(
  recentCommitsMs: readonly number[],
  nowMs: number,
  perSec: number = RATE_LIMIT_PER_USER_PER_SEC,
): boolean {
  const windowStart = nowMs - 1000;
  let count = 0;
  for (const t of recentCommitsMs) if (t >= windowStart) count += 1;
  return count >= perSec;
}

// Verify the submitted batch sequence numbers form a contiguous run starting at
// `expectedNext`. Gaps and duplicates are both rejected — entries must arrive
// in strict order to keep the book pages consistent.
export function checkSequenceContinuity(
  sequenceNumbers: readonly number[],
  expectedNext: number,
): { ok: true } | { ok: false; reason: AuditReason } {
  for (let i = 0; i < sequenceNumbers.length; i += 1) {
    if (sequenceNumbers[i] !== expectedNext + i) {
      return { ok: false, reason: "sequence_discontinuity" };
    }
  }
  return { ok: true };
}
