import SwiftUI
import KotiCore
import KotiThemes
import KotiL10n

/// Pattabhishekam ceremony screen (SPEC.md §20.4 S12). The Lottie animation
/// commission lands in milestone 3; this shell shows the layout + final
/// stats overlay so the rest of the completion flow is unblocked.
public struct CompletionView: View {
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        ZStack {
            theme.surface.ignoresSafeArea()
            VStack(spacing: 32) {
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.system(size: 96))
                    .foregroundStyle(theme.accent)
                Text(L10n.Common.complete, bundle: L10n.bundle)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Button {
                    // Routes to BookPreview in milestone 2.
                } label: {
                    Text("Continue to your book")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(theme.primaryBrand)
                .foregroundStyle(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
