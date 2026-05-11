import SwiftUI

/// One stroke = an array of timed points.
public struct StrokePoint: Hashable, Sendable {
    public let x: CGFloat
    public let y: CGFloat
    public let t: TimeInterval
    public init(x: CGFloat, y: CGFloat, t: TimeInterval) {
        self.x = x; self.y = y; self.t = t
    }
}

public typealias HandwritingStroke = [StrokePoint]

/// Touch-driven calibration surface. User traces the mantra; strokes are
/// captured as point arrays with timing and rendered as variable-width ink
/// (slow = thicker, fast = thinner) — matches handwriting.jsx.
public struct HandwritingCanvas: View {
    let guideText: String
    let guideFontName: String?
    let ink: Color
    let paper: Color
    let foil: Color
    let canvasSize: CGSize
    @Binding var strokes: [HandwritingStroke]

    @State private var current: HandwritingStroke = []
    private let minStrokeLength: CGFloat = 30

    public init(
        guideText: String,
        guideFontName: String? = nil,
        ink: Color,
        paper: Color,
        foil: Color,
        size: CGSize = CGSize(width: 342, height: 180),
        strokes: Binding<[HandwritingStroke]>
    ) {
        self.guideText = guideText
        self.guideFontName = guideFontName
        self.ink = ink
        self.paper = paper
        self.foil = foil
        self.canvasSize = size
        self._strokes = strokes
    }

    public var body: some View {
        ZStack {
            // Guide letterform in the back, very faint.
            Text(guideText)
                .font(guideFontName.map { Font.custom($0, size: min(canvasSize.height * 0.55, 96)) }
                      ?? .system(size: min(canvasSize.height * 0.55, 96)))
                .foregroundStyle(.black.opacity(0.10))
                .kerning(2)
                .allowsHitTesting(false)

            // Baseline
            VStack {
                Spacer()
                ZStack {
                    Rectangle()
                        .strokeBorder(.black.opacity(0.12), style: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .frame(height: 0.5)
                        .padding(.horizontal, 14)
                }
                .frame(height: canvasSize.height * 0.32)
            }
            .allowsHitTesting(false)

            // Stroke layer.
            Canvas { ctx, _ in
                for stroke in strokes { drawStroke(ctx: ctx, stroke: stroke) }
                drawStroke(ctx: ctx, stroke: current)
            }
            .gesture(strokeGesture)

            // Empty hint.
            if strokes.isEmpty && current.isEmpty {
                VStack {
                    Spacer()
                    Text("Trace with your finger — slow strokes pool more ink")
                        .font(.system(size: 11))
                        .italic()
                        .kerning(0.4)
                        .foregroundStyle(.black.opacity(0.5))
                        .padding(.bottom, 8)
                }
                .allowsHitTesting(false)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(foil, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 0, x: 0, y: 0)
    }

    private var strokeGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let p = StrokePoint(
                    x: value.location.x,
                    y: value.location.y,
                    t: Date().timeIntervalSince1970 * 1000
                )
                current.append(p)
            }
            .onEnded { _ in
                let len = current.enumerated().reduce(CGFloat(0)) { acc, item in
                    let i = item.offset
                    guard i > 0 else { return 0 }
                    let prev = current[i - 1]
                    return acc + hypot(item.element.x - prev.x, item.element.y - prev.y)
                }
                if len >= minStrokeLength { strokes.append(current) }
                current = []
            }
    }

    private func drawStroke(ctx: GraphicsContext, stroke: HandwritingStroke) {
        guard stroke.count >= 2 else { return }
        for i in 1..<stroke.count {
            let a = stroke[i - 1]
            let b = stroke[i]
            let dt = max(8, b.t - a.t)
            let dist = hypot(b.x - a.x, b.y - a.y)
            let v = dist / CGFloat(dt)
            let w = max(1.4, min(4.5, 4.5 - v * 8))
            let segment = Path { p in
                p.move(to: CGPoint(x: a.x, y: a.y))
                p.addLine(to: CGPoint(x: b.x, y: b.y))
            }
            ctx.stroke(segment, with: .color(ink),
                       style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Compact preview of a saved stroke set, fits inside a small swatch.
public struct StrokeThumbnail: View {
    let strokes: [HandwritingStroke]
    let ink: Color
    let paper: Color
    let size: CGSize

    public init(strokes: [HandwritingStroke], ink: Color, paper: Color, size: CGSize = CGSize(width: 68, height: 42)) {
        self.strokes = strokes
        self.ink = ink
        self.paper = paper
        self.size = size
    }

    public var body: some View {
        let bounds = computeBounds()
        Canvas { ctx, _ in
            guard let bounds else { return }
            let pad: CGFloat = 4
            let scale = min((size.width - pad * 2) / max(bounds.width, 1),
                            (size.height - pad * 2) / max(bounds.height, 1))
            let offX = (size.width - bounds.width * scale) / 2 - bounds.minX * scale
            let offY = (size.height - bounds.height * scale) / 2 - bounds.minY * scale
            for stroke in strokes where stroke.count >= 2 {
                let path = Path { p in
                    p.move(to: CGPoint(x: stroke[0].x * scale + offX, y: stroke[0].y * scale + offY))
                    for j in 1..<stroke.count {
                        p.addLine(to: CGPoint(x: stroke[j].x * scale + offX, y: stroke[j].y * scale + offY))
                    }
                }
                ctx.stroke(path, with: .color(ink),
                           style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size.width, height: size.height)
        .background(paper)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4).stroke(.black.opacity(0.12), lineWidth: 0.5)
        )
    }

    private func computeBounds() -> CGRect? {
        var minX: CGFloat = .infinity, minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity, maxY: CGFloat = -.infinity
        var seen = false
        for s in strokes {
            for p in s {
                seen = true
                if p.x < minX { minX = p.x }
                if p.y < minY { minY = p.y }
                if p.x > maxX { maxX = p.x }
                if p.y > maxY { maxY = p.y }
            }
        }
        guard seen else { return nil }
        return CGRect(x: minX, y: minY, width: max(1, maxX - minX), height: max(1, maxY - minY))
    }
}
