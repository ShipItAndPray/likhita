import SwiftUI

/// Geometric foil ornaments matching the design package's components.jsx.
/// All decoration is abstract (lines, dots, lozenges) — never figurative.

/// Gold double-rule with center diamond — section divider.
public struct GoldRule: View {
    let foil: Color
    let width: CGFloat

    public init(foil: Color, width: CGFloat = 200) {
        self.foil = foil
        self.width = width
    }

    public var body: some View {
        Canvas { ctx, size in
            let h = size.height
            let w = size.width
            let top = h * (3.0/14.0)
            let bot = h * (11.0/14.0)
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 0, y: top))
                    p.addLine(to: CGPoint(x: w, y: top))
                },
                with: .color(foil),
                lineWidth: 0.6
            )
            ctx.stroke(
                Path { p in
                    p.move(to: CGPoint(x: 0, y: bot))
                    p.addLine(to: CGPoint(x: w, y: bot))
                },
                with: .color(foil),
                lineWidth: 0.6
            )
            // center diamond at midpoint
            let cx = w / 2
            let cy = h / 2
            let d: CGFloat = 5.6
            let outer = Path { p in
                p.move(to: CGPoint(x: cx, y: cy - d))
                p.addLine(to: CGPoint(x: cx + d, y: cy))
                p.addLine(to: CGPoint(x: cx, y: cy + d))
                p.addLine(to: CGPoint(x: cx - d, y: cy))
                p.closeSubpath()
            }
            ctx.fill(outer, with: .color(foil))
            let inner = Path { p in
                let i: CGFloat = 3.1
                p.move(to: CGPoint(x: cx, y: cy - i))
                p.addLine(to: CGPoint(x: cx + i, y: cy))
                p.addLine(to: CGPoint(x: cx, y: cy + i))
                p.addLine(to: CGPoint(x: cx - i, y: cy))
                p.closeSubpath()
            }
            ctx.fill(inner, with: .color(.white.opacity(0.18)))
        }
        .frame(width: width, height: 14)
        .accessibilityHidden(true)
    }
}

/// Concentric squares + dot — corner flourish.
public struct CornerFlourish: View {
    let foil: Color
    let size: CGFloat

    public init(foil: Color, size: CGFloat = 28) {
        self.foil = foil
        self.size = size
    }

    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .stroke(foil, lineWidth: 0.5)
                .padding(2)
            RoundedRectangle(cornerRadius: 0)
                .stroke(foil, lineWidth: 0.5)
                .padding(5)
            Circle()
                .fill(foil)
                .frame(width: size * 0.115, height: size * 0.115)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// "Sri" yantra — abstract geometric (NOT figurative).
public struct SriYantra: View {
    let foil: Color
    let size: CGFloat

    public init(foil: Color, size: CGFloat = 64) {
        self.foil = foil
        self.size = size
    }

    public var body: some View {
        Canvas { ctx, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let scale = s / 64.0
            let center = CGPoint(x: s / 2, y: s / 2)

            ctx.stroke(
                Path(ellipseIn: CGRect(x: center.x - 28*scale, y: center.y - 28*scale, width: 56*scale, height: 56*scale)),
                with: .color(foil), lineWidth: 0.6
            )
            ctx.stroke(
                Path(ellipseIn: CGRect(x: center.x - 22*scale, y: center.y - 22*scale, width: 44*scale, height: 44*scale)),
                with: .color(foil), lineWidth: 0.6
            )
            // upward triangle (32,12)-(50,42)-(14,42)
            let up = Path { p in
                p.move(to: CGPoint(x: 32*scale, y: 12*scale))
                p.addLine(to: CGPoint(x: 50*scale, y: 42*scale))
                p.addLine(to: CGPoint(x: 14*scale, y: 42*scale))
                p.closeSubpath()
            }
            ctx.stroke(up, with: .color(foil), lineWidth: 0.7)
            // downward triangle (32,52)-(14,22)-(50,22)
            let down = Path { p in
                p.move(to: CGPoint(x: 32*scale, y: 52*scale))
                p.addLine(to: CGPoint(x: 14*scale, y: 22*scale))
                p.addLine(to: CGPoint(x: 50*scale, y: 22*scale))
                p.closeSubpath()
            }
            ctx.stroke(down, with: .color(foil), lineWidth: 0.7)
            // center dot
            let dot = Path(ellipseIn: CGRect(
                x: center.x - 2.5*scale, y: center.y - 2.5*scale,
                width: 5*scale, height: 5*scale
            ))
            ctx.fill(dot, with: .color(foil))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Lotus border — alternating dots, abstract petals.
public struct PetalBorder: View {
    let foil: Color
    let width: CGFloat

    public init(foil: Color, width: CGFloat = 280) {
        self.foil = foil
        self.width = width
    }

    public var body: some View {
        Canvas { ctx, size in
            let count = max(1, Int(size.width / 8))
            for i in 0..<count {
                let x: CGFloat = 4 + CGFloat(i) * 8
                let r: CGFloat = (i % 2 == 0) ? 1.6 : 0.8
                let opacity: Double = (i % 2 == 0) ? 1.0 : 0.5
                let dot = Path(ellipseIn: CGRect(x: x - r, y: 3 - r, width: r*2, height: r*2))
                ctx.fill(dot, with: .color(foil.opacity(opacity)))
            }
        }
        .frame(width: width, height: 6)
        .accessibilityHidden(true)
    }
}
