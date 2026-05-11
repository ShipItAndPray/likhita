import SwiftUI

/// One rendered mantra instance — the unit that fills the book grid.
/// Deterministic micro-jitter (rotation, offset, opacity) gives the
/// illusion of handwritten ink while keeping rendering pure (same seed
/// → same look, so SwiftUI can reuse render output).
public struct MantraEntry: View {
    let mantra: String
    let fontName: String?
    let color: Color
    let seed: Int
    let size: CGFloat

    public init(mantra: String, fontName: String? = nil, color: Color, seed: Int, size: CGFloat = 14) {
        self.mantra = mantra
        self.fontName = fontName
        self.color = color
        self.seed = seed
        self.size = size
    }

    public var body: some View {
        let r1 = pseudoRandom(seed: seed, mul: 9301, add: 49297, mod: 233_280)
        let r2 = pseudoRandom(seed: seed, mul: 1103, add: 12345, mod: 65_536)
        let r3 = pseudoRandom(seed: seed, mul: 2654, add: 877,   mod: 65_536)
        let rotate = (r1 - 0.5) * 2.4   // ±1.2°
        let dx = (r2 - 0.5) * 1.6       // ±0.8px
        let dy = (r3 - 0.5) * 1.4       // ±0.7px
        let opacity = 0.78 + r1 * 0.22  // 0.78..1

        Text(mantra)
            .font(fontName.map { Font.custom($0, size: size) } ?? .system(size: size))
            .foregroundStyle(color)
            .opacity(opacity)
            .lineLimit(1)
            .fixedSize()
            .rotationEffect(.degrees(rotate))
            .offset(x: dx, y: dy)
    }

    private func pseudoRandom(seed: Int, mul: Int, add: Int, mod: Int) -> Double {
        let v = abs((seed &* mul) &+ add) % mod
        return Double(v) / Double(mod)
    }
}
