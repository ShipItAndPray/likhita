import SwiftUI
import KotiThemes

/// Press-and-hold confirmation button. Used for the Sankalpam pledge —
/// the user must commit physically before the koti begins.
public struct HoldButton: View {
    let duration: Double
    let onComplete: () -> Void
    let theme: any Theme
    let label: String

    @State private var progress: Double = 0
    @State private var isPressing: Bool = false
    @State private var startedAt: Date?

    public init(
        duration: Double = 1.8,
        theme: any Theme,
        label: String,
        onComplete: @escaping () -> Void
    ) {
        self.duration = duration
        self.theme = theme
        self.label = label
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cloth)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.foil, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 12, x: 0, y: 4)

            GeometryReader { geo in
                Rectangle()
                    .fill(theme.foil.opacity(0.85))
                    .frame(width: geo.size.width * progress)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .animation(progress == 0 ? .easeOut(duration: 0.2) : nil, value: progress)
            }

            Text(label)
                .font(.system(size: 17, weight: .medium))
                .kerning(0.4)
                .foregroundStyle(theme.page)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 56)
        .contentShape(RoundedRectangle(cornerRadius: 14))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        startedAt = Date()
                        tick()
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    if progress < 1 {
                        progress = 0
                    }
                }
        )
    }

    private func tick() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
            guard isPressing, let started = startedAt else { return }
            let elapsed = Date().timeIntervalSince(started)
            progress = min(1, elapsed / duration)
            if progress >= 1 {
                isPressing = false
                onComplete()
            } else {
                tick()
            }
        }
    }
}
