import Foundation
import KotiCore

/// Telugu app default theme. Palette mirrors SPEC.md §20.2 exactly —
/// changing values here is a design decision, not a refactor.
public struct BhadrachalamClassicTheme: Theme {
    public init() {}

    public let key: ThemeKey = .bhadrachalamClassic
    public let displayName = "Bhadrachalam Classic"

    public let primaryBrandHex   = "#8B0000" // Deep red (cloth)
    public let accentHex         = "#D4AF37" // Gold foil
    public let surfaceHex        = "#FFF8DC" // Cream page
    public let surfaceAltHex     = "#F5E6C8" // Aged cream
    public let inkDefaultHex     = "#E34234" // Vermillion
    public let textPrimaryHex    = "#2C1810" // Dark sepia
    public let textSecondaryHex  = "#6B4423" // Medium sepia
    public let successHex        = "#5F8A3F" // Tulsi green
    public let errorHex          = "#8B2500" // Brick red

    public let displayFontName = "TiroTelugu-Regular"
    public let bodyFontName    = "AnekTelugu-Regular"
}
