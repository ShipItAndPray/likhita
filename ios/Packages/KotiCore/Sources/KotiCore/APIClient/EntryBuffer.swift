import Foundation

/// Disk-persisted batch accumulator. Counts committed mantras and tracks
/// the first/last commit timestamps until a flush sends the summary to
/// the server. Survives process kill via atomic FileManager writes.
///
/// The earlier design buffered per-mantra entries with cadence
/// signatures for anti-cheat. That was removed (devotional practice —
/// "it's the god who is going to enforce it"), so we now track only the
/// minimum the server needs: count + time range.
public actor EntryBuffer {
    public struct Summary: Codable, Sendable, Equatable {
        public var count: Int
        public var committedFirstAt: Date?
        public var committedLastAt: Date?
        public var clientSessionId: String
        public init(count: Int = 0, first: Date? = nil, last: Date? = nil, session: String) {
            self.count = count
            self.committedFirstAt = first
            self.committedLastAt = last
            self.clientSessionId = session
        }
    }

    private var summary: Summary
    private let storageKey: String
    private var inFlight: Int = 0   // count locked by an active flush

    public init(storageKey: String = "_default", clientSessionId: String) {
        self.storageKey = storageKey
        self.summary = Self.load(storageKey: storageKey)
            ?? Summary(session: clientSessionId)
    }

    /// Append one committed mantra to the on-disk batch.
    public func commit(at date: Date = Date()) {
        if summary.committedFirstAt == nil {
            summary.committedFirstAt = date
        }
        summary.committedLastAt = date
        summary.count += 1
        Self.save(storageKey: storageKey, summary: summary)
    }

    /// Lease the current pending batch for a flush. Marks `inFlight`
    /// so a concurrent flush doesn't double-post. Caller must call
    /// `confirm()` or `release()` afterward.
    public func leasePending() -> Summary? {
        guard summary.count > inFlight, let first = summary.committedFirstAt, let last = summary.committedLastAt else {
            return nil
        }
        let pending = summary.count - inFlight
        inFlight = summary.count
        return Summary(count: pending, first: first, last: last, session: summary.clientSessionId)
    }

    /// Successful flush — the leased count was accepted server-side.
    public func confirm(consumedCount: Int) {
        summary.count = max(0, summary.count - consumedCount)
        inFlight = max(0, inFlight - consumedCount)
        if summary.count == 0 {
            summary.committedFirstAt = nil
            summary.committedLastAt = nil
        }
        Self.save(storageKey: storageKey, summary: summary)
    }

    /// Flush failed — release the lease so the next attempt can retry.
    public func release(leasedCount: Int) {
        inFlight = max(0, inFlight - leasedCount)
    }

    public func pendingCount() -> Int { summary.count }

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

    private static func load(storageKey: String) -> Summary? {
        let url = fileURL(forKey: storageKey)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(Summary.self, from: data)
    }

    private static func save(storageKey: String, summary: Summary) {
        let url = fileURL(forKey: storageKey)
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        guard let data = try? enc.encode(summary) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    /// Wipe the on-disk queue file directory. Only used by UI testing's reset path.
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
