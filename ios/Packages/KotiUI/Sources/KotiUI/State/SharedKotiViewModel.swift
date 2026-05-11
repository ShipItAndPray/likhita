import Foundation
import Observation
import SwiftUI
import KotiCore

/// Loads + posts to the live Foundation Koti. Replaces the design-time
/// hard-coded sample data. The view model owns:
///   - the latest snapshot pulled from `GET /api/v1/shared/koti`
///   - a local "myMantras" counter so the UI can echo the user's session
///   - a refresh loop while the hub screen is visible (poll every 4s)
///   - the batched append that flushes mantras typed in SharedWritingView
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
    private let cadence = CadenceSampler()
    private let buffer = SharedEntryBuffer()
    private var flushTask: Task<Void, Never>?
    private var refreshTask: Task<Void, Never>?
    private let mantraTyped: String

    public init(service: LikhitaService, store: KotiStore = .shared, mantraTyped: String) {
        self.service = service
        self.deviceId = store.stableUserId()
        self.mantraTyped = mantraTyped
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

    public func commitMantra() {
        let gaps = cadence.takeGaps(expected: mantraTyped.count)
        mySessionCount += 1
        Task {
            await buffer.append(SharedEntryBuffer.Item(committedAt: Date(), gaps: gaps))
            scheduleFlush()
        }
    }

    private func scheduleFlush() {
        if flushTask != nil { return }
        flushTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000)
            await self?.flush()
            await MainActor.run { self?.flushTask = nil }
            if let pending = await self?.buffer.count(), pending > 0 {
                await MainActor.run { self?.scheduleFlush() }
            }
        }
    }

    private func flush() async {
        let lease = await buffer.lease(max: 25)
        if lease.isEmpty { return }
        await MainActor.run { self.pendingFlush = lease.count }

        let payloads = lease.map {
            LikhitaService.SharedEntryPayload(committedAt: $0.committedAt, gaps: $0.gaps)
        }
        let req = LikhitaService.SharedAppendRequest(
            deviceId: deviceId,
            displayName: nil, // honors anonymity by default; profile sync wires this later
            place: nil,
            country: nil,
            entries: payloads
        )
        do {
            let resp = try await service.appendSharedEntries(req)
            await buffer.confirm(count: resp.acceptedHere)
            // If acceptedHere is less than lease.count, the koti hit its ceiling
            // mid-batch. Drain the remaining lease so we don't retry forever.
            if resp.acceptedHere < lease.count {
                await buffer.confirm(count: lease.count - resp.acceptedHere)
            }
            await refresh()
            await MainActor.run { self.pendingFlush = 0 }
        } catch APIError.http(let status, _) where status == 410 {
            // Koti complete — nothing more to do
            await buffer.confirm(count: lease.count)
            await refresh()
            await MainActor.run { self.pendingFlush = 0 }
        } catch {
            await buffer.release(lease.count)
            phase = .error(describe(error))
            await MainActor.run { self.pendingFlush = 0 }
        }
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

/// In-flight buffer for shared koti entries. Simpler than the per-user
/// EntryBuffer — no sequence numbers, no in-flight set; the server is
/// append-only so we just need to remember how many are pending.
public actor SharedEntryBuffer {
    public struct Item: Sendable, Equatable {
        public let committedAt: Date
        public let gaps: [Double]
        public init(committedAt: Date, gaps: [Double]) {
            self.committedAt = committedAt
            self.gaps = gaps
        }
    }

    private var items: [Item] = []

    public init() {}

    public func append(_ item: Item) {
        items.append(item)
    }

    public func lease(max: Int = 25) -> [Item] {
        Array(items.prefix(max))
    }

    public func confirm(count: Int) {
        let drop = min(count, items.count)
        items.removeFirst(drop)
    }

    public func release(_ count: Int) {
        // No-op — items remain in the head of the buffer because we never
        // removed them. Kept for symmetry with EntryBuffer.
        _ = count
    }

    public func count() -> Int { items.count }
}
