import Foundation
import SwiftData

/// SwiftData model for entries that have been committed locally but not yet
/// confirmed by the server. Drained by the sync worker in batches of 5–25
/// per SPEC.md §19 (POST /v1/kotis/:id/entries).
@Model
public final class PendingEntryRecord {
    @Attribute(.unique) public var id: UUID
    public var kotiId: UUID
    public var sequenceNumber: Int64
    public var committedAt: Date
    public var cadenceSignature: String
    public var clientSessionId: UUID

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

/// SwiftData model: the user's local cache of a koti so the writing surface
/// works offline and the next launch resumes instantly without a network
/// round-trip.
@Model
public final class CachedKoti {
    @Attribute(.unique) public var id: UUID
    public var userId: UUID
    public var appOrigin: String
    public var modeRaw: String
    public var targetCount: Int64
    public var currentCount: Int64
    public var themeRaw: String
    public var dedicationText: String
    public var startedAt: Date
    public var completedAt: Date?

    public init(
        id: UUID,
        userId: UUID,
        appOrigin: String,
        modeRaw: String,
        targetCount: Int64,
        currentCount: Int64,
        themeRaw: String,
        dedicationText: String,
        startedAt: Date,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.appOrigin = appOrigin
        self.modeRaw = modeRaw
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.themeRaw = themeRaw
        self.dedicationText = dedicationText
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}

/// Builds the SwiftData container the app uses for offline state.
/// Kept tiny on purpose — all heavy querying happens against the server.
public enum PersistenceLayer {
    public static func makeContainer() throws -> ModelContainer {
        let schema = Schema([CachedKoti.self, PendingEntryRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try ModelContainer(for: schema, configurations: [config])
    }
}
