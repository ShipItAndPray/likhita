import SwiftUI

/// Small capsule pill shown top-left of the writing surface (and any other
/// mode-locked screen). Tapping it returns the user to the Threshold so
/// they can switch between My Book and The Sangha.
public struct ThresholdPill: View {
    let color: Color
    let background: Color
    let label: String
    let action: () -> Void

    public init(
        color: Color,
        background: Color,
        label: String = "↩ Threshold",
        action: @escaping () -> Void
    ) {
        self.color = color
        self.background = background
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("⌂").font(.system(size: 12))
                Text(label.uppercased())
                    .font(.system(size: 10))
                    .kerning(1.4)
            }
            .foregroundStyle(color)
            .padding(.leading, 8)
            .padding(.trailing, 10)
            .padding(.vertical, 5)
            .background(background)
            .clipShape(Capsule())
        }
    }
}
