import SwiftUI
import KotiCore
import KotiThemes

/// Splash before the sankalpam — shown when no koti is active.
/// Layout matches `Welcome` in onboarding.jsx.
public struct WelcomeView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let onBegin: () -> Void

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        onBegin: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.onBegin = onBegin
    }

    public var body: some View {
        ZStack {
            theme.cloth.ignoresSafeArea()

            // Double foil border
            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.foil, lineWidth: 0.5)
                .padding(18)
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.foil.opacity(0.5), lineWidth: 0.5)
                .padding(22)

            VStack {
                Spacer().frame(height: 60)
                VStack(spacing: 18) {
                    Text("Likhita Foundation · est. 2026")
                        .font(.system(size: 11))
                        .kerning(4)
                        .foregroundStyle(theme.page.opacity(0.65))
                    SriYantra(foil: theme.foil, size: 72)
                    Text(tradition.mantra)
                        .font(.custom(tradition.displayFontKey, size: 56))
                        .foregroundStyle(theme.foil)
                        .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 1)
                        .padding(.top, 4)
                    GoldRule(foil: theme.foil, width: 180)
                    Text(tradition.appName)
                        .font(.custom("EB Garamond", size: 28))
                        .italic()
                        .foregroundStyle(theme.page)
                        .padding(.top, 4)
                    Text(tradition.practiceLocal)
                        .font(.custom(tradition.displayFontKey, size: 13))
                        .foregroundStyle(theme.page.opacity(0.7))
                }
                .padding(.top, 40)

                Spacer()

                VStack(spacing: 20) {
                    Text("A digital extension of an ancient practice.\nWritten by you. Delivered to \(tradition.templeShort).")
                        .font(.custom("EB Garamond", size: 13))
                        .italic()
                        .foregroundStyle(theme.page.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .frame(maxWidth: 280)

                    Button(action: onBegin) {
                        Text("Begin a sankalpam")
                            .font(.system(size: 16, weight: .semibold))
                            .kerning(0.4)
                            .foregroundStyle(theme.cloth)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(theme.foil)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 32)
        }
        .foregroundStyle(theme.page)
    }
}
