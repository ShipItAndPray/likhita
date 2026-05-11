import Foundation
import Observation
import SwiftUI
import KotiCore

/// Coordinator between UI state and the backend. Owns:
///   - the service client (LikhitaService),
///   - the on-device pointer (KotiStore.activeKotiId),
///   - the cadence sampler that records keystrokes for each mantra,
///   - the entry buffer that batches commits to the server.
///
/// Production rule: count is whatever the SERVER returns. The UI never
/// fabricates progress — every mantra typed is buffered, posted, and only
/// then reflected in `koti.count`. This guarantees forward-only state,
/// even if the user kills the app mid-write.
@MainActor
@Observable
public final class KotiViewModel {
    public enum Phase: Equatable {
        case idle
        case syncing
        case loaded
        case error(String)
    }

    public private(set) var phase: Phase = .idle
    public private(set) var session: KotiSession
    public private(set) var serverKotiId: String?
    public private(set) var pendingFlush: Int = 0

    private let service: LikhitaService
    private let store: KotiStore
    private let cadence = CadenceSampler()
    private let buffer = EntryBuffer()
    private let mantraTyped: String      // expected target string e.g. "srirama"
    private var nextSequence: Int = 1
    private var flushTask: Task<Void, Never>?

    public init(
        service: LikhitaService,
        store: KotiStore = .shared,
        initialSession: KotiSession,
        mantraTyped: String
    ) {
        self.service = service
        self.store = store
        self.session = initialSession
        self.mantraTyped = mantraTyped
        self.serverKotiId = store.activeKotiId
    }

    // MARK: - Lifecycle

    /// Resume an existing koti from the server, if one is pinned in storage.
    /// Returns true if a session was hydrated and the writing route should be
    /// shown; false if the user must walk the sankalpam from scratch.
    public func resumeIfPossible() async -> Bool {
        guard let id = store.activeKotiId else { return false }
        phase = .syncing
        do {
            let server = try await service.getKoti(id: id)
            applyServer(server)
            phase = .loaded
            return server.completedAt == nil
        } catch {
            // If the server doesn't know this koti (404 / 403), drop the
            // pointer — the user's device has stale state.
            if case APIError.http(let status, _) = error, status == 404 || status == 403 {
                store.clearActive()
                serverKotiId = nil
            }
            phase = .error(describe(error))
            return false
        }
    }

    /// Sankalpam pledge complete → create the koti server-side and pin it.
    public func startKoti(traditionPath: String, renderedScript: String, modeKey: String,
                          targetCount: Int, stylusColor: String, stylusSignatureHash: String,
                          theme: String, dedicationText: String, dedicationTo: String,
                          name: String) async throws {
        phase = .syncing
        let mantraString = traditionPath == "telugu" ? "srirama" : "ram"
        let req = LikhitaService.CreateKotiRequest(
            traditionPath: traditionPath,
            mantraString: mantraString,
            renderedScript: renderedScript,
            mode: backendModeKey(modeKey),
            targetCount: targetCount,
            stylusColor: stylusColor,
            stylusSignatureHash: stylusSignatureHash,
            theme: theme,
            dedicationText: dedicationText,
            dedicationTo: backendDedication(dedicationTo)
        )
        let server = try await service.createKoti(req)
        store.activeKotiId = server.id
        serverKotiId = server.id
        applyServer(server)
        // Reset the local session so the writing surface starts fresh.
        session.name = name
        session.dedicationText = dedicationText
        nextSequence = server.currentCount + 1
        phase = .loaded
    }

    // MARK: - Writing surface

    /// Called whenever the user types a character of the target mantra.
    public func recordKeystroke() {
        cadence.record()
    }

    /// Called when the user successfully types the full mantra (matches
    /// `mantraTyped` lowercased). Captures the cadence + buffers an entry,
    /// then schedules a flush.
    public func commitMantra() {
        guard serverKotiId != nil else { return }
        let gaps = cadence.takeGaps(expected: mantraTyped.count)
        let item = EntryBuffer.Item(
            sequenceNumber: nextSequence,
            committedAt: Date(),
            gaps: gaps
        )
        nextSequence += 1
        Task { await buffer.append(item); scheduleFlush() }
    }

