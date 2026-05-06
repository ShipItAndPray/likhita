import Foundation

/// Which devotional tradition a koti follows. Drives mantra rendering,
/// localized labels, and which temple destination is offered.
public enum Tradition: String, Codable, Sendable, CaseIterable {
    case telugu
    case hindi
}

/// User-selected mantra. The Hindi app exposes `.ramOrSitaramSubchoice` as
/// a placeholder until Sankalpam Step 0 resolves it to `.ram` or `.sitaram`.
public enum MantraChoice: String, Codable, Sendable, CaseIterable {
    case srirama
    case ram
    case sitaram
    case ramOrSitaramSubchoice
}

/// Where a completed koti book is shipped on the user's behalf.
public enum TempleDestination: String, Codable, Sendable, CaseIterable {
    case bhadrachalam
    case ramNaamBank
    case ayodhya
}

/// Identifies a theme without binding to its concrete asset implementation.
/// Concrete themes live in KotiThemes; KotiCore stays asset-free.
public enum ThemeKey: String, Codable, Sendable, CaseIterable {
    case bhadrachalamClassic
    case palmLeafOla
    case tirupatiSaffron
    case banarasPothi
    case ayodhyaSandstone
    case tulsidasManuscript
    case parchment
    case modernMinimalist
}

/// Practice modes per SPEC.md §21.
public enum KotiMode: String, Codable, Sendable, CaseIterable {
    case trial
    case lakh
    case crore

    /// Target mantra count for this mode.
    public var targetCount: Int64 {
        switch self {
        case .trial: return 108
        case .lakh: return 100_000
        case .crore: return 10_000_000
        }
    }
}

/// Build-time configuration contract — each app target supplies a concrete
/// value. Shared packages read from this protocol; never import target code.
public protocol AppConfiguration: Sendable {
    var tradition: Tradition { get }
    var defaultThemeKey: ThemeKey { get }
    var mantra: MantraChoice { get }
    var allowMantraSubchoice: Bool { get }
    var templeDestination: TempleDestination { get }
    var appName: String { get }
    var practiceName: String { get }
    var bundleId: String { get }
    var appOriginHeader: String { get }
    var foundationURL: URL { get }
    var marketingURL: URL { get }
    var apiBaseURL: URL { get }
}
