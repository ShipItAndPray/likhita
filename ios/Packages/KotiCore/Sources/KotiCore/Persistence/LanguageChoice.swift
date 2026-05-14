import Foundation

/// User's first-launch language + tradition choice. Persisted in
/// `UserDefaults` so it survives app restarts but NOT reinstalls — that
/// matches the design's "permanent until reinstall" contract.
///
/// Keychain would survive reinstall too, but the design ([[chat1 lang
/// picker beat]]) makes reinstall the explicit reset path. UserDefaults
/// is the correct surface.
public enum LanguageCode: String, Codable, Sendable, CaseIterable {
    case english = "en"
    case hindi = "hi"
    case telugu = "te"
}

/// Which devotional tradition the user is practicing. Maps onto the
/// `Tradition` enum already in this module — kept distinct so the
/// language picker can express "English speaker who picked Rama Koti"
/// without collapsing the language layer.
public enum PracticeTradition: String, Codable, Sendable, CaseIterable {
    case rama  // Telugu / Bhadrachalam
    case ram   // Hindi  / Varanasi (Ram Naam Bank)

    public var tradition: Tradition {
        switch self {
        case .rama: return .telugu
        case .ram:  return .hindi
        }
    }
}

public struct LanguageChoice: Codable, Sendable, Equatable {
    public let language: LanguageCode
    public let tradition: PracticeTradition
    public let pickedAt: Date

    public init(language: LanguageCode, tradition: PracticeTradition, pickedAt: Date = .init()) {
        self.language = language
        self.tradition = tradition
        self.pickedAt = pickedAt
    }
}

/// Reads / writes the first-launch choice. Uses the standard suite so
/// the value lives next to the rest of [[koti-store]] state and wipes
/// on uninstall.
public final class LanguageChoiceStore: @unchecked Sendable {
    public static let shared = LanguageChoiceStore(suite: nil)

    private let defaults: UserDefaults
    private let key = "likhita.languageChoice.v1"

    public init(suite: String?) {
        if let suite, let custom = UserDefaults(suiteName: suite) {
            self.defaults = custom
        } else {
            self.defaults = .standard
        }
    }

    /// Current choice, or `nil` if the user hasn't seen the picker yet.
    public var current: LanguageChoice? {
        get {
            guard let data = defaults.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(LanguageChoice.self, from: data)
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }
    }

    /// UI-testing override path: forget the choice so the picker re-runs.
    /// Production code never calls this; the contract is reinstall-only.
    public func resetForUITesting() {
        defaults.removeObject(forKey: key)
    }
}
