import SwiftUI
import KotiCore
import KotiThemes

/// Type-erased wrapper so we can stash `any AppConfiguration` into the
/// SwiftUI environment without dragging generics through every view.
public struct AnyAppConfiguration: Sendable {
    public let tradition: Tradition
    public let defaultThemeKey: ThemeKey
    public let mantra: MantraChoice
    public let allowMantraSubchoice: Bool
    public let templeDestination: TempleDestination
    public let appName: String
    public let practiceName: String
    public let appOriginHeader: String
    public let apiBaseURL: URL

    public init(_ config: any AppConfiguration) {
        self.tradition = config.tradition
        self.defaultThemeKey = config.defaultThemeKey
        self.mantra = config.mantra
        self.allowMantraSubchoice = config.allowMantraSubchoice
        self.templeDestination = config.templeDestination
        self.appName = config.appName
        self.practiceName = config.practiceName
        self.appOriginHeader = config.appOriginHeader
        self.apiBaseURL = config.apiBaseURL
    }
}

private struct ThemeKeyEnv: EnvironmentKey {
    static let defaultValue: any Theme = BhadrachalamClassicTheme()
}

private struct AppConfigKeyEnv: EnvironmentKey {
    static let defaultValue: AnyAppConfiguration = AnyAppConfiguration(
        FallbackConfig()
    )
}

public extension EnvironmentValues {
    var theme: any Theme {
        get { self[ThemeKeyEnv.self] }
        set { self[ThemeKeyEnv.self] = newValue }
    }
    var appConfig: AnyAppConfiguration {
        get { self[AppConfigKeyEnv.self] }
        set { self[AppConfigKeyEnv.self] = newValue }
    }
}

/// Used only for SwiftUI previews where no real config is injected.
private struct FallbackConfig: AppConfiguration {
    let tradition: Tradition = .telugu
    let defaultThemeKey: ThemeKey = .bhadrachalamClassic
    let mantra: MantraChoice = .srirama
    let allowMantraSubchoice: Bool = false
    let templeDestination: TempleDestination = .bhadrachalam
    let appName: String = "Likhita"
    let practiceName: String = "Koti"
    let bundleId: String = "org.likhita.preview"
    let appOriginHeader: String = "likhita-preview"
    let foundationURL: URL = URL(string: "https://likhita.org")!
    let marketingURL: URL = URL(string: "https://likhita.org")!
    let apiBaseURL: URL = URL(string: "https://api.likhita.org")!
}
