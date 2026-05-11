import SwiftUI

/// Thin gold arc representing % of the koti complete.
public struct ProgressArc: View {
    let pct: Double
    let foil: Color
    let track: Color
    let size: CGFloat
    let strokeWidth: CGFloat

    public init(
        pct: Double,
        foil: Color,
        track: Color = .black.opacity(0.08),
        size: CGFloat = 56,
        strokeWidth: CGFloat = 3
    ) {
        self.pct = max(0, min(1, pct))
        self.foil = foil
        self.track = track
        self.size = size
        self.strokeWidth = strokeWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(track, lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: pct)
                .stroke(foil, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
