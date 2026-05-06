import Foundation
import KotiCore

/// Hindi app default theme — Banaras Pothi (handmade paper + saffron + gold).
/// Palette per SPEC.md §20.2.
public struct BanarasPothiTheme: Theme {
    public init() {}

    public let key: ThemeKey = .banarasPothi
    public let displayName = "Banaras Pothi"

    public let primaryBrandHex   = "#FF7722" // Saffron
    public let accentHex         = "#D4AF37" // Gold foil
    public let surfaceHex        = "#F5E6D3" // Handmade paper cream
    public let surfaceAltHex     = "#EDD9B8" // Aged tan
    public let inkDefaultHex     = "#1C1C1C" // Lamp-black
    public let textPrimaryHex    = "#2C1810" // Dark sepia
    public let textSecondaryHex  = "#5C4033" // Brown
    public let successHex        = "#FFA500" // Marigold
    public let errorHex          = "#8B2500" // Brick red

    public let displayFontName = "TiroDevanagariHindi-Regular"
    public let bodyFontName    = "Mukta-Regular"
}
