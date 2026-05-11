import SwiftUI
import KotiThemes

/// Cream paper card with subtle radial watermark.
public struct BookPage<Content: View>: View {
    let theme: any Theme
    let padding: CGFloat
    let ruleSpacing: CGFloat?         // nil = no rule lines
    let minHeight: CGFloat?
    let content: () -> Content

    public init(
        theme: any Theme,
        padding: CGFloat = 18,
        ruleSpacing: CGFloat? = nil,
        minHeight: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.theme = theme
        self.padding = padding
        self.ruleSpacing = ruleSpacing
        self.minHeight = minHeight
        self.content = content
    }

    public var body: some View {
        ZStack {
            theme.page
            // paper grain — two soft radial watermarks
            Canvas { ctx, size in
                let r1 = CGRect(x: size.width * 0.05, y: -size.height * 0.10,
                                width: size.width * 0.7, height: size.height * 0.8)
                ctx.fill(Path(ellipseIn: r1), with: .color(theme.pageWatermark.opacity(0.6)))
                let r2 = CGRect(x: size.width * 0.35, y: size.height * 0.4,
                                width: size.width * 0.7, height: size.height * 0.85)
                ctx.fill(Path(ellipseIn: r2), with: .color(theme.pageWatermark.opacity(0.45)))
            }
            .blendMode(.multiply)
            .allowsHitTesting(false)

            if let spacing = ruleSpacing {
                ruleLines(spacing: spacing)
                    .allowsHitTesting(false)
            }

            content()
                .padding(padding)
        }
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .background(theme.page)
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(.black.opacity(0.05), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 1.5, x: 0, y: 1)
    }

    private func ruleLines(spacing: CGFloat) -> some View {
        Canvas { ctx, size in
            var y: CGFloat = spacing
            while y < size.height {
                let line = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                ctx.stroke(line, with: .color(theme.pageRule), lineWidth: 1)
                y += spacing
            }
        }
    }
}

/// Bound book wrapper — page surface with a dark cloth spine on the
/// left edge (matches BookSpread in components.jsx).
public struct BookSpread<Content: View>: View {
    let theme: any Theme
    let content: () -> Content

    public init(theme: any Theme, @ViewBuilder content: @escaping () -> Content) {
        self.theme = theme
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(theme.page)

            // binding shadow on left
            LinearGradient(
                stops: [
                    .init(color: theme.clothEdge,           location: 0.00),
                    .init(color: theme.clothEdge,           location: 0.28),
                    .init(color: Color.black.opacity(0.18), location: 0.43),
                    .init(color: Color.black.opacity(0.0),  location: 1.00),
                ],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: 14)
            .allowsHitTesting(false)
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 8)
        .shadow(color: .black.opacity(0.10), radius: 1.5, x: 0, y: 1)
    }
}
