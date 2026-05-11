import SwiftUI
import KotiCore
import KotiThemes

/// Pattabhishekam ceremony screen — radial gold beams, mantra reveal,
/// final stats, "see your completed book" CTA.
public struct CompletionView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let koti: KotiSession
    let onContinue: () -> Void

    @State private var revealed: Bool = false

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        koti: KotiSession,
        onContinue: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.koti = koti
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            RadialGradient(
                colors: [theme.foil.opacity(0.2), theme.cloth],
                center: .top, startRadius: 20, endRadius: 480
            )
            .ignoresSafeArea()

            beams

            VStack(spacing: 16) {
                Spacer()
                Text("PATTABHISHEKAM")
                    .font(.system(size: 11))
                    .kerning(4)
                    .foregroundStyle(theme.page.opacity(0.7))
                Text(tradition.mantra)
                    .font(.custom(tradition.displayFontKey, size: 64))
                    .foregroundStyle(theme.foil)
                    .opacity(revealed ? 1 : 0)
                    .scaleEffect(revealed ? 1 : 0.92)
                    .shadow(color: Color(red: 1, green: 0.86, blue: 0.59).opacity(0.5), radius: 24)
                SriYantra(foil: theme.foil, size: 56)
                Text("The koti is complete.")
                    .font(.custom("EB Garamond", size: 20))
                    .italic()
                    .foregroundStyle(theme.page)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)
                GoldRule(foil: theme.foil, width: 180)
                statsBlock
                    .frame(maxWidth: 280)
                Text(tradition.jaya)
                    .font(.custom(tradition.displayFontKey, size: 22))
                    .foregroundStyle(theme.foil)
                    .padding(.top, 8)
                Spacer()
            }

            VStack {
                Spacer()
                Button(action: onContinue) {
                    Text("See your completed book →")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(theme.cloth)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(theme.foil)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 36)
            }
        }
        .foregroundStyle(theme.page)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeOut(duration: 1.6)) { revealed = true }
            }
        }
    }

    private var beams: some View {
        ZStack {
            ForEach([-30, -15, 0, 15, 30], id: \.self) { deg in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [theme.foil.opacity(0.55), Color.clear],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 240)
                    .rotationEffect(.degrees(Double(deg)), anchor: .top)
                    .offset(y: -120)
                    .opacity(revealed ? 0.55 : 0)
            }
        }
        .offset(y: 60)
    }

    private var statsBlock: some View {
        let trimmed = koti.dedicationText.prefix(40)
        let suffix = koti.dedicationText.count > 40 ? "…" : ""
        return VStack(spacing: 4) {
            Text("\(formatted(koti.count)) mantras · in \(koti.daysActive) days")
                .font(.custom("EB Garamond", size: 13))
                .foregroundStyle(theme.page.opacity(0.78))
            Text("Dedicated to \(koti.dedicationText.isEmpty ? "Sri Rama" : "“\(trimmed)\(suffix)”")")
                .font(.custom("EB Garamond", size: 13))
                .foregroundStyle(theme.page.opacity(0.78))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}
