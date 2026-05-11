import Foundation

/// On-device pointer to the active koti so the app can resume across cold
/// launches. The koti row itself lives on the server — this just remembers
/// "which koti was I writing".
///
/// Uses `UserDefaults` in the app's standard suite, which survives app
/// restarts but not uninstalls (which is the right behavior — re-installing
/// is the moment to re-auth).
public final class KotiStore: @unchecked Sendable {
    public static let shared = KotiStore(suite: nil)

    private let defaults: UserDefaults
    private let activeIdKey = "likhita.activeKotiId"
    private let clientSessionIdKey = "likhita.clientSessionId"
    private let stableUserIdKey = "likhita.stableUserId"

    public init(suite: String?) {
        if let suite, let custom = UserDefaults(suiteName: suite) {
            self.defaults = custom
        } else {
            self.defaults = .standard
        }
    }

    public var activeKotiId: String? {
        get { defaults.string(forKey: activeIdKey) }
        set {
            if let newValue { defaults.set(newValue, forKey: activeIdKey) }
            else { defaults.removeObject(forKey: activeIdKey) }
        }
    }

    /// UUID stamped on every entry to group keystrokes from the same launch.
    /// Rotates per launch — a new session ID per cold start.
    public lazy var clientSessionId: String = {
        if let existing = defaults.string(forKey: clientSessionIdKey) {
            return existing
        }
        let id = UUID().uuidString.lowercased()
        defaults.set(id, forKey: clientSessionIdKey)
        return id
    }()

    /// Stable per-install identity passed as `X-Test-Clerk-Id` until Clerk's
    /// iOS SDK ships. Server treats this as the clerk identity — the server's
    /// `requireAuth` accepts it via the test/dev header.
    public func stableUserId() -> String {
        if let existing = defaults.string(forKey: stableUserIdKey) {
            return existing
        }
        let id = "device-" + UUID().uuidString.lowercased()
        defaults.set(id, forKey: stableUserIdKey)
        return id
    }

    public func clearActive() {
        defaults.removeObject(forKey: activeIdKey)
    }
}
