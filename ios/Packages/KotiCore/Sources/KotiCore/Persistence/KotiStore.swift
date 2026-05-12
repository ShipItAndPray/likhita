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

    /// Wipe everything UI tests rely on so each test starts from a known
    /// clean state: active koti pin + the on-disk Sangha retry queue. Only
    /// the app itself (under `--ui-testing --reset-state`) should call this.
    public static func resetForUITesting() {
        let store = KotiStore.shared
        store.clearActive()
        store.defaults.removeObject(forKey: store.stableUserIdKey)
        store.defaults.removeObject(forKey: store.clientSessionIdKey)
        // Disk-persisted Sangha queue lives in Library/LikhitaSangha — wipe
        // the whole directory so no pending entries bleed between tests.
        let dirs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        if let base = dirs.first {
            let queueDir = base.appendingPathComponent("LikhitaSangha", isDirectory: true)
            try? FileManager.default.removeItem(at: queueDir)
        }
    }
}
