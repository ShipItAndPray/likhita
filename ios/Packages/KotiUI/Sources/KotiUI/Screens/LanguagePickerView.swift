import SwiftUI
import KotiCore
import KotiThemes

/// First-launch language + tradition picker. Translated pixel-for-pixel
/// from `design/ramakoti/project/app.ml.jsx` (LangPicker function, lines
/// 229–372). Order is **English → Hindi → Telugu** per the user's final
/// design beat. Picking a language commits the practice tradition:
///   - Telugu → `.rama` (Bhadrachalam)
///   - Hindi  → `.ram`  (Ram Naam Bank, Varanasi)
///   - English → routes to the tradition follow-up screen.
public struct LanguagePickerView: View {
    public typealias OnPick = (LanguageChoice) -> Void

    private let onPick: OnPick

    @State private var stage: Stage = .language
    @State private var pickedLanguage: LanguageCode? = nil

    public init(onPick: @escaping OnPick) {
        self.onPick = onPick
    }

    public var body: some View {
        ZStack {
            background
            doubleFoilBorder

            switch stage {
            case .language:
                languageStage
            case .tradition:
                traditionStage
            }
        }
        .ignoresSafeArea()
    }

    // ─── Background + frame ────────────────────────────────────

    private var background: some View {
        LinearGradient(
            colors: [Color(hex: "#7A1218"), Color(hex: "#2a060b")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var doubleFoilBorder: some View {
        let foil = Color(hex: "#C9A04A")
        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(foil, lineWidth: 0.5)
                .padding(18)
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(foil.opacity(0.45), lineWidth: 0.5)
                .padding(22)
        }
        .allowsHitTesting(false)
    }

    // ─── Stage: language ───────────────────────────────────────

    private var languageStage: some View {
        VStack(spacing: 0) {
            languageHeader
            Spacer(minLength: 8)
            languageCards
            Spacer(minLength: 8)
            permanentFooter
        }
        .padding(.top, 70)
        .padding(.horizontal, 28)
        .padding(.bottom, 36)
    }

    private var languageHeader: some View {
        let page = Color(hex: "#F5E9D0")
        let foil = Color(hex: "#C9A04A")
        return VStack(spacing: 0) {
            Text("LIKHITA  FOUNDATION")
                .font(.system(size: 10, weight: .regular, design: .default))
                .tracking(4)
                .foregroundColor(page.opacity(0.65))

            SriYantraMark(color: foil, size: 56)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Text("Likhita")
                .font(.custom("EBGaramond-Italic", size: 26))
                .italic()
                .foregroundColor(foil)

            VStack(spacing: 0) {
                Text("English · हिन्दी · తెలుగు")
                    .font(.custom("EBGaramond-Italic", size: 13))
                    .italic()
                    .foregroundColor(page.opacity(0.75))
                Text("Choose how the book speaks to you")
                    .font(.custom("EBGaramond-Italic", size: 12))
                    .italic()
                    .foregroundColor(page.opacity(0.50))
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .padding(.top, 8)
            .frame(maxWidth: 280)
        }
    }

    private var languageCards: some View {
        VStack(spacing: 12) {
            ForEach(LanguageCardData.all, id: \.code) { card in
                Button {
                    handleLanguage(card.code)
                } label: {
                    LanguageCardView(card: card)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var permanentFooter: some View {
        let page = Color(hex: "#F5E9D0")
        return VStack(spacing: 2) {
            Text("A permanent choice.")
                .font(.custom("EBGaramond-Italic", size: 10))
                .italic()
                .foregroundColor(page.opacity(0.55))
            Text("To switch later, reinstall the app.")
                .font(.custom("EBGaramond-Italic", size: 10))
                .italic()
                .foregroundColor(page.opacity(0.65))
        }
        .multilineTextAlignment(.center)
    }

    // ─── Stage: tradition (English follow-up) ──────────────────

    private var traditionStage: some View {
        let page = Color(hex: "#F5E9D0")
        let foil = Color(hex: "#C9A04A")
        return VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                SriYantraMark(color: foil, size: 44)
                Text("Your practice")
                    .font(.custom("EBGaramond-Regular", size: 26))
                    .foregroundColor(foil)
                    .padding(.top, 12)
                Text("The mantra always stays in its sacred script.\nPick the tradition you'd like to follow.")
                    .font(.custom("EBGaramond-Italic", size: 12))
                    .italic()
                    .multilineTextAlignment(.center)
                    .foregroundColor(page.opacity(0.70))
                    .lineSpacing(3)
                    .frame(maxWidth: 280)
                    .padding(.top, 6)
            }

            Spacer(minLength: 8)

            // Two big tradition cards
            VStack(spacing: 14) {
                Button {
                    commit(language: .english, tradition: .rama)
                } label: {
                    TraditionCardView(
                        mantra: "శ్రీరామ",
                        mantraFont: "TiroTelugu-Regular",
                        title: "Rama Koti",
                        subtitle: "South Indian tradition · book travels to Bhadrachalam"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    commit(language: .english, tradition: .ram)
                } label: {
                    TraditionCardView(
                        mantra: "राम",
                        mantraFont: "TiroDevanagariHindi-Regular",
                        title: "Ram Naam Lekhan",
                        subtitle: "North Indian tradition · book travels to Ram Naam Bank, Varanasi"
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 8)

            // Back to language stage
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    stage = .language
                }
            } label: {
                Text("‹ change language")
                    .font(.custom("EBGaramond-Italic", size: 12))
                    .italic()
                    .foregroundColor(page.opacity(0.55))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 70)
        .padding(.horizontal, 28)
        .padding(.bottom, 36)
    }

    // ─── Logic ─────────────────────────────────────────────────

    private func handleLanguage(_ code: LanguageCode) {
        switch code {
        case .telugu:
            commit(language: .telugu, tradition: .rama)
        case .hindi:
            commit(language: .hindi, tradition: .ram)
        case .english:
            withAnimation(.easeInOut(duration: 0.2)) {
                pickedLanguage = .english
                stage = .tradition
            }
        }
    }

    private func commit(language: LanguageCode, tradition: PracticeTradition) {
        let choice = LanguageChoice(language: language, tradition: tradition)
        onPick(choice)
    }

    private enum Stage {
        case language
        case tradition
    }
}

// ─── Cards ─────────────────────────────────────────────────────

private struct LanguageCardData {
    let code: LanguageCode
    let native: String
    let englishName: String
    let mantra: String
    let mantraFont: String
    let nativeFont: String
    let lineage: String
    let city: String
    let sub: String

    static let english = LanguageCardData(
        code: .english,
        native: "English",
        englishName: "English",
        mantra: "Śrī Rāma",
        mantraFont: "EBGaramond-Italic",
        nativeFont: "EBGaramond-Regular",
        lineage: "Tulsidas · Tyāgarāja · Valmiki",
        city: "Bhadrachalam · or Varanasi",
        sub: "You'll pick the tradition next"
    )
    static let hindi = LanguageCardData(
        code: .hindi,
        native: "हिन्दी",
        englishName: "Hindi",
        mantra: "राम",
        mantraFont: "TiroDevanagariHindi-Regular",
        nativeFont: "TiroDevanagariHindi-Regular",
        lineage: "तुलसीदास · कबीर",
        city: "वाराणसी · गंगा",
        sub: "Book is deposited at Ram Naam Bank, Varanasi (est. 1926)"
    )
    static let telugu = LanguageCardData(
        code: .telugu,
        native: "తెలుగు",
        englishName: "Telugu",
        mantra: "శ్రీరామ",
        mantraFont: "TiroTelugu-Regular",
        nativeFont: "TiroTelugu-Regular",
        lineage: "భద్రాచల రామదాసు · త్యాగరాజ",
        city: "భద్రాచలం · గోదావరి",
        sub: "Book travels to Bhadrachalam in the Rama-Koti Mandapam"
    )

    static let all: [LanguageCardData] = [.english, .hindi, .telugu]
}

private struct LanguageCardView: View {
    let card: LanguageCardData

    var body: some View {
        let page = Color(hex: "#F5E9D0")
        let foil = Color(hex: "#C9A04A")
        HStack(spacing: 14) {
            // Mantra column (60pt fixed)
            Text(card.mantra)
                .font(.custom(card.mantraFont, size: 28))
                .foregroundColor(foil)
                .lineSpacing(0)
                .multilineTextAlignment(.center)
                .frame(width: 60)

            // Divider
            Rectangle()
                .fill(foil.opacity(0.2))
                .frame(width: 0.5)
                .padding(.vertical, 2)

            // Right column
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(card.native)
                        .font(.custom(card.nativeFont, size: 18))
                        .foregroundColor(page)
                    Text(card.englishName)
                        .font(.system(size: 10))
                        .tracking(0.4)
                        .foregroundColor(page.opacity(0.5))
                }
                Text(card.lineage)
                    .font(.custom(card.nativeFont, size: 12))
                    .foregroundColor(page.opacity(0.72))
                    .lineSpacing(1)
                    .padding(.top, 6)
                Text(card.city)
                    .font(.custom(card.nativeFont, size: 11))
                    .foregroundColor(page.opacity(0.55))
                    .padding(.top, 2)
                Text(card.sub)
                    .font(.custom("EBGaramond-Italic", size: 10))
                    .italic()
                    .foregroundColor(page.opacity(0.50))
                    .lineSpacing(1)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("›")
                .font(.system(size: 18))
                .foregroundColor(page.opacity(0.5))
        }
        .padding(EdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18))
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(foil, lineWidth: 0.5)
        )
    }
}

private struct TraditionCardView: View {
    let mantra: String
    let mantraFont: String
    let title: String
    let subtitle: String

    var body: some View {
        let page = Color(hex: "#F5E9D0")
        let foil = Color(hex: "#C9A04A")
        VStack(alignment: .leading, spacing: 0) {
            Text(mantra)
                .font(.custom(mantraFont, size: 32))
                .foregroundColor(foil)
                .lineSpacing(0)
            Text(title)
                .font(.custom("EBGaramond-Regular", size: 20))
                .foregroundColor(page)
                .padding(.top, 8)
            Text(subtitle)
                .font(.custom("EBGaramond-Italic", size: 12))
                .italic()
                .foregroundColor(page.opacity(0.78))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 20, leading: 22, bottom: 20, trailing: 22))
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(foil, lineWidth: 0.5)
        )
    }
}

// ─── Sri Yantra mark ───────────────────────────────────────────

/// Sacred geometric mark. Simplified Sri Yantra: nine interlocking
/// triangles inside concentric circles, all drawn as hairlines. Pure
/// shape — no asset dependency. Matches the foil-colored mark used in
/// the JSX prototype (`rama-art.jsx > SriYantra`).
public struct SriYantraMark: View {
    let color: Color
    let size: CGFloat

    public init(color: Color, size: CGFloat) {
        self.color = color
        self.size = size
    }

    public var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(color, lineWidth: 0.5)

            // Inner circle
            Circle()
                .stroke(color.opacity(0.7), lineWidth: 0.4)
                .scaleEffect(0.78)

            // Four upward triangles + four downward, forming the
            // characteristic Sri Yantra lattice. Hairline weights.
            Group {
                triangle(scale: 0.62, pointingUp: true)
                triangle(scale: 0.62, pointingUp: false)
                triangle(scale: 0.46, pointingUp: true)
                triangle(scale: 0.46, pointingUp: false)
                triangle(scale: 0.30, pointingUp: true)
                triangle(scale: 0.30, pointingUp: false)
            }

            // Central bindu (dot)
            Circle()
                .fill(color)
                .frame(width: size * 0.04, height: size * 0.04)
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func triangle(scale: CGFloat, pointingUp: Bool) -> some View {
        Triangle(pointingUp: pointingUp)
            .stroke(color.opacity(0.85), lineWidth: 0.5)
            .scaleEffect(scale)
    }
}

private struct Triangle: Shape {
    let pointingUp: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        if pointingUp {
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        } else {
            p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        p.closeSubpath()
        return p
    }
}

