import SwiftUI
import KotiCore
import KotiThemes

/// The Sangha — communal hub. Cloth-coloured cover, live counter, stats
/// tiles, "writing now" ticker (rotates through the recent writers from
/// the server), permanence note, and a sticky CTA to add your hand.
public struct SharedHubView: View {
    let tradition: TraditionContent
    let theme: any Theme
    @Bindable var vm: SharedKotiViewModel
    let onWrite: () -> Void
    let onOpenWriters: () -> Void
    /// v5 design: legacy callback kept so older call sites still compile.
    /// The chrome no longer renders a `‹` back button here — switching to
    /// My Book is done via the persistent `ModeSwitch` in the header.
    let onClose: () -> Void
    /// v5 design: flip back to My Book via the persistent mode switch.
    let onSwitchToMine: () -> Void

    @State private var tickerIdx: Int = 0

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        vm: SharedKotiViewModel,
        onWrite: @escaping () -> Void,
        onOpenWriters: @escaping () -> Void,
        onClose: @escaping () -> Void,
        onSwitchToMine: @escaping () -> Void = {}
    ) {
        self.tradition = tradition
        self.theme = theme
        self.vm = vm
        self.onWrite = onWrite
        self.onOpenWriters = onOpenWriters
        self.onClose = onClose
        self.onSwitchToMine = onSwitchToMine
    }

    private var snap: LikhitaService.SharedHubSnapshot? { vm.snapshot }
    private var liveCount: Int64 { Int64(snap?.koti.currentCount ?? 0) }
    private var target: Int64 { Int64(snap?.koti.targetCount ?? 10_000_000) }
    private var pct: Double { target > 0 ? Double(liveCount) / Double(target) : 0 }
    private var remaining: Int64 { max(0, target - liveCount) }

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
        .task {
            // Drain any disk-persisted entries from a prior session BEFORE
            // we render the count. This is the "I typed, force-quit, came
            // back — make my entries land" path. Cheap when the queue is
            // empty (file doesn't even exist).
            await vm.flushNow()
            vm.startPolling()
            startTickerLoop()
        }
        .onDisappear {
            vm.stopPolling()
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            ModeSwitch(
                active: .sangha,
                theme: theme,
                variant: .cloth,
                onPickMine: onSwitchToMine,
                onPickSangha: {}
            )
            Spacer()
            Button(action: onOpenWriters) {
                Text("HANDS")
                    .font(.system(size: 10))
                    .kerning(1.4)
                    .foregroundStyle(theme.page.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .overlay(
                        Capsule().stroke(theme.foil.opacity(0.25), lineWidth: 0.5)
                    )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 54)
    }

    private var title: some View {
        VStack(spacing: 8) {
            SriYantra(foil: theme.foil, size: 42)
            Text(snap?.koti.nameLocal ?? "")
                .font(.custom(tradition.displayFontKey, size: 28))
                .foregroundStyle(theme.foil)
                .multilineTextAlignment(.center)
            Text(snap?.koti.name ?? "The Foundation Koti")
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
                Text("/ \(formatted(target))")
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
            statTile(label: "DEVOTEES", value: formatted(Int64(snap?.uniqueWriters ?? 0)), sub: "unique hands", action: onOpenWriters)
            statTile(label: "COUNTRIES", value: "\(snap?.countriesActive ?? 0)", sub: "and growing", action: nil)
            statTile(label: "BEGUN", value: beganText, sub: "Sankranti", action: nil)
        }
    }

    private var beganText: String {
        guard let s = snap?.koti.startedAt else { return "—" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: s) ?? ISO8601DateFormatter().date(from: s)
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM dd"
        f.locale = Locale(identifier: "en_US")
        return f.string(from: date)
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
        let writers = snap?.recentWriters ?? []
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
                if writers.isEmpty {
                    Text("No writers yet — be the first to add your hand.")
                        .font(.custom("EB Garamond", size: 12))
                        .italic()
                        .foregroundStyle(theme.page.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(0..<3, id: \.self) { offset in
                        if writers.count > 0 {
                            let writer = writers[(tickerIdx + offset) % writers.count]
                            let isTop = (offset == 0)
                            HStack {
                                Group {
                                    Text(writer.name).fontWeight(.medium) +
                                    Text(writer.place.isEmpty ? "" : " · \(writer.place)").foregroundColor(Color.gray)
                                }
                                Spacer()
                                Text("+\(writer.count) · \(writer.ago)")
                            }
                            .font(.custom("EB Garamond", size: isTop ? 13 : 12))
                            .foregroundStyle(theme.page.opacity(isTop ? 1 : (0.45 - Double(offset) * 0.12)))
                        }
                    }
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
        let writers = snap?.uniqueWriters ?? 0
        return HStack(alignment: .top, spacing: 10) {
            Text(String(tradition.mantra.prefix(1)))
                .font(.custom(tradition.displayFontKey, size: 22))
                .foregroundStyle(theme.foil)
            VStack(alignment: .leading, spacing: 4) {
                (Text("Append-only ledger.").bold() +
                 Text(writers > 0
                      ? " Once written, never erased — not by you, not by anyone. Your hand joins \(formatted(Int64(writers))) others on a single sacred book the Foundation will bind and carry to \(tradition.templeShort)."
                      : " Once written, never erased — not by you, not by anyone. The Foundation will bind this book and carry it to \(tradition.templeShort)."
                 ))
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

    private func startTickerLoop() {
        Task {
            while true {
                try? await Task.sleep(nanoseconds: 2_600_000_000)
                await MainActor.run {
                    if let count = vm.snapshot?.recentWriters.count, count > 0 {
                        tickerIdx = (tickerIdx + 1) % count
                    }
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
