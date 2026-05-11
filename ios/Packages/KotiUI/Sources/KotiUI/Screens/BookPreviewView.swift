import SwiftUI
import KotiCore
import KotiThemes

/// Cover, dedication page, sample spread, colophon — the user's bound book
/// preview shown after completion.
public struct BookPreviewView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let koti: KotiSession
    let onBack: () -> Void
    let onContinue: () -> Void

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        koti: KotiSession,
        onBack: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.koti = koti
        self.onBack = onBack
        self.onContinue = onContinue
    }

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        cover
                        Text("COVER · CLOTH & GOLD FOIL")
                            .font(.system(size: 11))
                            .kerning(1.4)
                            .foregroundStyle(theme.textPrimary.opacity(0.5))

                        dedicationPage
                        sampleSpread
                        colophon
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
                }
                Button(action: onContinue) {
                    Text("Choose what's next →")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.page)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(theme.cloth)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 36)
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
                Text("YOUR BOUND BOOK")
                    .font(.system(size: 11))
                    .kerning(2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                Color.clear.frame(width: 22, height: 22)
            }
            Text("~\(koti.count / 150) pages · \(theme.displayName)")
                .font(.custom("EB Garamond", size: 24))
                .foregroundStyle(theme.textPrimary)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
        .padding(.top, 54)
        .padding(.bottom, 8)
    }

    private var cover: some View {
        ZStack {
            theme.cloth
            RoundedRectangle(cornerRadius: 2)
                .stroke(theme.foil, lineWidth: 0.5)
                .padding(14)
            RoundedRectangle(cornerRadius: 1)
                .stroke(theme.foil.opacity(0.6), lineWidth: 0.5)
                .padding(18)

            VStack(spacing: 12) {
                SriYantra(foil: theme.foil, size: 48)
                Text(tradition.practiceLocal)
                    .font(.custom(tradition.displayFontKey, size: 36))
                    .foregroundStyle(theme.foil)
                PetalBorder(foil: theme.foil, width: 140)
                Text(koti.name.isEmpty ? "A devotee" : koti.name)
                    .font(.custom("EB Garamond", size: 13))
                    .italic()
                    .foregroundStyle(theme.page.opacity(0.85))
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
    }

    private var dedicationPage: some View {
        BookPage(theme: theme, padding: 26, minHeight: 200) {
            VStack(spacing: 14) {
                Text("PAGE 1 · SANKALPAM")
                    .font(.system(size: 9))
                    .kerning(2.4)
                    .foregroundStyle(theme.textPrimary.opacity(0.5))
                CornerFlourish(foil: theme.foil, size: 20)
                Text("\u{201C}\(koti.dedicationText.isEmpty ? "In dedication to Sri Rama, this koti is offered." : koti.dedicationText)\u{201D}")
                    .font(.custom("EB Garamond", size: 16))
                    .italic()
                    .foregroundStyle(theme.bookInk)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .frame(maxWidth: 240)
                Text("— \(koti.name.isEmpty ? "A devotee" : koti.name)")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                    .padding(.top, 4)
                GoldRule(foil: theme.foil, width: 120)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var sampleSpread: some View {
        BookPage(theme: theme, padding: 20) {
            VStack(spacing: 6) {
                HStack {
                    Text("FOLIO 24")
                        .font(.system(size: 9))
                        .kerning(2)
                        .foregroundStyle(theme.textPrimary.opacity(0.45))
                    Spacer()
                    Text(tradition.scriptKey == "telugu" ? "చిత్రకూటం" : "चित्रकूट")
                        .font(.custom(tradition.displayFontKey, size: 9))
                        .kerning(2)
                        .foregroundStyle(theme.textPrimary.opacity(0.45))
                }
                .padding(.bottom, 4)

                ForEach(0..<10, id: \.self) { row in
                    HStack {
                        ForEach(0..<8, id: \.self) { col in
                            MantraEntry(
                                mantra: tradition.mantra,
                                fontName: tradition.displayFontKey,
                                color: koti.inkColor,
                                seed: row * 8 + col + 1,
                                size: tradition.scriptKey == "devanagari" ? 13 : 11
                            )
                            if col < 7 { Spacer() }
                        }
                    }
                }
            }
        }
    }

    private var colophon: some View {
        BookPage(theme: theme, padding: 26, minHeight: 220) {
            VStack(spacing: 12) {
                Text("COLOPHON")
                    .font(.system(size: 9))
                    .kerning(2.4)
                    .foregroundStyle(theme.textPrimary.opacity(0.5))
                SriYantra(foil: theme.foil, size: 36)
                VStack(spacing: 4) {
                    Text("Begun · 12 Phālguna 2026")
                    Text("Completed · 4 Vaiśākha 2026")
                    Text("\(formatted(koti.count)) writings of \(tradition.mantra)")
                        .italic()
                        .padding(.top, 8)
                }
                .font(.custom("EB Garamond", size: 14))
                .foregroundStyle(theme.bookInk)
                .lineSpacing(4)

                VStack(spacing: 2) {
                    Text("To be deposited at")
                    Text(tradition.templeFull).bold()
                    Text(tradition.templeLocale)
                }
                .font(.system(size: 11))
                .foregroundStyle(theme.textPrimary.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.top, 4)

                GoldRule(foil: theme.foil, width: 120)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}
