import SwiftUI
import KotiCore
import KotiThemes

/// Ramayana journey path (SPEC.md §20.4 S10). 7 nodes connected by a curved
/// path; current node pulses, passed nodes are gold-filled, future are
/// outlined. The illustrated SVG ships in a later milestone — this layout
/// validates the right-rail geometry on iPad and the modal shape on iPhone.
public struct ProgressPathView: View {
    public struct Node: Identifiable, Hashable {
        public let id: Int
        public let labelKey: String
        public let position: CGPoint   // 0..1 normalized
        public init(id: Int, labelKey: String, position: CGPoint) {
            self.id = id
            self.labelKey = labelKey
            self.position = position
        }
    }

    public static let defaultNodes: [Node] = [
        .init(id: 0, labelKey: "ayodhya",      position: CGPoint(x: 0.10, y: 0.15)),
        .init(id: 1, labelKey: "chitrakoot",   position: CGPoint(x: 0.30, y: 0.30)),
        .init(id: 2, labelKey: "panchavati",   position: CGPoint(x: 0.50, y: 0.45)),
        .init(id: 3, labelKey: "kishkindha",   position: CGPoint(x: 0.65, y: 0.60)),
        .init(id: 4, labelKey: "ramasetu",     position: CGPoint(x: 0.80, y: 0.72)),
        .init(id: 5, labelKey: "lanka",        position: CGPoint(x: 0.85, y: 0.85)),
        .init(id: 6, labelKey: "pattabhishekam", position: CGPoint(x: 0.50, y: 0.95))
    ]

    @Environment(\.theme) private var theme
    private let nodes: [Node]
    private let currentNodeId: Int
    private let progress: Double  // 0..1

    public init(
        nodes: [Node] = ProgressPathView.defaultNodes,
        currentNodeId: Int = 1,
        progress: Double = 0.42
    ) {
        self.nodes = nodes
        self.currentNodeId = currentNodeId
        self.progress = progress
    }

    public var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            ZStack {
                theme.surface
                ForEach(nodes) { node in
                    Circle()
                        .fill(fill(for: node))
                        .frame(width: 18, height: 18)
                        .position(x: node.position.x * w, y: node.position.y * h)
                        .overlay(
                            Circle()
                                .stroke(theme.accent, lineWidth: node.id == currentNodeId ? 2 : 0)
                                .frame(width: 24, height: 24)
                                .position(x: node.position.x * w, y: node.position.y * h)
                        )
                }
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(Int(progress * 100))% complete")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(theme.textSecondary)
                    }
                    .padding(16)
                }
            }
        }
    }

    private func fill(for node: Node) -> Color {
        if node.id < currentNodeId { return theme.accent }
        if node.id == currentNodeId { return theme.primaryBrand }
        return theme.surfaceAlt
    }
}
