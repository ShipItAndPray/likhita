import SwiftUI

/// Flow-layout horizontal stack that wraps onto multiple lines when content
/// exceeds the available width. Used for the dedication-preset chips.
public struct FlexibleHStack<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: () -> Content

    public init(
        spacing: CGFloat = 8,
        lineSpacing: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    public var body: some View {
        FlowLayoutContainer(spacing: spacing, lineSpacing: lineSpacing) {
            content()
        }
    }
}

private struct FlowLayoutContainer<Content: View>: View {
    let spacing: CGFloat
    let lineSpacing: CGFloat
    let content: () -> Content

    init(spacing: CGFloat, lineSpacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.lineSpacing = lineSpacing
        self.content = content
    }

    var body: some View {
        FlowLayout(spacing: spacing, lineSpacing: lineSpacing) {
            content()
        }
    }
}

/// SwiftUI Layout (iOS 16+) that lays subviews left-to-right and wraps.
private struct FlowLayout: Layout {
    let spacing: CGFloat
    let lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let available = proposal.width ?? .infinity
        let rows = computeRows(available: available, subviews: subviews)
        let height = rows.reduce(CGFloat(0)) { $0 + $1.height + lineSpacing } - (rows.isEmpty ? 0 : lineSpacing)
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, available), height: max(0, height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let available = bounds.width
        let rows = computeRows(available: available, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func computeRows(available: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for (i, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            let prospective = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if prospective > available && !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            if current.indices.isEmpty {
                current.width = size.width
            } else {
                current.width += spacing + size.width
            }
            current.height = max(current.height, size.height)
            current.indices.append(i)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
