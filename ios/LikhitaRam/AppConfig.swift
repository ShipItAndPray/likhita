import Foundation
import KotiCore
import KotiThemes

/// Hindi-app build-time configuration. Mantra sub-choice (Ram / Sitaram) is
/// resolved in Sankalpam Step 0 — see SPEC.md §21.
public struct AppConfig: AppConfiguration {
    public static let shared = AppConfig()

    public let tradition: Tradition = .hindi
    public let defaultThemeKey: ThemeKey = .banarasPothi
    public let mantra: MantraChoice = .ramOrSitaramSubchoice
    public let allowMantraSubchoice: Bool = true
    public let templeDestination: TempleDestination = .ramNaamBank
    public let appName: String = "Likhita Ram"
    public let practiceName: String = "Ram Naam Lekhan"
    public let bundleId: String = "org.likhita.ram"
    public let appOriginHeader: String = "likhita-ram"
    public let foundationURL: URL = URL(string: "https://likhita.org")!
    public let marketingURL: URL = URL(string: "https://likhitaram.org")!

    public var apiBaseURL: URL {
        let raw = ProcessInfo.processInfo.environment["LIKHITA_API_BASE"]
            ?? Bundle.main.object(forInfoDictionaryKey: "LikhitaAPIBase") as? String
            ?? "https://api.likhita.org"
        return URL(string: raw) ?? URL(string: "https://api.likhita.org")!
    }

    private init() {}
}
