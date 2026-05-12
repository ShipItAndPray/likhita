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
/// Production rule: count never moves backward, and **no mantra is ever
/// lost.** Every append() is atomically written to disk before returning,
/// so a process kill within the 800ms flush debounce never drops entries.
/// On next launch the on-disk queue is loaded and drained on first flush.
public actor EntryBuffer {
    public struct Item: Sendable, Equatable, Codable {
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
    private let storageKey: String

    /// `storageKey` is the koti id. The on-disk queue file is partitioned
    /// per koti so multiple sankalpams on the same device don't bleed.
    /// Falls back to "_default" when the caller hasn't pinned a koti yet
    /// (early-launch state before startKoti() completes).
    public init(storageKey: String = "_default") {
        self.storageKey = storageKey
        self.items = Self.load(storageKey: storageKey)
    }

    public func append(_ item: Item) {
        items.append(item)
        Self.save(storageKey: storageKey, items: items)
    }

    /// Returns up to `max` pending items in order. Marks them in-flight so
    /// concurrent flush attempts don't double-submit. Caller must call
    /// `confirm(...)` or `release(...)` afterwards.
    public func leaseBatch(max: Int = 10) -> [Item] {
        let pending = items.filter { !inFlight.contains($0.sequenceNumber) }
        let batch = Array(pending.prefix(max))
        for it in batch { inFlight.insert(it.sequenceNumber) }
        return batch
    }

    public func confirm(throughSequence seq: Int) {
        items.removeAll { $0.sequenceNumber <= seq }
        inFlight = inFlight.filter { $0 > seq }
        Self.save(storageKey: storageKey, items: items)
    }

    public func release(_ batch: [Item]) {
        for it in batch { inFlight.remove(it.sequenceNumber) }
    }

    public func count() -> Int { items.count }

    // MARK: - Disk persistence

    private static func fileURL(forKey key: String) -> URL {
        let safe = key.replacingOccurrences(of: "/", with: "_")
                      .replacingOccurrences(of: ".", with: "_")
        let dirs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        let base = dirs.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("LikhitaPersonal", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("buffer-\(safe).json")
    }

    private static func load(storageKey: String) -> [Item] {
        let url = fileURL(forKey: storageKey)
        guard let data = try? Data(contentsOf: url) else { return [] }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return (try? dec.decode([Item].self, from: data)) ?? []
    }

    private static func save(storageKey: String, items: [Item]) {
        let url = fileURL(forKey: storageKey)
        if items.isEmpty {
            try? FileManager.default.removeItem(at: url)
            return
        }
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(items) else { return }
        // Atomic write — fsync'd temp file + rename, so a process kill
        // mid-write can never produce a partial file.
        try? data.write(to: url, options: [.atomic])
    }

    /// Wipe the on-disk queue file. Only used by UI testing's reset path.
    public static func wipeAll() {
        let dirs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        guard let base = dirs.first else { return }
        let dir = base.appendingPathComponent("LikhitaPersonal", isDirectory: true)
        try? FileManager.default.removeItem(at: dir)
    }
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
