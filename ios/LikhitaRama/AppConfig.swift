import Foundation
import KotiCore
import KotiThemes

/// Build-time configuration for the merged Likhita app.
///
/// After the 2026-05-14 merger ([[likhita-merger-decision]]) this single
/// target (`org.likhita.rama`, renamed "Likhita") serves both traditions.
/// The tradition itself is chosen at runtime by [[LanguagePickerView]];
/// this file just provides the two flavor structs the shell picks from.
///
/// Everything that *doesn't* change between traditions (bundleId,
/// apiBaseURL, foundationURL) is shared; everything that *does* changes
/// per flavor.
public struct AppConfig: AppConfiguration {
    public let tradition: Tradition
    public let defaultThemeKey: ThemeKey
    public let mantra: MantraChoice
    public let allowMantraSubchoice: Bool
    public let templeDestination: TempleDestination
    public let appName: String
    public let practiceName: String
    public let bundleId: String
    public let appOriginHeader: String
    public let foundationURL: URL
    public let marketingURL: URL

    public var apiBaseURL: URL {
        let raw = ProcessInfo.processInfo.environment["LIKHITA_API_BASE"]
            ?? Bundle.main.object(forInfoDictionaryKey: "LikhitaAPIBase") as? String
            ?? "https://api.likhita.org"
        return URL(string: raw) ?? URL(string: "https://api.likhita.org")!
    }

    // ─── Tradition flavors ─────────────────────────────────────

    /// Telugu / Rama Koti / Bhadrachalam.
    public static let rama = AppConfig(
        tradition: .telugu,
        defaultThemeKey: .bhadrachalamClassic,
        mantra: .srirama,
        allowMantraSubchoice: false,
        templeDestination: .bhadrachalam,
        appName: "Likhita",
        practiceName: "Rama Koti",
        bundleId: "org.likhita.rama",
        appOriginHeader: "likhita-rama",
        foundationURL: URL(string: "https://likhita.org")!,
        marketingURL: URL(string: "https://likhitarama.org")!
    )

    /// Hindi / Ram Naam Lekhan / Varanasi Ram Naam Bank.
    public static let ram = AppConfig(
        tradition: .hindi,
        defaultThemeKey: .banarasPothi,
        mantra: .ramOrSitaramSubchoice,
        allowMantraSubchoice: true,
        templeDestination: .ramNaamBank,
        appName: "Likhita",
        practiceName: "Ram Naam Lekhan",
        bundleId: "org.likhita.rama",
        appOriginHeader: "likhita-ram",
        foundationURL: URL(string: "https://likhita.org")!,
        marketingURL: URL(string: "https://likhitaram.org")!
    )

    /// Pick the right flavor for the user's chosen tradition. Called by
    /// `LikhitaShell` after the language picker resolves.
    public static func forTradition(_ t: PracticeTradition) -> AppConfig {
        switch t {
        case .rama: return .rama
        case .ram:  return .ram
        }
    }
}
