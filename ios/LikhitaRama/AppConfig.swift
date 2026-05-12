import Foundation
import KotiCore
import KotiThemes

/// Telugu-app build-time configuration. Read by shared packages to skin
/// behavior — no `#if` conditionals scattered through the codebase.
/// See SPEC.md §16 "Build configuration".
public struct AppConfig: AppConfiguration {
    public static let shared = AppConfig()

    public let tradition: Tradition = .telugu
    public let defaultThemeKey: ThemeKey = .bhadrachalamClassic
    public let mantra: MantraChoice = .srirama
    public let allowMantraSubchoice: Bool = false
    public let templeDestination: TempleDestination = .bhadrachalam
    public let appName: String = "Likhita Rama"
    public let practiceName: String = "Rama Koti"
    public let bundleId: String = "org.likhita.rama"
    public let appOriginHeader: String = "likhita-rama"
    public let foundationURL: URL = URL(string: "https://likhita.org")!
    public let marketingURL: URL = URL(string: "https://likhitarama.org")!

    /// Reads `LikhitaAPIBase` from the LIKHITA_API_BASE env var first (so UI
    /// tests can point Debug builds at a real backend without rebuilding),
    /// then falls back to Info.plist (xcodegen sets per-config).
    public var apiBaseURL: URL {
        let raw = ProcessInfo.processInfo.environment["LIKHITA_API_BASE"]
            ?? Bundle.main.object(forInfoDictionaryKey: "LikhitaAPIBase") as? String
            ?? "https://api.likhita.org"
        return URL(string: raw) ?? URL(string: "https://api.likhita.org")!
    }

    private init() {}
}