    private func scheduleFlush() {
        if flushTask != nil { return }
        flushTask = Task { [weak self] in
            // Coalesce rapid commits — wait briefly so a small batch forms.
            try? await Task.sleep(nanoseconds: 800_000_000)   // 0.8s
            await self?.flush()
            await MainActor.run { self?.flushTask = nil }
            // If more arrived while we slept, reschedule.
            if let count = await self?.buffer.count(), count > 0 {
                await MainActor.run { self?.scheduleFlush() }
            }
        }
    }

    private func flush() async {
        guard let kotiId = serverKotiId else { return }
        let lease = await buffer.leaseBatch(max: 25)
        guard !lease.isEmpty else { return }
        await MainActor.run { self.pendingFlush = lease.count }

        let payloads = lease.map { item in
            LikhitaService.EntryPayload(
                sequenceNumber: item.sequenceNumber,
                committedAt: item.committedAt,
                gaps: item.gaps,
                clientSessionId: store.clientSessionId
            )
        }
        let req = LikhitaService.SubmitEntriesRequest(
            idempotencyKey: IdempotencyKey.make(),
            entries: payloads
        )

        do {
            let resp = try await service.submitEntries(kotiId: kotiId, request: req)
            await buffer.confirm(throughSequence: lease.last!.sequenceNumber)
            session.count = Int64(resp.currentCount)
            await MainActor.run { self.pendingFlush = 0 }
        } catch APIError.http(let status, let body) {
            await buffer.release(lease)
            // 409 = concurrent_update or sequence_discontinuity. Re-fetch the
            // server state so our nextSequence and count realign.
            if status == 409 {
                await refreshFromServer()
            } else if status == 410 {
                // Koti is already complete server-side. Treat as success.
                session.count = session.target
            } else {
                let msg = String(data: body, encoding: .utf8) ?? "HTTP \(status)"
                phase = .error(msg)
            }
            await MainActor.run { self.pendingFlush = 0 }
        } catch {
            await buffer.release(lease)
            phase = .error(describe(error))
            await MainActor.run { self.pendingFlush = 0 }
        }
    }

    public func refreshFromServer() async {
        guard let id = serverKotiId else { return }
        do {
            let server = try await service.getKoti(id: id)
            applyServer(server)
            nextSequence = server.currentCount + 1
        } catch {
            phase = .error(describe(error))
        }
    }

    // MARK: - Helpers

    private func applyServer(_ server: LikhitaService.ServerKoti) {
        // Server is the source of truth. Never let local state regress; only
        // forward-rebase if the server reports a higher count.
        if Int64(server.currentCount) > session.count {
            session.count = Int64(server.currentCount)
        }
        if Int64(server.targetCount) != session.target {
            session.target = Int64(server.targetCount)
        }
        if let text = server.dedicationText, !text.isEmpty {
            session.dedicationText = text
        }
    }

    private func backendModeKey(_ uiKey: String) -> String {
        // UI uses six plans; backend accepts a smaller enum. Map closest.
        switch uiKey {
        case "trial":      return "trial"
        case "crore":      return "crore"
        case "daily", "sankalpa", "lakh", "maha":
            return "lakh"
        default: return "lakh"
        }
    }

    private func backendDedication(_ uiKey: String) -> String {
        // Backend accepts: self / parent / child / departed / deity / community.
        // UI's "family" and "cause" map onto deity/community.
        switch uiKey {
        case "family": return "community"
        case "cause":  return "community"
        default:       return uiKey
        }
    }

    private func describe(_ err: Error) -> String {
        switch err {
        case let APIError.http(status, body):
            return "HTTP \(status): \(String(data: body, encoding: .utf8) ?? "")"
        case let APIError.transport(urlErr):
            return "Network: \(urlErr.localizedDescription)"
        case APIError.unauthenticated:
            return "Unauthenticated"
        case APIError.rateLimited:
            return "Rate limited"
        default:
            return "\(err)"
        }
    }
}
