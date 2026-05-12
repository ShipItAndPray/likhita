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

    /// Stable per-device identity passed as `X-Test-Clerk-Id` until Clerk's
    /// iOS SDK ships. Server treats this as the clerk identity.
    ///
    /// Stored in the **Keychain**, not UserDefaults — survives:
    ///   - app uninstall + reinstall (Keychain items are not removed)
    ///   - iCloud restore to a new device (kSecAttrAccessibleAfterFirstUnlock)
    ///   - --reset-state UI testing flag (intentionally; see `resetForUITesting`)
    ///
    /// One devotee = one device. If you reinstall the app you keep your
    /// devotee identity. The Sangha's "unique writers" count therefore
    /// reflects real distinct people, not test churn.
    public func stableUserId() -> String {
        if let kc = KeychainHelper.read(account: "likhita.stableUserId") {
            return kc
        }
        // Fall back to UserDefaults during migration — older installs have
        // the id there; copy it into Keychain so future reads are stable.
        if let legacy = defaults.string(forKey: stableUserIdKey) {
            _ = KeychainHelper.write(account: "likhita.stableUserId", value: legacy)
            return legacy
        }
        let id = "device-" + UUID().uuidString.lowercased()
        _ = KeychainHelper.write(account: "likhita.stableUserId", value: id)
        defaults.set(id, forKey: stableUserIdKey)
        return id
    }

    public func clearActive() {
        defaults.removeObject(forKey: activeIdKey)
    }

    /// Wipe everything UI tests rely on so each test starts from a known
    /// clean state: active koti pin + the on-disk Sangha + personal retry
    /// queues. Only the app itself (under `--ui-testing --reset-state`)
    /// should call this.
    ///
    /// Deliberately does NOT touch the Keychain-backed `stableUserId` —
    /// rotating that on every test run inflates the Sangha's
    /// `uniqueWriters` count with fake devotees. The stable id IS the
    /// device's identity; tests reset around it, not into a fresh one.
    public static func resetForUITesting() {
        let store = KotiStore.shared
        store.clearActive()
        store.defaults.removeObject(forKey: store.clientSessionIdKey)
        // Sangha disk queue
        let dirs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        if let base = dirs.first {
            try? FileManager.default.removeItem(at: base.appendingPathComponent("LikhitaSangha", isDirectory: true))
        }
        // Personal koti disk buffer
        EntryBuffer.wipeAll()
    }
}

/// Minimal Keychain wrapper for storing a single string value per account.
/// The full Apple `Security.framework` API is way more than this skill
/// needs — we just want "store one UUID, retrieve it later, survive
/// reinstall". Accessible after first device unlock so background tasks
/// can read it.
enum KeychainHelper {
    private static let service = "org.likhita.foundation"

    static func read(account: String) -> String? {
        let q: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var item: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    @discardableResult
    static func write(account: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let common: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        // Delete-then-add is simpler + atomic for this single-string use case.
        SecItemDelete(common as CFDictionary)
        var add = common
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }
}
