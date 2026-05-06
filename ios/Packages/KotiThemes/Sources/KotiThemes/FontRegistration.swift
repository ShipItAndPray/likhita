import Foundation
#if canImport(UIKit)
import UIKit
import CoreText
#endif

/// Registers bundled font files with CoreText so SwiftUI can resolve them
/// by PostScript name. The actual `.ttf` files for Tiro Telugu, Tiro
/// Devanagari Hindi, Anek Telugu, and Mukta are not bundled yet — link to
/// Google Fonts and drop them into a future `Fonts/` resource group:
///
///   - https://fonts.google.com/specimen/Tiro+Telugu
///   - https://fonts.google.com/specimen/Tiro+Devanagari+Hindi
///   - https://fonts.google.com/specimen/Anek+Telugu
///   - https://fonts.google.com/specimen/Mukta
///
/// Until then, this is a no-op that logs which font names the app expects
/// so designers know what to ship.
public enum FontRegistration {
    public static let expectedFonts: [String] = [
        "TiroTelugu-Regular",
        "TiroDevanagariHindi-Regular",
        "AnekTelugu-Regular",
        "Mukta-Regular"
    ]

    /// Call once at app launch (before any view that uses display fonts).
    public static func registerBundledFonts(in bundle: Bundle = .main) {
        #if canImport(UIKit)
        for fontName in expectedFonts {
            guard let url = bundle.url(forResource: fontName, withExtension: "ttf") else {
                // Font file not yet bundled — UI will fall back to system font.
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }
        #endif
    }
}
