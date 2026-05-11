import SwiftUI
import KotiCore
import KotiThemes

/// The Sangha — communal hub. Cloth-coloured cover, live counter, stats
/// tiles, "writing now" ticker (rotates every 2.6s), permanence note, and
/// a sticky CTA to add your hand.
public struct SharedHubView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let onWrite: () -> Void
    let onOpenWriters: () -> Void
    let onClose: () -> Void

    @State private var tickerIdx: Int = 0
    @State private var nudge: Int64 = 0

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        onWrite: @escaping () -> Void,
        onOpenWriters: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.onWrite = onWrite
        self.onOpenWriters = onOpenWriters
        self.onClose = onClose
    }

    private var k: SharedKoti { SharedKotiCatalog.sample }
    private var liveCount: Int64 { k.count + nudge }
    private var pct: Double {
        guard k.target > 0 else { return 0 }
        return Double(liveCount) / Double(k.target)
    }
    private var remaining: Int64 { max(0, k.target - liveCount) }

    public var body: some View {
        ZStack(alignment: .bottom) {
            theme.cloth.ignoresSafeArea()

            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.foil, lineWidth: 0.5)
                .padding(14)
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.foil.opacity(0.4), lineWidth: 0.5)
                .padding(18)

            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 12) {
                        title
                        counter
                        statTiles
                        ticker
                        permanenceNote
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 110)
                }
            }
            ctaBar
        }
        .foregroundStyle(theme.page)
        .onAppear { startTimers() }
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Text("‹")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.page.opacity(0.7))
            }
            Spacer()
            Text("THE SHARED KOTI")
                .font(.system(size: 11))
                .kerning(2.4)
                .foregroundStyle(theme.page.opacity(0.75))
            Spacer()
            Button(action: onOpenWriters) {
                Text("HANDS")
                    .font(.system(size: 10))
                    .kerning(1.4)
                    .foregroundStyle(theme.page.opacity(0.7))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 54)
    }

    private var title: some View {
        VStack(spacing: 8) {
            SriYantra(foil: theme.foil, size: 42)
            Text(k.nameLocal)
                .font(.custom(tradition.displayFontKey, size: 28))
                .foregroundStyle(theme.foil)
                .multilineTextAlignment(.center)
            Text(k.name)
                .font(.custom("EB Garamond", size: 15))
                .italic()
                .foregroundStyle(theme.page.opacity(0.85))
            Text("By the Likhita Foundation · bound for \(tradition.templeShort)")
                .font(.custom("EB Garamond", size: 11))
                .italic()
                .foregroundStyle(theme.page.opacity(0.65))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
        .padding(.top, 4)
    }

    private var counter: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("NAMES WRITTEN")
                    .font(.system(size: 10))
                    .kerning(1.6)
                    .foregroundStyle(theme.page.opacity(0.65))
                Spacer()
                Text("CEILING · 1 KOTI")
                    .font(.system(size: 10))
                    .kerning(1.6)
                    .foregroundStyle(theme.page.opacity(0.65))
            }
            HStack(alignment: .firstTextBaseline) {
                Text(formatted(liveCount))
                    .font(.custom("EB Garamond", size: 32))
                    .kerning(0.4)
                    .foregroundStyle(theme.foil)
                Spacer()
                Text("/ \(formatted(k.target))")
                    .font(.custom("EB Garamond", size: 16))
                    .foregroundStyle(theme.page.opacity(0.5))
            }
            .padding(.top, 4)

            Capsule()
                .fill(Color.white.opacity(0.08))
                .frame(height: 5)
                .overlay(
                    GeometryReader { g in
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [theme.foil, theme.accent],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: g.size.width * pct, height: 5)
                            .shadow(color: theme.foil.opacity(0.4), radius: 6)
                            .animation(.linear(duration: 1.4), value: liveCount)
                    }
                )
                .padding(.top, 12)

            HStack {
                Text("\(String(format: "%.3f", pct * 100))%")
                Spacer()
                Text("\(formatted(remaining)) remaining")
            }
            .font(.system(size: 11))
            .foregroundStyle(theme.page.opacity(0.7))
            .padding(.top, 6)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(Color.black.opacity(0.24))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(theme.foil, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statTiles: some View {
        HStack(spacing: 8) {
            statTile(label: "DEVOTEES", value: formatted(Int64(k.uniqueWriters)), sub: "unique hands", action: onOpenWriters)
            statTile(label: "COUNTRIES", value: "\(k.countriesActive)", sub: "and growing", action: nil)
            statTile(label: "BEGUN", value: k.startedOn.components(separatedBy: "·").first?.trimmingCharacters(in: .whitespaces) ?? "—", sub: "Sankranti", action: nil)
        }
    }

    private func statTile(label: String, value: String, sub: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9.5))
                    .kerning(1.4)
                    .foregroundStyle(theme.page.opacity(0.65))
                Text(value)
                    .font(.custom("EB Garamond", size: 18))
                    .foregroundStyle(theme.foil)
                Text(sub)
                    .font(.system(size: 10))
                    .foregroundStyle(theme.page.opacity(0.5))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(theme.foil.opacity(0.3), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private var ticker: some View {
        let writers = SharedKotiCatalog.recentWriters
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(hex: "#5BCB81"))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color(hex: "#5BCB81").opacity(0.5), radius: 3)
                        .modifier(LiveDotAnimation())
                    Text("WRITING NOW")
                        .font(.system(size: 10))
                        .kerning(1.6)
                        .foregroundStyle(theme.page.opacity(0.7))
                }
                Spacer()
                Text("worldwide · live")
                    .font(.system(size: 10))
                    .kerning(0.4)
                    .foregroundStyle(theme.page.opacity(0.55))
            }
            VStack(alignment: .leading, spacing: 4) {
                ForEach(0..<3, id: \.self) { offset in
                    let writer = writers[(tickerIdx + offset) % writers.count]
                    let isTop = (offset == 0)
                    HStack {
                        Group {
                            Text(writer.name).fontWeight(.medium) +
                            Text(" · \(writer.place)").foregroundColor(Color.gray)
                        }
                        Spacer()
                        Text("+\(writer.count) · \(writer.ago)")
                    }
                    .font(.custom("EB Garamond", size: isTop ? 13 : 12))
                    .foregroundStyle(theme.page.opacity(isTop ? 1 : (0.45 - Double(offset) * 0.12)))
                }
            }
            .frame(minHeight: 70, alignment: .center)
            .animation(.easeInOut(duration: 0.5), value: tickerIdx)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.18))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.foil.opacity(0.3), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var permanenceNote: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(String(tradition.mantra.prefix(1)))
                .font(.custom(tradition.displayFontKey, size: 22))
                .foregroundStyle(theme.foil)
            VStack(alignment: .leading, spacing: 4) {
                (Text("Append-only ledger.").bold() +
                 Text(" Once written, never erased — not by you, not by anyone. Your hand joins \(formatted(Int64(k.uniqueWriters))) others on a single sacred book the Foundation will bind and carry to \(tradition.templeShort)."))
                    .font(.custom("EB Garamond", size: 11.5))
                    .italic()
                    .foregroundStyle(theme.page.opacity(0.85))
                    .lineSpacing(3)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(red: 1, green: 0.86, blue: 0.59).opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(theme.foil, style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var ctaBar: some View {
        VStack(spacing: 8) {
            Button(action: onWrite) {
                Text("Add your hand to the koti")
                    .font(.system(size: 16, weight: .semibold))
                    .kerning(0.4)
                    .foregroundStyle(theme.cloth)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(theme.foil)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 8)
            }
            Text("Write as many as you wish · no personal limit")
                .font(.custom("EB Garamond", size: 11))
                .italic()
                .foregroundStyle(theme.page.opacity(0.65))
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 30)
        .background(
            LinearGradient(
                colors: [theme.cloth.opacity(0), theme.cloth],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 120)
            .offset(y: 30)
        )
    }

    private func startTimers() {
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                await MainActor.run {
                    tickerIdx = (tickerIdx + 1) % SharedKotiCatalog.recentWriters.count
                }
            }
        }
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                await MainActor.run {
                    nudge += Int64.random(in: 2...12)
                }
            }
        }
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}

private struct LiveDotAnimation: ViewModifier {
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
