import SwiftUI
import KotiCore
import KotiThemes

/// The Threshold — the app's true home. The user picks where they write
/// today: their own bound book ("My Book"), or the communal append-only
/// ledger ("The Sangha"). Sangha values come from the live
/// `SharedKotiViewModel.snapshot`.
public struct ThresholdView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let sanghaTheme: any Theme
    let myCount: Int64
    let myTarget: Int64
    @Bindable var sangha: SharedKotiViewModel
    let onEnterMine: () -> Void
    let onEnterSangha: () -> Void

    @State private var sanghaTick: Int = 0

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        sanghaTheme: any Theme,
        myCount: Int64,
        myTarget: Int64,
        sangha: SharedKotiViewModel,
        onEnterMine: @escaping () -> Void,
        onEnterSangha: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.sanghaTheme = sanghaTheme
        self.myCount = myCount
        self.myTarget = myTarget
        self.sangha = sangha
        self.onEnterMine = onEnterMine
        self.onEnterSangha = onEnterSangha
    }

    private var myPct: Double {
        guard myTarget > 0 else { return 0 }
        return Double(myCount) / Double(myTarget)
    }
    private var snap: LikhitaService.SharedHubSnapshot? { sangha.snapshot }
    private var sanghaCount: Int64 { Int64(snap?.koti.currentCount ?? 0) }
    private var sanghaTarget: Int64 { Int64(snap?.koti.targetCount ?? 10_000_000) }
    private var sanghaWriters: Int { snap?.uniqueWriters ?? 0 }
    private var sanghaPct: Double {
        guard sanghaTarget > 0 else { return 0 }
        return Double(sanghaCount) / Double(sanghaTarget)
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [theme.chromeBg, theme.page],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 16) {
                        myBookCard
                        sanghaCard
                        Text("Your hand calibrates once. Both books accept it. Both are stewarded by the Likhita Foundation.")
                            .font(.custom("EB Garamond", size: 11))
                            .italic()
                            .foregroundStyle(theme.textPrimary.opacity(0.7))
                            .lineSpacing(3)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.03))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(.black.opacity(0.12), style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
        }
        .foregroundStyle(theme.textPrimary)
        .task {
            sangha.startPolling()
        }
        .onDisappear {
            sangha.stopPolling()
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(tradition.mantra)
                .font(.custom(tradition.displayFontKey, size: 30))
                .foregroundStyle(theme.cloth)
            Text("Choose where you write today")
                .font(.custom("EB Garamond", size: 14))
                .italic()
                .foregroundStyle(theme.textPrimary.opacity(0.6))
            HStack(spacing: 10) {
                GoldRule(foil: theme.foil, width: 60)
                SriYantra(foil: theme.foil, size: 18)
                GoldRule(foil: theme.foil, width: 60)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.top, 64)
        .padding(.bottom, 12)
    }

    private var myBookCard: some View {
        Button(action: onEnterMine) {
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("YOUR KOTI")
                            .font(.system(size: 10))
                            .kerning(1.8)
                            .foregroundStyle(theme.textPrimary.opacity(0.55))
                        Text("My Book")
                            .font(.custom("EB Garamond", size: 24))
                            .kerning(0.2)
                            .foregroundStyle(theme.textPrimary)
                            .padding(.top, 4)
                        Text("Your sankalpam. Your hand. Bound and shipped to \(tradition.templeShort) when complete.")
                            .font(.custom("EB Garamond", size: 12))
                            .italic()
                            .foregroundStyle(theme.textPrimary.opacity(0.65))
                            .lineSpacing(3)
                            .padding(.top, 4)
                        if myTarget > 0 {
                            VStack(spacing: 4) {
                                HStack {
                                    Text("\(formatted(myCount)) of \(formatted(myTarget))")
                                    Spacer()
                                    Text("\(String(format: "%.1f", myPct * 100))%")
                                }
                                .font(.system(size: 11))
                                .foregroundStyle(theme.textPrimary.opacity(0.7))
                                Capsule()
                                    .fill(Color.black.opacity(0.08))
                                    .frame(height: 3)
                                    .overlay(
                                        GeometryReader { g in
                                            Capsule()
                                                .fill(theme.cloth)
                                                .frame(width: g.size.width * myPct, height: 3)
                                        }
                                    )
                            }
                            .padding(.top, 12)
                        } else {
                            Text("Not begun · sankalpam awaits")
                                .font(.system(size: 11))
                                .kerning(0.4)
                                .foregroundStyle(theme.textPrimary.opacity(0.55))
                                .padding(.top, 10)
                        }
                    }
                    Spacer(minLength: 0)
                    miniBookIcon
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(theme.page)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.foil, lineWidth: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.foil.opacity(0.35), lineWidth: 0.5)
                    .padding(8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private var miniBookIcon: some View {
        ZStack {
            theme.cloth
            RoundedRectangle(cornerRadius: 2)
                .stroke(theme.foil, lineWidth: 0.5)
                .padding(5)
            Text(String(tradition.mantra.prefix(1)))
                .font(.custom(tradition.displayFontKey, size: 18))
                .foregroundStyle(theme.foil)
        }
        .frame(width: 52, height: 68)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }

    private var sanghaCard: some View {
        Button(action: onEnterSangha) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#5BCB81"))
                            .frame(width: 6, height: 6)
                            .modifier(PulseDotAnimation())
                        Text("THE FOUNDATION KOTI")
                            .font(.system(size: 10))
                            .kerning(1.8)
                    }
                    .foregroundStyle(sanghaTheme.page.opacity(0.7))

                    Text("The Sangha")
                        .font(.custom("EB Garamond", size: 24))
                        .kerning(0.2)
                        .foregroundStyle(sanghaTheme.foil)
                        .padding(.top, 4)

                    Text(sanghaWriters > 0
                         ? "One book. \(formatted(Int64(sanghaWriters))) hands. Append-only — once written, never erased."
                         : "One book. Append-only — once written, never erased."
                    )
                        .font(.custom("EB Garamond", size: 12))
                        .italic()
                        .foregroundStyle(sanghaTheme.page.opacity(0.78))
                        .lineSpacing(3)
                        .padding(.top, 4)

                    VStack(spacing: 4) {
                        HStack {
                            Text("\(formatted(sanghaCount)) of 1 crore")
                            Spacer()
                            Text("\(String(format: "%.2f", sanghaPct * 100))%")
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(sanghaTheme.page.opacity(0.8))

                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 3)
                            .overlay(
                                GeometryReader { g in
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [sanghaTheme.foil, sanghaTheme.accent],
                                                startPoint: .leading, endPoint: .trailing
                                            )
                                        )
                                        .frame(width: g.size.width * sanghaPct, height: 3)
                                        .animation(.linear(duration: 1.4), value: sanghaCount)
                                }
                            )
                    }
                    .padding(.top, 12)
                }
                Spacer(minLength: 0)
                SriYantra(foil: sanghaTheme.foil, size: 52)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 22)
            .background(sanghaTheme.cloth)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(sanghaTheme.foil, lineWidth: 0.5)
                    .padding(8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(sanghaTheme.foil.opacity(0.4), lineWidth: 0.5)
                    .padding(12)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.18), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}

private struct PulseDotAnimation: ViewModifier {
    @State private var pulse: Bool = false
    func body(content: Content) -> some View {
        content
            .scaleEffect(pulse ? 0.85 : 1)
            .opacity(pulse ? 0.4 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}
