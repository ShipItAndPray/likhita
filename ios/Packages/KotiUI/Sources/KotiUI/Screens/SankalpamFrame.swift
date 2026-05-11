import SwiftUI
import KotiThemes

/// Reusable shell shared by all sankalpam steps that live on the cream
/// `chromeBg` surface (identity, dedication, stylus). Provides back chevron,
/// step indicator, title/subtitle block, gold rule, scrollable body, sticky
/// footer.
public struct SankalpamFrame<Body: View, Footer: View>: View {
    let theme: any Theme
    let step: Int
    let total: Int
    let title: String
    let subtitle: String?
    let onBack: () -> Void
    let bodyContent: () -> Body
    let footer: () -> Footer

    public init(
        theme: any Theme,
        step: Int,
        total: Int,
        title: String,
        subtitle: String? = nil,
        onBack: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Body,
        @ViewBuilder footer: @escaping () -> Footer
    ) {
        self.theme = theme
        self.step = step
        self.total = total
        self.title = title
        self.subtitle = subtitle
        self.onBack = onBack
        self.bodyContent = content
        self.footer = footer
    }

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        bodyContent()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                }
                footerArea
            }
        }
        .foregroundStyle(theme.textPrimary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Text("‹")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.textPrimary.opacity(0.6))
                }
                Spacer()
                Text("Sankalpam · \(step) of \(total)")
                    .font(.system(size: 11))
                    .kerning(2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                Color.clear.frame(width: 22, height: 22)
            }
            Text(title)
                .font(.custom("EB Garamond", size: 28))
                .lineSpacing(4)
                .foregroundStyle(theme.textPrimary)
                .padding(.top, 18)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textPrimary.opacity(0.65))
                    .lineSpacing(4)
                    .padding(.top, 8)
            }
            GoldRule(foil: theme.foil, width: 300)
                .padding(.top, 18)
        }
        .padding(.horizontal, 24)
        .padding(.top, 54)
    }

    private var footerArea: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: theme.chromeBg.opacity(0), location: 0),
                    .init(color: theme.chromeBg, location: 0.4),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 18)
            .offset(y: -32)

            footer()
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 36)
                .frame(maxWidth: .infinity)
                .background(theme.chromeBg)
        }
    }
}

/// "Continue" / "Begin" / similar primary action. Cloth-colored slab with
/// page-cream label.
public struct PrimaryButton: View {
    let label: String
    let theme: any Theme
    let isEnabled: Bool
    let action: () -> Void

    public init(_ label: String, theme: any Theme, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.label = label
        self.theme = theme
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: { if isEnabled { action() } }) {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(theme.page)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(isEnabled ? theme.cloth : Color.black.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .opacity(isEnabled ? 1 : 0.6)
        }
        .disabled(!isEnabled)
    }
}

/// Small uppercase eyebrow label.
public struct Eyebrow: View {
    let text: String
    let theme: any Theme
    public init(_ text: String, theme: any Theme) {
        self.text = text; self.theme = theme
    }
    public var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11))
            .kerning(1.4)
            .foregroundStyle(theme.textPrimary.opacity(0.6))
    }
}
