import Foundation

/// Pure ink-rendering math used by KotiUI's WritingSurface. Lives here
/// (not KotiUI) so it stays unit-testable on Linux/macOS without UIKit.
public struct StylusEngine: Sendable {
    /// User-configured ink color in hex (e.g. "#E34234").
    public let colorHex: String
    /// Maximum jitter (in normalized units 0..1) applied per glyph to give
    /// each entry a hand-written, non-repeating quality.
    public let jitter: Double

    public init(colorHex: String, jitter: Double = 0.015) {
        self.colorHex = colorHex
        self.jitter = jitter
    }

    /// Returns `(red, green, blue, alpha)` in 0..1, derived from
    /// ``colorHex``. Returns black on parse failure.
    public func rgbaComponents() -> (Double, Double, Double, Double) {
        var hex = colorHex
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6 || hex.count == 8 else { return (0, 0, 0, 1) }
        let scanner = Scanner(string: hex)
        var raw: UInt64 = 0
        guard scanner.scanHexInt64(&raw) else { return (0, 0, 0, 1) }
        if hex.count == 6 {
            let r = Double((raw >> 16) & 0xFF) / 255.0
            let g = Double((raw >> 8) & 0xFF) / 255.0
            let b = Double(raw & 0xFF) / 255.0
            return (r, g, b, 1.0)
        } else {
            let r = Double((raw >> 24) & 0xFF) / 255.0
            let g = Double((raw >> 16) & 0xFF) / 255.0
            let b = Double((raw >> 8) & 0xFF) / 255.0
            let a = Double(raw & 0xFF) / 255.0
            return (r, g, b, a)
        }
    }

    /// Returns a deterministic jitter offset in `(-jitter, +jitter)` for a
    /// given entry sequence number. We derive from the sequence so the same
    /// entry always renders identically across re-renders.
    public func jitterOffset(forSequence seq: Int64) -> (dx: Double, dy: Double) {
        let h1 = hash64(UInt64(bitPattern: seq))
        let h2 = hash64(h1 ^ 0xA5A5_A5A5_A5A5_A5A5)
        let dx = (Double(h1 & 0xFFFF) / Double(0xFFFF) - 0.5) * 2.0 * jitter
        let dy = (Double(h2 & 0xFFFF) / Double(0xFFFF) - 0.5) * 2.0 * jitter
        return (dx, dy)
    }

    /// SplitMix64 — small, fast, and avoids constants that look like other
    /// number formats. Source: public-domain reference implementation.
    private func hash64(_ input: UInt64) -> UInt64 {
        var z = input &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
