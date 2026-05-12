import Foundation
import Observation
import SwiftUI
import KotiCore

/// Loads + posts to the live Foundation Koti.
///
/// **Persistence contract (redesigned 2026-05-12):**
///   - Each commitMantra() bumps an on-disk batch summary (count + first/
///     last commit timestamps). One atomic file write per commit.
///   - Force-flush when the writing view disappears (`flushNow()`).
///   - Force-flush when the app moves to background or terminates
///     (caller observes scenePhase and calls `flushNow()`).
///   - On launch the queue is drained transparently — any unflushed
///     mantras from a prior session post automatically.
///
/// Anti-cheat was removed (devotional, voluntary practice). The wire
/// format is a summary: `count + committedFirstAt + committedLastAt`.
/// API calls per session: 1 GET on hub entry, 1 POST on lifecycle exit.
@MainActor
@Observable
public final class SharedKotiViewModel {
    public enum Phase: Equatable {
        case idle
        case loading
        case ready
        case error(String)
    }

    public private(set) var phase: Phase = .idle
    public private(set) var snapshot: LikhitaService.SharedHubSnapshot?
    public private(set) var mySessionCount: Int = 0
    public private(set) var pendingFlush: Int = 0

    private let service: LikhitaService
    private let deviceId: String
    private let store: KotiStore
    private var refreshTask: Task<Void, Never>?
    private let mantraTyped: String
    private let storageKey: String
    private var posting: Bool = false

    public init(service: LikhitaService, store: KotiStore = .shared, mantraTyped: String) {
        self.service = service
        self.store = store
        self.deviceId = store.stableUserId()
        self.mantraTyped = mantraTyped
        self.storageKey = "likhita.sangha.\(store.stableUserId())"

        // UI-testing helper: `--simulate-mantras=N` synthesizes N committed
        // mantras directly into the on-disk summary at init time, so XCUITest
        // can exercise the disk → flush → server pipeline without driving the
        // keyboard.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-testing"),
           let simArg = args.first(where: { $0.hasPrefix("--simulate-mantras=") }),
           let n = Int(simArg.dropFirst("--simulate-mantras=".count)),
           n > 0 {
            let now = Date()
            let first = now.addingTimeInterval(-Double(n))
            PersistedSangha.bump(key: storageKey, addCount: n, first: first, last: now)
        }

        let pending = PersistedSangha.load(key: storageKey)
        self.mySessionCount = pending.count
        self.pendingFlush = pending.count
        if pending.count > 0 {
            Task { await flushNow() }
        }
    }

    /// Refresh once on entry. Polling is intentionally NOT enabled — the
    /// Sangha counter moves slowly enough that a static read on entry is
    /// fine. To see fresh data, go back to the Threshold and re-enter.
    public func startPolling() {
        if refreshTask != nil { return }
        refreshTask = Task { [weak self] in
            await self?.refresh()
        }
    }

    public func stopPolling() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    public func refresh() async {
        if phase != .ready { phase = .loading }
        do {
            let snap = try await service.getSharedHub()
            self.snapshot = snap
            self.phase = .ready
        } catch {
            self.phase = .error(describe(error))
        }
    }

    // MARK: - Writing surface integration

    /// No-op since anti-cheat was removed. Kept for source compatibility.
    public func recordKeystroke() {}

    /// Called once per completed mantra. Bumps the on-disk batch summary
    /// (count + last timestamp). One atomic file write. No HTTP.
    public func commitMantra() {
        let now = Date()
        PersistedSangha.bump(key: storageKey, addCount: 1, first: nil, last: now)
        mySessionCount += 1
        pendingFlush += 1
    }

