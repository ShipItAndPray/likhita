import Foundation

/// Domain model for an active or completed koti (mantra-writing practice).
/// Mirrors the `kotis` table in SPEC.md §18.
public struct Koti: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let userId: UUID
    public let appOrigin: String
    public let traditionPath: String
    public let mantraString: String
    public let renderedScript: String
    public let inputMode: String
    public let mode: KotiMode
    public let targetCount: Int64
    public var currentCount: Int64
    public let stylusColor: String
    public let stylusSignatureHash: String
    public let theme: ThemeKey
    public let dedicationText: String
    public let dedicationTo: String
    public let startedAt: Date
    public var completedAt: Date?
    public var locked: Bool
    public var shipTemple: Bool
    public var templeDestination: TempleDestination?
    public var shipHome: Bool
    public var photoURL: URL?
    public var receiptURL: URL?

    public var progressFraction: Double {
        guard targetCount > 0 else { return 0 }
        return Double(currentCount) / Double(targetCount)
    }

    public var isComplete: Bool { currentCount >= targetCount }

    public init(
        id: UUID,
        userId: UUID,
        appOrigin: String,
        traditionPath: String,
        mantraString: String,
        renderedScript: String,
        inputMode: String,
        mode: KotiMode,
        targetCount: Int64,
        currentCount: Int64 = 0,
        stylusColor: String,
        stylusSignatureHash: String,
        theme: ThemeKey,
        dedicationText: String,
        dedicationTo: String,
        startedAt: Date,
        completedAt: Date? = nil,
        locked: Bool = true,
        shipTemple: Bool = false,
        templeDestination: TempleDestination? = nil,
        shipHome: Bool = false,
        photoURL: URL? = nil,
        receiptURL: URL? = nil
    ) {
        self.id = id
        self.userId = userId
        self.appOrigin = appOrigin
        self.traditionPath = traditionPath
        self.mantraString = mantraString
        self.renderedScript = renderedScript
        self.inputMode = inputMode
        self.mode = mode
        self.targetCount = targetCount
        self.currentCount = currentCount
        self.stylusColor = stylusColor
        self.stylusSignatureHash = stylusSignatureHash
        self.theme = theme
        self.dedicationText = dedicationText
        self.dedicationTo = dedicationTo
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.locked = locked
        self.shipTemple = shipTemple
        self.templeDestination = templeDestination
        self.shipHome = shipHome
        self.photoURL = photoURL
        self.receiptURL = receiptURL
    }
}
