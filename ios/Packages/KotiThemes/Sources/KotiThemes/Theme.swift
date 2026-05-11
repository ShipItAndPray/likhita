import SwiftUI
import KotiCore

/// Visual contract a theme must satisfy. Hex strings keep the protocol
/// platform-agnostic and round-trippable to JSON for server sync of
/// purchased themes (SPEC.md §19 GET /v1/themes).
///
/// The "book" subset (cloth/foil/page/...) maps directly onto the design
/// package's theme records — see /tmp/likhita-design data.jsx.
public protocol Theme: Sendable {
    var key: ThemeKey { get }
    var displayName: String { get }
    var subtitle: String { get }

    // Core token surface.
    var primaryBrandHex: String { get }
    var accentHex: String { get }
    var surfaceHex: String { get }
    var surfaceAltHex: String { get }
    var inkDefaultHex: String { get }
    var textPrimaryHex: String { get }
    var textSecondaryHex: String { get }
    var successHex: String { get }
    var errorHex: String { get }

    // Book/devotional palette (matches design's THEMES record).
    var clothHex: String { get }
    var clothEdgeHex: String { get }
    var foilHex: String { get }
    var pageHex: String { get }
    var pageRuleHex: String { get }      // expects rgba — keep as hex+alpha
    var pageWatermarkHex: String { get }
    var chromeBgHex: String { get }
    var bookInkHex: String { get }       // page text ink (distinct from inkDefault stylus default)

    /// Display font for large headings (e.g. Tiro Telugu / Tiro Devanagari).
    var displayFontName: String { get }
    /// Body / UI chrome font (e.g. Anek Telugu / Mukta).
    var bodyFontName: String { get }

    /// Which tradition this theme belongs to (`nil` = universal, e.g. PalmLeaf).
    var tradition: Tradition? { get }
}

public extension Theme {
    var subtitle: String { "" }
    var tradition: Tradition? { nil }

    var primaryBrand: Color { Color(hex: primaryBrandHex) }
    var accent: Color { Color(hex: accentHex) }
    var surface: Color { Color(hex: surfaceHex) }
    var surfaceAlt: Color { Color(hex: surfaceAltHex) }
    var inkDefault: Color { Color(hex: inkDefaultHex) }
    var textPrimary: Color { Color(hex: textPrimaryHex) }
    var textSecondary: Color { Color(hex: textSecondaryHex) }
    var success: Color { Color(hex: successHex) }
    var error: Color { Color(hex: errorHex) }

    var cloth: Color { Color(hex: clothHex) }
    var clothEdge: Color { Color(hex: clothEdgeHex) }
    var foil: Color { Color(hex: foilHex) }
    var page: Color { Color(hex: pageHex) }
    var pageRule: Color { Color(hex: pageRuleHex) }
    var pageWatermark: Color { Color(hex: pageWatermarkHex) }
    var chromeBg: Color { Color(hex: chromeBgHex) }
    var bookInk: Color { Color(hex: bookInkHex) }
}

/// Resolves a `ThemeKey` to a concrete `Theme` instance. v1 ships with
/// Bhadrachalam Classic, Banaras Pothi, and Palm-leaf Ola; remaining
/// keys fall back to the closest sibling so the UI never crashes if the
/// server returns an unrecognized theme.
public enum ThemeRegistry {
    public static func theme(for key: ThemeKey) -> Theme {
        switch key {
        case .bhadrachalamClassic, .tirupatiSaffron:
            return BhadrachalamClassicTheme()
        case .palmLeafOla:
            return PalmLeafOlaTheme()
        case .banarasPothi, .ayodhyaSandstone, .tulsidasManuscript:
            return BanarasPothiTheme()
        case .parchment, .modernMinimalist:
            return BhadrachalamClassicTheme()
        }
    }

    /// Themes available for a tradition. Includes the universal Palm-leaf.
    public static func themes(for tradition: Tradition) -> [Theme] {
        let all: [Theme] = [
            BhadrachalamClassicTheme(),
            BanarasPothiTheme(),
            PalmLeafOlaTheme(),
        ]
        return all.filter { $0.tradition == nil || $0.tradition == tradition }
    }
}
