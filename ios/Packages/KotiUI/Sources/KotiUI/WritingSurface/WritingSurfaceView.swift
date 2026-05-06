import SwiftUI
import KotiCore
import KotiThemes

/// Core practice surface. Tops with a counter, fills the middle with the
/// rendered book page, and pins an input field to the bottom. SPEC.md §20.4
/// S9. The actual book renderer + anti-cheat input bridge land in a later
/// milestone — this is the layout shell that locks the geometry in place.
public struct WritingSurfaceView: View {
    @Environment(\.theme) private var theme

    @State private var draft: String = ""
    @State private var currentCount: Int64 = 42_317
    private let targetCount: Int64 = 100_000

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            counterBar
            bookPage
            inputBar
        }
        .background(theme.surface)
    }

    private var counterBar: some View {
        HStack {
            Text("\(currentCount.formatted()) / \(targetCount.formatted())")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Image(systemName: "leaf.fill")
                .foregroundStyle(theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 44)
        .background(theme.surfaceAlt)
    }

    private var bookPage: some View {
        ZStack {
            theme.surface
            Text(String(repeating: "·", count: 60))
                .font(.body)
                .foregroundStyle(theme.inkDefault.opacity(0.4))
                .multilineTextAlignment(.leading)
                .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.wave.2")
                .foregroundStyle(theme.textSecondary)
            TextField("", text: $draft)
                .textFieldStyle(.roundedBorder)
            Image(systemName: "pause.circle")
                .foregroundStyle(theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(height: 120)
        .background(theme.surfaceAlt)
    }
}
