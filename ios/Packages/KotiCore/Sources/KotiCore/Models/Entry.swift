import Foundation

/// A single committed mantra entry. Sequence numbers are server-issued and
/// strictly monotonic per koti (UNIQUE constraint in SPEC.md §18).
public struct Entry: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let kotiId: UUID
    public let sequenceNumber: Int64
    public let committedAt: Date
    public let cadenceSignature: String
    public let clientSessionId: UUID
    public var flagged: Bool

    public init(
        id: UUID = UUID(),
        kotiId: UUID,
        sequenceNumber: Int64,
        committedAt: Date,
        cadenceSignature: String,
        clientSessionId: UUID,
        flagged: Bool = false
    ) {
        self.id = id
        self.kotiId = kotiId
        self.sequenceNumber = sequenceNumber
        self.committedAt = committedAt
        self.cadenceSignature = cadenceSignature
        self.clientSessionId = clientSessionId
        self.flagged = flagged
    }
}

/// Local-only buffer entry waiting to be POSTed to the server in a batch.
/// Once the server accepts it the row is removed from the queue.
public struct PendingEntry: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let kotiId: UUID
    public let sequenceNumber: Int64
    public let committedAt: Date
    public let cadenceSignature: String
    public let clientSessionId: UUID

    public init(
        id: UUID = UUID(),
        kotiId: UUID,
        sequenceNumber: Int64,
        committedAt: Date,
        cadenceSignature: String,
        clientSessionId: UUID
    ) {
        self.id = id
        self.kotiId = kotiId
        self.sequenceNumber = sequenceNumber
        self.committedAt = committedAt
        self.cadenceSignature = cadenceSignature
        self.clientSessionId = clientSessionId
    }
}
