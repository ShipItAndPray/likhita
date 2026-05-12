import Foundation
import Observation
import SwiftUI
import KotiCore

/// Loads + posts to the live Foundation Koti.
///
/// **Persistence contract (fixed 2026-05-11, redesigned 2026-05-12):**
///   - Every commit is persisted to disk immediately (UserDefaults backed
///     queue keyed by deviceId). Survives process kill.
///   - Auto-flush when the on-disk queue reaches 10 entries.
///   - Force-flush when the writing view disappears (`flushNow()`).
///   - Force-flush when the app moves to background or terminates
///     (caller observes scenePhase and calls `flushNow()`).
///   - On launch the queue is drained transparently — any unflushed
///     mantras from a prior session post automatically.
///
/// API calls = max(N/10, 1 per app session). No mantra is ever lost.
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
    private let cadence = CadenceSampler()
    private var refreshTask: Task<Void, Never>?
    private let mantraTyped: String
    private let pendingKey: String

    /// Auto-flush threshold. When the disk queue reaches this many entries,
    /// fire the POST immediately instead of waiting for view-disappear /
    /// background.
    private let batchSize = 10

    /// Set to true while a POST is in flight so concurrent commits don't
    /// fire overlapping requests.
    private var posting: Bool = false

    public init(service: LikhitaService, store: KotiStore = .shared, mantraTyped: String) {
        self.service = service
        self.store = store
        self.deviceId = store.stableUserId()
        self.mantraTyped = mantraTyped
        self.pendingKey = "likhita.sangha.pendingPosts.\(store.stableUserId())"
        // Surface any items left over from a prior session — the UI shows
        // them as pendingFlush so the user knows there's outstanding work.
        let pending = PersistedSangha.load(key: pendingKey)
        self.mySessionCount = pending.count
        self.pendingFlush = pending.count
        if !pending.isEmpty {
            Task { await flushNow() }
        }
    }

    public func startPolling() {
        if refreshTask != nil { return }
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(nanoseconds: 4_000_000_000)
            }
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

    public func recordKeystroke() {
        cadence.record()
    }

    /// Called once per completed mantra. Bumps session counter, persists
    /// the entry to disk, fires a batched POST if the queue has hit the
    /// batch threshold. Cheap in the typical case (no HTTP).
    public func commitMantra() {
        let gaps = cadence.takeGaps(expected: mantraTyped.count)
        let entry = PersistedSangha.Entry(committedAt: Date(), gaps: gaps)
        PersistedSangha.append(key: pendingKey, entry: entry)
        mySessionCount += 1
        pendingFlush += 1
        if PersistedSangha.load(key: pendingKey).count >= batchSize {
            Task { await flushNow() }
        }
    }

    /// Force a flush of every queued entry. Call this from:
    ///   - the writing view's `onDisappear`
    ///   - the app's `scenePhase` change to `.background` or `.inactive`
    ///   - app foreground (to drain any pending from prior session)
    ///   - error retries
    public func flushNow() async {
        if posting { return }
        posting = true
        defer { posting = false }

        var pending = PersistedSangha.load(key: pendingKey)
        while !pending.isEmpty {
            let batch = Array(pending.prefix(25))
            let payloads = batch.map {
                LikhitaService.SharedEntryPayload(committedAt: $0.committedAt, gaps: $0.gaps)
            }
            let req = LikhitaService.SharedAppendRequest(
                deviceId: deviceId,
                displayName: nil,
                place: nil,
                country: nil,
                entries: payloads
            )
            do {
                let resp = try await service.appendSharedEntries(req)
                let accepted = resp.acceptedHere
                // Drop the items the server actually accepted. If acceptedHere
                // is less than batch.count, the koti hit its ceiling — drop
                // the rest too since there's no point retrying them.
                let drop = (resp.complete ? batch.count : accepted)
                pending.removeFirst(min(drop, pending.count))
                PersistedSangha.save(key: pendingKey, entries: pending)
                pendingFlush = pending.count
                if resp.complete {
                    pending.removeAll()
                    PersistedSangha.save(key: pendingKey, entries: [])
                    pendingFlush = 0
                    break
                }
            } catch APIError.http(let status, _) where status == 410 {
                // Koti complete — discard everything.
                PersistedSangha.save(key: pendingKey, entries: [])
                pendingFlush = 0
                break
            } catch {
                // Network or 5xx — leave the queue on disk for next attempt.
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

/// Disk-persisted retry queue for Sangha entries. Each entry is a single
/// mantra commit. Survives app process kill so mantras typed offline / on
/// flaky networks are never lost. Encoded as a JSON array stored in
/// UserDefaults keyed by deviceId.
public enum PersistedSangha {
    public struct Entry: Codable, Sendable, Equatable {
        public let committedAt: Date
        public let gaps: [Double]
        public init(committedAt: Date, gaps: [Double]) {
            self.committedAt = committedAt
            self.gaps = gaps
        }
    }

    public static func load(key: String) -> [Entry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
    }

    public static func save(key: String, entries: [Entry]) {
        if entries.isEmpty {
            UserDefaults.standard.removeObject(forKey: key)
            return
        }
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    public static func append(key: String, entry: Entry) {
        var list = load(key: key)
        list.append(entry)
        save(key: key, entries: list)
    }
}
