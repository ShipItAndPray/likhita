import Foundation
import KotiCore

/// Universal "Palm-leaf · Ola" theme — earthy ola texture with etched
/// lettering. Mirrors the design's `THEMES.palmleaf` record. Available
/// to either tradition (the design treats it as universal — both apps
/// can switch in).
public struct PalmLeafOlaTheme: Theme {
    public init() {}

    public let key: ThemeKey = .palmLeafOla
    public let displayName = "Palm-leaf · Ola"
    public let subtitle    = "Ola texture · etched lettering"
    public let tradition: Tradition? = nil

    public let primaryBrandHex   = "#6B4226"
    public let accentHex         = "#7A4424"
    public let surfaceHex        = "#D9BE8A"
    public let surfaceAltHex     = "#C9AC75"
    public let inkDefaultHex     = "#2A1A0C"
    public let textPrimaryHex    = "#2A1A0C"
    public let textSecondaryHex  = "#5C4033"
    public let successHex        = "#5F8A3F"
    public let errorHex          = "#8B2500"

    public let clothHex          = "#6B4226"
    public let clothEdgeHex      = "#4A2D18"
    public let foilHex           = "#A07B3E"
    public let pageHex           = "#D9BE8A"
    public let pageRuleHex       = "#3C2812"
    public let pageWatermarkHex  = "#3C28120D"
    public let chromeBgHex       = "#C9AC75"
    public let bookInkHex        = "#2A1A0C"

    public let displayFontName = "TiroTelugu-Regular"
    public let bodyFontName    = "AnekTelugu-Regular"
}