    /// Force a flush of every queued entry. Call this from:
    ///   - the writing view's `onDisappear`
    ///   - the app's `scenePhase` change to `.background` or `.inactive`
    ///   - app foreground (to drain any pending from prior session)
    public func flushNow() async {
        if posting { return }
        posting = true
        defer { posting = false }

        guard var pending = PersistedSangha.load(key: storageKey).nonEmpty else { return }

        // Cap per-POST count to avoid sending more than the server accepts.
        let stride = 1008
        while pending.count > 0 {
            let chunkCount = min(pending.count, stride)
            let req = LikhitaService.SharedAppendRequest(
                deviceId: deviceId,
                displayName: nil,
                place: nil,
                country: nil,
                count: chunkCount,
                committedFirstAt: pending.committedFirstAt,
                committedLastAt: pending.committedLastAt
            )
            do {
                let resp = try await service.appendSharedEntries(req)
                let drop = (resp.complete ? chunkCount : resp.acceptedHere)
                pending = PersistedSangha.drain(key: storageKey, count: drop) ?? PersistedSangha.Empty
                pendingFlush = pending.count
                if resp.complete {
                    PersistedSangha.wipe(key: storageKey)
                    pendingFlush = 0
                    break
                }
            } catch APIError.http(let status, _) where status == 410 {
                PersistedSangha.wipe(key: storageKey)
                pendingFlush = 0
                break
            } catch APIError.http(let status, let body) {
                let bodyStr = String(data: body, encoding: .utf8) ?? "(non-utf8)"
                phase = .error("HTTP \(status): \(bodyStr)")
                return
            } catch {
                phase = .error(describe(error))
                return
            }
        }
        await refresh()
    }

    private func describe(_ err: Error) -> String {
        switch err {
        case let APIError.http(status, body):
            return "HTTP \(status): \(String(data: body, encoding: .utf8) ?? "")"
        case let APIError.transport(urlErr):
            return "Network: \(urlErr.localizedDescription)"
        case APIError.unauthenticated: return "Unauthenticated"
        case APIError.rateLimited: return "Rate limited"
        default: return "\(err)"
        }
    }
}

/// Disk-persisted batch summary for the Sangha. One file per device,
/// holding `{count, committedFirstAt, committedLastAt}`. Every commit
/// atomic-writes the updated summary — survives process kill.
public enum PersistedSangha {
    public struct Summary: Codable, Sendable, Equatable {
        public var count: Int
        public var committedFirstAt: Date
        public var committedLastAt: Date
    }

    public static let Empty = Summary(count: 0, committedFirstAt: Date(), committedLastAt: Date())

    private static func fileURL(forKey key: String) -> URL {
        let safeName = key.replacingOccurrences(of: ".", with: "_")
                          .replacingOccurrences(of: "/", with: "_")
        let dirs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        let base = dirs.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = base.appendingPathComponent("LikhitaSangha", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("\(safeName).json")
    }

    public static func load(key: String) -> Summary {
        let url = fileURL(forKey: key)
        guard let data = try? Data(contentsOf: url) else { return Empty }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(Summary.self, from: data)) ?? Empty
    }

    private static func save(key: String, summary: Summary) {
        let url = fileURL(forKey: key)
        if summary.count == 0 {
            try? FileManager.default.removeItem(at: url)
            return
        }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(summary) else { return }
        try? data.write(to: url, options: [.atomic])
    }

    /// Increment the on-disk count. If `first` is nil and we already
    /// have a summary, we keep the existing first-timestamp; otherwise
    /// we adopt the supplied one (or `last` as a fallback).
    public static func bump(key: String, addCount n: Int, first: Date?, last: Date) {
        var cur = load(key: key)
        if cur.count == 0 {
            cur.committedFirstAt = first ?? last
        }
        cur.committedLastAt = last
        cur.count += n
        save(key: key, summary: cur)
    }

    /// Drop `count` mantras off the summary after a successful flush.
    /// Returns the post-drain summary (or nil if completely empty).
    public static func drain(key: String, count: Int) -> Summary? {
        var cur = load(key: key)
        cur.count = max(0, cur.count - count)
        if cur.count == 0 {
            let url = fileURL(forKey: key)
            try? FileManager.default.removeItem(at: url)
            return nil
        }
        save(key: key, summary: cur)
        return cur
    }

    public static func wipe(key: String) {
        let url = fileURL(forKey: key)
        try? FileManager.default.removeItem(at: url)
    }
}

private extension PersistedSangha.Summary {
    /// `nil` when this summary holds nothing flushable.
    var nonEmpty: PersistedSangha.Summary? { count > 0 ? self : nil }
}
