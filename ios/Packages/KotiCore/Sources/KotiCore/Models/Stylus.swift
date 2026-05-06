import Foundation

/// Stylus configuration captured during Sankalpam Step 4 calibration.
/// `signatureHash` is the server-side fingerprint of the user's calibration
/// strokes; subsequent entries are validated against it for cadence drift.
public struct Stylus: Codable, Sendable, Hashable {
    /// Hex color (e.g. "#E34234"). 12 swatches per spec §20.4 S6.
    public let colorHex: String
    public let signatureHash: String
    public let calibratedAt: Date

    public init(colorHex: String, signatureHash: String, calibratedAt: Date) {
        self.colorHex = colorHex
        self.signatureHash = signatureHash
        self.calibratedAt = calibratedAt
    }
}

/// 12 ink swatches offered during calibration (SPEC.md §20.4 S6).
/// Hex values chosen to evoke traditional inks (vermillion, lamp-black,
/// turmeric, indigo, etc.) without committing to per-theme palettes here.
public enum InkSwatch {
    public static let palette: [String] = [
        "#E34234", "#1C1C1C", "#8B0000", "#4B0082",
        "#5F8A3F", "#D4AF37", "#FF7722", "#3B2F2F",
        "#0F4C5C", "#7B3F00", "#A0522D", "#2C1810"
    ]
}
