import Foundation

/// Server-side user record (mirror of `users` table in SPEC.md §18).
public struct User: Codable, Sendable, Identifiable, Hashable {
    public let id: UUID
    public let clerkId: String
    public var name: String
    public var gotra: String?
    public var nativePlace: String?
    public var email: String
    public var phone: String?
    public var uiLanguage: String
    public var primaryApp: String
    public var linkedApps: [String]
    public let createdAt: Date

    public init(
        id: UUID,
        clerkId: String,
        name: String,
        gotra: String? = nil,
        nativePlace: String? = nil,
        email: String,
        phone: String? = nil,
        uiLanguage: String,
        primaryApp: String,
        linkedApps: [String] = [],
        createdAt: Date
    ) {
        self.id = id
        self.clerkId = clerkId
        self.name = name
        self.gotra = gotra
        self.nativePlace = nativePlace
        self.email = email
        self.phone = phone
        self.uiLanguage = uiLanguage
        self.primaryApp = primaryApp
        self.linkedApps = linkedApps
        self.createdAt = createdAt
    }
}
