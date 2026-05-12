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
        // Pace fields (added 2026-05-12). Optional so older server
        // responses still decode cleanly while a deploy rolls out.
        public let goalDays: Int?
        public let reminderTimes: [String]?
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

    // MARK: - Entries (batch summary, one POST per session)

    /// One batch summary. Server UPSERTs into daily_counts keyed on
    /// (koti_id, date), so multiple writing sessions on the same local
    /// day collapse into one DB row. `date` is the device's local
    /// calendar date — derive with `LikhitaService.todayLocalDate()`.
    public struct SubmitBatchRequest: Encodable, Sendable {
        public let idempotencyKey: String
        public let count: Int
        public let clientSessionId: String
        public let date: String   // YYYY-MM-DD local

        public init(idempotencyKey: String, count: Int, clientSessionId: String, date: String) {
            self.idempotencyKey = idempotencyKey
            self.count = count
            self.clientSessionId = clientSessionId
            self.date = date
        }
    }

    /// Today's date in the device's local calendar, formatted YYYY-MM-DD.
    /// Use this when building a SubmitBatchRequest or SharedAppendRequest
    /// so the server's per-day row keying matches what the user actually
    /// experienced as "today".
    public static func todayLocalDate() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f.string(from: Date())
    }

    public struct SubmitBatchResponse: Decodable, Sendable {
        public let accepted: Int
        public let currentCount: Int
        public let targetCount: Int?
        public let complete: Bool?
        public let milestoneUnlocked: Bool?
        public let milestoneLabel: String?
    }

    public func submitBatch(kotiId: String, request: SubmitBatchRequest) async throws -> SubmitBatchResponse {
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

    public struct SharedAppendRequest: Encodable, Sendable {
        public let deviceId: String
        public let displayName: String?
        public let place: String?
        public let country: String?
        public let count: Int
        public let date: String   // YYYY-MM-DD local

        public init(
            deviceId: String,
            displayName: String? = nil,
            place: String? = nil,
            country: String? = nil,
            count: Int,
            date: String
        ) {
            self.deviceId = deviceId
            self.displayName = displayName
            self.place = place
            self.country = country
            self.count = count
            self.date = date
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

    // MARK: - Pace (calendar + goal/reminders)

    public struct CalendarDay: Decodable, Sendable, Equatable {
        public let date: String   // YYYY-MM-DD
        public let count: Int
    }

    public struct CalendarResponse: Decodable, Sendable {
        public let days: Int
        public let daily: [CalendarDay]
    }

    /// GET /api/v1/kotis/{id}/calendar?days=N
    /// Returns the user's per-day mantra contributions for the last N
    /// days. Source: the daily_counts table — primary-key range scan.
    public func getCalendar(kotiId: String, days: Int = 180) async throws -> CalendarResponse {
        try await api.get("/api/v1/kotis/\(kotiId)/calendar?days=\(days)")
    }

    public struct UpdatePaceRequest: Encodable, Sendable {
        public let goalDays: Int?
        public let reminderTimes: [String]?
        public init(goalDays: Int? = nil, reminderTimes: [String]? = nil) {
            self.goalDays = goalDays
            self.reminderTimes = reminderTimes
        }
    }

    public struct UpdatePaceResponse: Decodable, Sendable {
        public let goalDays: Int
        public let reminderTimes: [String]
    }

    /// PATCH /api/v1/kotis/{id}/pace
    /// Partial update of the Pace fields. Either or both fields may be
    /// nil — server only touches the ones you send.
    public func updatePace(kotiId: String, request: UpdatePaceRequest) async throws -> UpdatePaceResponse {
        try await api.patch("/api/v1/kotis/\(kotiId)/pace", body: request)
    }
}

extension ISO8601DateFormatter {
    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

extension Date {
    /// Local YYYY-MM-DD for this date. Used to bucket batches into the
    /// server's `daily_counts` table on the calendar day the user
    /// actually experienced.
    public func asLocalYMD() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f.string(from: self)
    }
}
