import SwiftUI
import KotiCore
import KotiThemes

/// Full-screen overlay — the Ramayana journey map.
/// Geometric path with 7 nodes; current pulses, passed are gold-filled,
/// future are outlined.
public struct RamayanaPathView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let progress: Double
    let onClose: () -> Void

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        progress: Double,
        onClose: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.progress = progress
        self.onClose = onClose
    }

    public var body: some View {
        let currentIdx = MilestoneCatalog.currentIndex(forProgress: progress)
        ZStack {
            theme.cloth.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("THE RAMAYANA JOURNEY")
                        .font(.system(size: 11))
                        .kerning(2)
                        .foregroundStyle(theme.page.opacity(0.65))
                    Spacer()
                    Button(action: onClose) {
                        Text("✕")
                            .font(.system(size: 22))
                            .foregroundStyle(theme.page.opacity(0.65))
                    }
                }
                .padding(.top, 54)

                Text("\(String(format: "%.1f", progress * 100))% along the path")
                    .font(.custom("EB Garamond", size: 24))
                    .italic()
                    .foregroundStyle(theme.page)
                    .padding(.top, 8)

                GoldRule(foil: theme.foil, width: 300)
                    .padding(.top, 14)

                pathCanvas(currentIdx: currentIdx)
                    .frame(maxWidth: .infinity, minHeight: 380)
                    .padding(.top, 20)

                MilestoneCard(
                    milestone: MilestoneCatalog.path[currentIdx],
                    tradition: tradition,
                    theme: theme
                )
                .padding(.top, 14)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .foregroundStyle(theme.page)
        .transition(.opacity)
    }

    private func pathCanvas(currentIdx: Int) -> some View {
        let positions: [CGPoint] = [
            CGPoint(x: 60,  y: 60),
            CGPoint(x: 280, y: 90),
            CGPoint(x: 80,  y: 160),
            CGPoint(x: 290, y: 220),
            CGPoint(x: 70,  y: 290),
            CGPoint(x: 280, y: 350),
            CGPoint(x: 180, y: 420),
        ]
        return GeometryReader { geo in
            let scale = min(geo.size.width / 360, 1.2)
            let labelKey = tradition.scriptKey == "telugu" ? Tradition.telugu : Tradition.hindi
            ZStack {
                Canvas { ctx, _ in
                    var path = Path()
                    for (i, p) in positions.enumerated() {
                        let scaled = CGPoint(x: p.x * scale, y: p.y * scale)
                        if i == 0 {
                            path.move(to: scaled)
                        } else {
                            let prev = positions[i - 1]
                            let prevScaled = CGPoint(x: prev.x * scale, y: prev.y * scale)
                            let cx = (prevScaled.x + scaled.x) / 2
                            path.addQuadCurve(
                                to: scaled,
                                control: CGPoint(x: cx, y: prevScaled.y)
                            )
                        }
                    }
                    ctx.stroke(
                        path,
                        with: .color(theme.foil.opacity(0.5)),
                        style: StrokeStyle(lineWidth: 0.6, dash: [2, 3])
                    )
                }

                ForEach(Array(positions.enumerated()), id: \.offset) { i, p in
                    let isCurrent = (i == currentIdx)
                    let reached = (i <= currentIdx)
                    let m = MilestoneCatalog.path[i]
                    let xy = CGPoint(x: p.x * scale, y: p.y * scale)
                    ZStack {
                        if isCurrent {
                            Circle()
                                .fill(theme.foil.opacity(0.18))
                                .frame(width: 44, height: 44)
                                .modifier(HaloAnimation())
                        }
                        Circle()
                            .strokeBorder(theme.foil, lineWidth: 1)
                            .background(Circle().fill(reached ? theme.foil : Color.clear))
                            .frame(width: 18, height: 18)
                        if reached {
                            Circle()
                                .fill(theme.cloth)
                                .frame(width: 7, height: 7)
                        }
                    }
                    .position(xy)

                    let leftSide = (i % 2 == 0)
                    let labelOffsetX: CGFloat = leftSide ? 16 : -16
                    Text(m.label(for: labelKey))
                        .font(.custom(tradition.displayFontKey, size: 13))
                        .foregroundStyle(theme.page.opacity(reached ? 1 : 0.5))
                        .multilineTextAlignment(leftSide ? .leading : .trailing)
                        .position(x: xy.x + labelOffsetX, y: xy.y + 4)
                        .frame(width: 140, alignment: leftSide ? .leading : .trailing)
                        .offset(x: leftSide ? 70 : -70)

                    Text(m.englishLabel)
                        .font(.custom("EB Garamond", size: 9))
                        .italic()
                        .kerning(0.3)
                        .foregroundStyle(theme.foil.opacity(reached ? 0.85 : 0.4))
                        .position(x: xy.x + labelOffsetX, y: xy.y + 18)
                        .frame(width: 140, alignment: leftSide ? .leading : .trailing)
                        .offset(x: leftSide ? 70 : -70)
                }
            }
        }
    }
}

private struct MilestoneCard: View {
    let milestone: Milestone
    let tradition: TraditionContent
    let theme: any Theme
    var body: some View {
        let labelKey = tradition.scriptKey == "telugu" ? Tradition.telugu : Tradition.hindi
        VStack(alignment: .leading, spacing: 4) {
            Text("YOU ARE AT")
                .font(.system(size: 10))
                .kerning(1.5)
                .foregroundStyle(theme.page.opacity(0.6))
            Text(milestone.label(for: labelKey))
                .font(.custom(tradition.displayFontKey, size: 22))
                .foregroundStyle(theme.page)
            Text(milestone.note)
                .font(.custom("EB Garamond", size: 13))
                .italic()
                .foregroundStyle(theme.page.opacity(0.78))
                .lineSpacing(3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.18))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(theme.foil, lineWidth: 0.5)
        )
    }
}

private struct HaloAnimation: ViewModifier {
    @State private var grow: Bool = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(grow ? 1.4 : 1.0)
            .opacity(grow ? 0.05 : 0.3)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    grow = true
                }
            }
    }
}
