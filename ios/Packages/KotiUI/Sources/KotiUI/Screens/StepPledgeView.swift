import SwiftUI
import KotiCore
import KotiThemes

/// Sankalpam final step — the pledge. Cloth-colored hero with mantra,
/// dedication echo, hold-to-begin button.
public struct StepPledgeView: View {
    let theme: any Theme
    let tradition: TraditionContent
    let dedicationText: String
    let onBack: () -> Void
    let onComplete: () -> Void

    public init(
        theme: any Theme,
        tradition: TraditionContent,
        dedicationText: String,
        onBack: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.theme = theme
        self.tradition = tradition
        self.dedicationText = dedicationText
        self.onBack = onBack
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            theme.cloth.ignoresSafeArea()

            RoundedRectangle(cornerRadius: 18)
                .stroke(theme.foil, lineWidth: 0.5)
                .padding(18)

            VStack(spacing: 0) {
                HStack {
                    Button(action: onBack) {
                        Text("‹")
                            .font(.system(size: 22))
                            .foregroundStyle(theme.page.opacity(0.6))
                    }
                    Spacer()
                    Text("THE PLEDGE")
                        .font(.system(size: 11))
                        .kerning(2)
                        .foregroundStyle(theme.page.opacity(0.65))
                    Spacer()
                    Color.clear.frame(width: 22, height: 22)
                }
                .padding(.horizontal, 32)
                .padding(.top, 56)

                VStack(spacing: 24) {
                    Spacer()
                    SriYantra(foil: theme.foil, size: 48)
                    Text(tradition.pledge)
                        .font(.custom(tradition.displayFontKey, size: 18))
                        .foregroundStyle(theme.page.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .frame(maxWidth: 320)

                    if !dedicationText.isEmpty {
                        GoldRule(foil: theme.foil, width: 140)
                        Text("\u{201C}\(dedicationText)\u{201D}")
                            .font(.custom("EB Garamond", size: 14))
                            .italic()
                            .foregroundStyle(theme.page.opacity(0.78))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .frame(maxWidth: 280)
                    }
                    Spacer()
                }
                .padding(.horizontal, 32)

                VStack(spacing: 10) {
                    HoldButton(
                        duration: 1.8,
                        theme: theme,
                        label: "Hold to begin · \(tradition.beginLabel)",
                        onComplete: onComplete
                    )
                    Text("The counter starts at zero. The koti begins now.")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.page.opacity(0.55))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
        .foregroundStyle(theme.page)
    }
}
