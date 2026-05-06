import Foundation
import CryptoKit

/// Client-side anti-cheat for mantra entry cadence. The server is the
/// authority — this is a fast local screen so we don't ship obviously bad
/// data over the network. See SPEC.md §17 (rate limiting) + §22 (target
/// false-positive rate <2%).
public struct CadenceValidator: Sendable {
    /// Minimum gap between entries. Anything tighter is reflex/auto-tap.
    public let minInterval: TimeInterval
    /// Maximum gap before we consider the session paused.
    public let maxInterval: TimeInterval
    /// Minimum standard deviation of intervals — if entries are too uniform,
    /// likely a script.
    public let minStdDev: TimeInterval

    public init(
        minInterval: TimeInterval = 0.25,
        maxInterval: TimeInterval = 60.0,
        minStdDev: TimeInterval = 0.05
    ) {
        self.minInterval = minInterval
        self.maxInterval = maxInterval
        self.minStdDev = minStdDev
    }

    /// Returns the indices of entries that should be flagged for review.
    /// Empty array means the batch is clean.
    public func flaggedIndices(intervals: [TimeInterval]) -> [Int] {
        var flagged: [Int] = []
        for (i, interval) in intervals.enumerated() {
            if interval < minInterval { flagged.append(i) }
        }
        if intervals.count >= 5, stdDev(intervals) < minStdDev {
            // Low entropy — entire batch is suspicious.
            flagged = Array(intervals.indices)
        }
        return flagged
    }

    /// SHA256 hex digest of the joined timing string. Server compares this
    /// against its own re-derivation to detect forged batches.
    public func cadenceSignature(intervals: [TimeInterval], salt: String) -> String {
        let joined = intervals.map { String(format: "%.4f", $0) }.joined(separator: "|")
        let payload = "\(salt)|\(joined)"
        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func stdDev(_ values: [TimeInterval]) -> TimeInterval {
        guard values.count > 1 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(values.count - 1)
        return variance.squareRoot()
    }
}
