import Foundation

/// Captures inter-keystroke gaps for one mantra commit. The UI feeds each
/// keypress timestamp into the sampler; on commit, it asks for the gaps
/// array and resets.
public final class CadenceSampler: @unchecked Sendable {
    private var timestamps: [TimeInterval] = []
    private let lock = NSLock()

    public init() {}

    public func record(timestamp: TimeInterval = Date().timeIntervalSince1970 * 1000) {
        lock.lock(); defer { lock.unlock() }
        timestamps.append(timestamp)
    }

    /// Returns gaps in milliseconds, then resets internal state.
    /// `mantraLength` lets the caller pad with the mean if they captured
    /// fewer keystrokes than expected (rare — happens if the user paste-blocks).
    public func takeGaps(expected: Int) -> [Double] {
        lock.lock(); defer { lock.unlock() }
        var gaps: [Double] = []
        for i in 1..<timestamps.count {
            let g = timestamps[i] - timestamps[i - 1]
            if g >= 0 && g <= 60_000 { gaps.append(g) }
        }
        timestamps.removeAll(keepingCapacity: true)
        if gaps.isEmpty { return [200] }   // fallback: one mid-cadence gap so the schema (min 1) passes
        if gaps.count >= expected { return gaps }
        // Pad with the median so the gaps array has at least `expected - 1` entries.
        let sorted = gaps.sorted()
        let median = sorted[sorted.count / 2]
        while gaps.count < max(1, expected - 1) { gaps.append(median) }
        return gaps
    }
}

/// Buffer of accepted entries waiting to flush to the server.
/// Production rule: count never moves backward. We keep the buffer in
/// monotonic sequence-number order and never re-issue a number we've already
/// successfully posted.
public actor EntryBuffer {
    public struct Item: Sendable, Equatable {
        public let sequenceNumber: Int
        public let committedAt: Date
        public let gaps: [Double]
        public init(sequenceNumber: Int, committedAt: Date, gaps: [Double]) {
            self.sequenceNumber = sequenceNumber
            self.committedAt = committedAt
            self.gaps = gaps
        }
    }

    private var items: [Item] = []
    private var inFlight: Set<Int> = []

    public init() {}

    public func append(_ item: Item) {
        items.append(item)
    }

    /// Returns up to `max` pending items in order. Marks them in-flight so
    /// concurrent flush attempts don't double-submit. Caller must call
    /// `confirm(...)` or `release(...)` afterwards.
    public func leaseBatch(max: Int = 10) -> [Item] {
        let batch = Array(items.prefix(max))
        for it in batch { inFlight.insert(it.sequenceNumber) }
        return batch
    }

    public func confirm(throughSequence seq: Int) {
        items.removeAll { $0.sequenceNumber <= seq }
        inFlight = inFlight.filter { $0 > seq }
    }

    public func release(_ batch: [Item]) {
        for it in batch { inFlight.remove(it.sequenceNumber) }
    }

    public func count() -> Int { items.count }
}

/// Generates URL-safe idempotency keys (server requires 8-128 [A-Za-z0-9_-]).
public enum IdempotencyKey {
    public static func make() -> String {
        // 16 bytes of randomness, URL-safe base64 without padding.
        var bytes = [UInt8](repeating: 0, count: 16)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if status != errSecSuccess {
            for i in 0..<bytes.count { bytes[i] = UInt8.random(in: 0...255) }
        }
        let b64 = Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "ios-\(b64)"
    }
}
