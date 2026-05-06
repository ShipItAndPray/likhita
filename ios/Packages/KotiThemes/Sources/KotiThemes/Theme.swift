import SwiftUI
import KotiCore

/// Visual contract a theme must satisfy. Hex strings keep the protocol
/// platform-agnostic and round-trippable to JSON for server sync of
/// purchased themes (SPEC.md §19 GET /v1/themes).
public protocol Theme: Sendable {
    var key: ThemeKey { get }
    var displayName: String { get }

    var primaryBrandHex: String { get }
    var accentHex: String { get }
    var surfaceHex: String { get }
    var surfaceAltHex: String { get }
    var inkDefaultHex: String { get }
    var textPrimaryHex: String { get }
    var textSecondaryHex: String { get }
    var successHex: String { get }
    var errorHex: String { get }

    /// Display font for large headings (e.g. Tiro Telugu / Tiro Devanagari).
    var displayFontName: String { get }
    /// Body / UI chrome font (e.g. Anek Telugu / Mukta).
    var bodyFontName: String { get }
}

/// SwiftUI color sugar.
public extension Theme {
    var primaryBrand: Color { Color(hex: primaryBrandHex) }
    var accent: Color { Color(hex: accentHex) }
    var surface: Color { Color(hex: surfaceHex) }
    var surfaceAlt: Color { Color(hex: surfaceAltHex) }
    var inkDefault: Color { Color(hex: inkDefaultHex) }
    var textPrimary: Color { Color(hex: textPrimaryHex) }
    var textSecondary: Color { Color(hex: textSecondaryHex) }
    var success: Color { Color(hex: successHex) }
    var error: Color { Color(hex: errorHex) }
}

/// Resolves a `ThemeKey` to a concrete `Theme` instance. v1 ships with two
/// (Bhadrachalam Classic + Banaras Pothi); other keys fall back to the
/// closest sibling so the UI never crashes if the server returns an
/// unrecognized theme.
public enum ThemeRegistry {
    public static func theme(for key: ThemeKey) -> Theme {
        switch key {
        case .bhadrachalamClassic, .palmLeafOla, .tirupatiSaffron:
            return BhadrachalamClassicTheme()
        case .banarasPothi, .ayodhyaSandstone, .tulsidasManuscript:
            return BanarasPothiTheme()
        case .parchment, .modernMinimalist:
            return BhadrachalamClassicTheme()
        }
    }
}
