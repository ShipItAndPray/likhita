import Foundation

/// High-level service that turns the wire contracts into typed Swift calls.
/// Wraps `APIClient`, never exposes URLRequest details to the UI layer.
public actor LikhitaService {
    private let api: APIClient

    public init(api: APIClient) {
        self.api = api
    }

    // MARK: - Auth

    public struct AuthSyncRequest: Encodable, Sendable {
        public let name: String
        public let email: String
        public let gotra: String?
        public let nativePlace: String?
        public let phone: String?
        public let uiLanguage: String?
        public init(name: String, email: String, gotra: String? = nil, nativePlace: String? = nil, phone: String? = nil, uiLanguage: String? = nil) {
            self.name = name; self.email = email
            self.gotra = gotra; self.nativePlace = nativePlace
            self.phone = phone; self.uiLanguage = uiLanguage
        }
    }

    public struct AuthSyncResponse: Decodable, Sendable {
        public let ok: Bool
        public let user: ServerUser
    }

    public struct ServerUser: Decodable, Sendable {
        public let id: String
        public let clerkId: String
        public let name: String
        public let email: String
        public let primaryApp: String?
        public let linkedApps: [String]?
    }

    public func syncUser(_ req: AuthSyncRequest) async throws -> AuthSyncResponse {
        try await api.post("/api/v1/auth/sync", body: req)
    }

    // MARK: - Kotis

    public struct CreateKotiRequest: Encodable, Sendable {
        public let traditionPath: String
        public let mantraString: String
        public let renderedScript: String
        public let mode: String
        public let targetCount: Int
        public let stylusColor: String
        public let stylusSignatureHash: String
        public let theme: String
        public let dedicationText: String
        public let dedicationTo: String

        public init(
            traditionPath: String, mantraString: String, renderedScript: String,
            mode: String, targetCount: Int, stylusColor: String, stylusSignatureHash: String,
            theme: String, dedicationText: String, dedicationTo: String
        ) {
            self.traditionPath = traditionPath; self.mantraString = mantraString
            self.renderedScript = renderedScript; self.mode = mode
            self.targetCount = targetCount; self.stylusColor = stylusColor
            self.stylusSignatureHash = stylusSignatureHash; self.theme = theme
            self.dedicationText = dedicationText; self.dedicationTo = dedicationTo
        }
    }

    public struct CreateKotiResponse: Decodable, Sendable {
        public let koti: ServerKoti
    }

    public struct ServerKoti: Decodable, Sendable {
        public let id: String
        public let userId: String
        public let appOrigin: String
        public let traditionPath: String
        public let mantraString: String
        public let renderedScript: String
        public let mode: String
        public let targetCount: Int
        public let currentCount: Int
        public let stylusColor: String?
        public let theme: String?
        public let dedicationText: String?
        public let dedicationTo: String?
        public let locked: Bool?
        public let completedAt: Date?
    }

    public struct GetKotiResponse: Decodable, Sendable {
        public let koti: ServerKoti
    }

    public struct ListKotisResponse: Decodable, Sendable {
        public let kotis: [ServerKoti]
    }

    public func createKoti(_ req: CreateKotiRequest) async throws -> ServerKoti {
        let resp: CreateKotiResponse = try await api.post("/api/v1/kotis", body: req)
        return resp.koti
    }

    public func getKoti(id: String) async throws -> ServerKoti {
        let resp: GetKotiResponse = try await api.get("/api/v1/kotis/\(id)")
        return resp.koti
    }

    public func listKotis() async throws -> [ServerKoti] {
        let resp: ListKotisResponse = try await api.get("/api/v1/kotis")
        return resp.kotis
    }

    // MARK: - Entries (the monotonic forward-only commit)

    public struct CadenceSignaturePayload: Encodable, Sendable {
        public let gaps: [Double]
        public init(gaps: [Double]) { self.gaps = gaps }
    }

    public struct EntryPayload: Encodable, Sendable {
        public let sequenceNumber: Int
        public let committedAt: String   // ISO-8601 UTC
        public let cadenceSignature: CadenceSignaturePayload
        public let clientSessionId: String

        public init(sequenceNumber: Int, committedAt: Date, gaps: [Double], clientSessionId: String) {
            self.sequenceNumber = sequenceNumber
            self.committedAt = ISO8601DateFormatter.standard.string(from: committedAt)
            self.cadenceSignature = CadenceSignaturePayload(gaps: gaps)
            self.clientSessionId = clientSessionId
        }
    }

    public struct SubmitEntriesRequest: Encodable, Sendable {
        public let idempotencyKey: String
        public let entries: [EntryPayload]
        public init(idempotencyKey: String, entries: [EntryPayload]) {
            self.idempotencyKey = idempotencyKey
            self.entries = entries
        }
    }

    public struct SubmitEntriesResponse: Decodable, Sendable {
        public let accepted: Int
        public let currentCount: Int
        public let targetCount: Int?
        public let complete: Bool?
        public let milestoneUnlocked: Bool?
        public let milestoneLabel: String?
        public let flagged: [Int]?
    }

    public func submitEntries(kotiId: String, request: SubmitEntriesRequest) async throws -> SubmitEntriesResponse {
        try await api.post("/api/v1/kotis/\(kotiId)/entries", body: request)
    }

    // MARK: - Shared (Foundation) Koti

    public struct ServerSharedKoti: Decodable, Sendable {
        public let id: String
        public let name: String
        public let nameLocal: String
        public let targetCount: Int
        public let currentCount: Int
        public let custodian: String
        public let destination: String
        public let estimatedShipDate: String
        public let startedAt: String
    }

    public struct ServerSharedWriter: Decodable, Sendable {
        public let name: String
        public let place: String
        public let count: Int
        public let ago: String
        public let committedAt: String
    }

    public struct ServerSharedTopWriter: Decodable, Sendable {
        public let name: String
        public let count: Int
        public let joined: String
    }

    public struct ServerSharedCountry: Decodable, Sendable {
        public let country: String
        public let count: Int
    }

    public struct SharedHubSnapshot: Decodable, Sendable {
        public let koti: ServerSharedKoti
        public let uniqueWriters: Int
        public let countriesActive: Int
        public let recentWriters: [ServerSharedWriter]
        public let topWriters: [ServerSharedTopWriter]
        public let countries: [ServerSharedCountry]
    }

    public func getSharedHub() async throws -> SharedHubSnapshot {
        try await api.get("/api/v1/shared/koti")
    }

    public struct SharedEntryPayload: Encodable, Sendable {
        public let committedAt: String
        public let cadenceSignature: CadenceSignaturePayload
        public init(committedAt: Date, gaps: [Double]) {
            self.committedAt = ISO8601DateFormatter.standard.string(from: committedAt)
            self.cadenceSignature = CadenceSignaturePayload(gaps: gaps)
        }
    }

    public struct SharedAppendRequest: Encodable, Sendable {
        public let deviceId: String
        public let displayName: String?
        public let place: String?
        public let country: String?
        public let entries: [SharedEntryPayload]
        public init(deviceId: String, displayName: String? = nil, place: String? = nil, country: String? = nil, entries: [SharedEntryPayload]) {
            self.deviceId = deviceId
            self.displayName = displayName
            self.place = place
            self.country = country
            self.entries = entries
        }
    }

    public struct SharedAppendResponse: Decodable, Sendable {
        public let acceptedHere: Int
        public let currentCount: Int
        public let remaining: Int
        public let complete: Bool
    }

    public func appendSharedEntries(_ req: SharedAppendRequest) async throws -> SharedAppendResponse {
        try await api.post("/api/v1/shared/entries", body: req)
    }
}

extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
