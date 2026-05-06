import SwiftUI

/// Initialize a SwiftUI `Color` from a `#RRGGBB` or `#RRGGBBAA` hex string.
/// Falls back to opaque black if the string is malformed — themes are
/// curated, so a malformed hex indicates a typo we want to spot in QA.
public extension Color {
    init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") { trimmed.removeFirst() }
        guard trimmed.count == 6 || trimmed.count == 8 else {
            self = .black
            return
        }
        let scanner = Scanner(string: trimmed)
        var raw: UInt64 = 0
        guard scanner.scanHexInt64(&raw) else {
            self = .black
            return
        }
        let r, g, b, a: Double
        if trimmed.count == 6 {
            r = Double((raw >> 16) & 0xFF) / 255.0
            g = Double((raw >> 8) & 0xFF) / 255.0
            b = Double(raw & 0xFF) / 255.0
            a = 1.0
        } else {
            r = Double((raw >> 24) & 0xFF) / 255.0
            g = Double((raw >> 16) & 0xFF) / 255.0
            b = Double((raw >> 8) & 0xFF) / 255.0
            a = Double(raw & 0xFF) / 255.0
        }
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
