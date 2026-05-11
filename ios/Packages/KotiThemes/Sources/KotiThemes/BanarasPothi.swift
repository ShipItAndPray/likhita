import Foundation
import KotiCore

/// Hindi app default theme — Banaras Pothi (handmade paper + saffron + gold).
/// Palette is the design package's `THEMES.banaras` record.
public struct BanarasPothiTheme: Theme {
    public init() {}

    public let key: ThemeKey = .banarasPothi
    public let displayName = "Banaras Pothi"
    public let subtitle    = "Saffron cloth · gold · handmade paper"
    public let tradition: Tradition? = .hindi

    public let primaryBrandHex   = "#C2531A"
    public let accentHex         = "#FF7722"
    public let surfaceHex        = "#F0E0C2"
    public let surfaceAltHex     = "#EDD9B5"
    public let inkDefaultHex     = "#1A1410"
    public let textPrimaryHex    = "#1A1410"
    public let textSecondaryHex  = "#5C4033"
    public let successHex        = "#FFA500"
    public let errorHex          = "#8B2500"

    public let clothHex          = "#C2531A"
    public let clothEdgeHex      = "#9A3F12"
    public let foilHex           = "#D4AF37"
    public let pageHex           = "#F0E0C2"
    public let pageRuleHex       = "#9A3F1214"     // rgba(154,63,18,0.08)
    public let pageWatermarkHex  = "#9A3F120A"     // rgba(154,63,18,0.04)
    public let chromeBgHex       = "#EDD9B5"
    public let bookInkHex        = "#1A1410"

    public let displayFontName = "TiroDevanagariHindi-Regular"
    public let bodyFontName    = "Mukta-Regular"
}
