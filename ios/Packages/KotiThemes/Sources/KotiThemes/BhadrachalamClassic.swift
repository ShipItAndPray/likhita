import Foundation
import KotiCore

/// Telugu app default theme — Bhadrachalam Classic.
/// Palette is the design package's `THEMES.bhadrachalam` record.
public struct BhadrachalamClassicTheme: Theme {
    public init() {}

    public let key: ThemeKey = .bhadrachalamClassic
    public let displayName = "Bhadrachalam Classic"
    public let subtitle    = "Red cloth · gold foil · Telugu palm-leaf"
    public let tradition: Tradition? = .telugu

    // Core tokens (kept compatible with prior values).
    public let primaryBrandHex   = "#7A1218"
    public let accentHex         = "#E34234"
    public let surfaceHex        = "#F5E9D0"
    public let surfaceAltHex     = "#F2E4C8"
    public let inkDefaultHex     = "#E34234"
    public let textPrimaryHex    = "#1A1410"
    public let textSecondaryHex  = "#6B4423"
    public let successHex        = "#5F8A3F"
    public let errorHex          = "#8B2500"

    // Book / devotional palette.
    public let clothHex          = "#7A1218"
    public let clothEdgeHex      = "#5C0E14"
    public let foilHex           = "#C9A24A"
    public let pageHex           = "#F5E9D0"
    public let pageRuleHex       = "#7A121814"     // rgba(122,18,24,0.08)
    public let pageWatermarkHex  = "#7A121808"     // rgba(122,18,24,0.03)
    public let chromeBgHex       = "#F2E4C8"
    public let bookInkHex        = "#1A1410"

    public let displayFontName = "TiroTelugu-Regular"
    public let bodyFontName    = "AnekTelugu-Regular"
}
