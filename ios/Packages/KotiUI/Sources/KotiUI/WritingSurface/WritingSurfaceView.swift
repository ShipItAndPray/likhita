import SwiftUI
import KotiCore
import KotiThemes

/// The core practice surface. Top counter + milestone pill, middle book
/// spread (8×12 grid of mantras + cursor), bottom input rail with the
/// type-target field. Mirrors `WritingSurface` in core-screens.jsx.
public struct WritingSurfaceView: View {
    let tradition: TraditionContent
    let theme: any Theme
    @Binding var koti: KotiSession
    let onIncrement: () -> Void
    /// Fires once per keystroke entered into the input field. Used to feed the
    /// cadence sampler so the server's anti-cheat can verify human rhythm.
    let onKeystroke: () -> Void
    let onOpenPath: () -> Void
    /// Return to the Threshold so the user can switch between My Book and
    /// The Sangha. v2 design — pill rendered top-left.
    let onThreshold: () -> Void
    let onPause: () -> Void
    /// Fired automatically when count reaches target — no manual shortcut.
    /// Production rule: the user cannot mark a koti complete without writing
    /// every mantra in the chosen mode (Trial = 1,000, Lakh = 100,000, etc.).
    let onComplete: () -> Void

    @State private var typed: String = ""
    @State private var shake: Bool = false
    @State private var tooFast: Bool = false
    @State private var lastCommitTime: TimeInterval = 0

    private let cols: Int = 8
    private let rows: Int = 12

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        koti: Binding<KotiSession>,
        onIncrement: @escaping () -> Void,
        onKeystroke: @escaping () -> Void = {},
        onOpenPath: @escaping () -> Void,
        onThreshold: @escaping () -> Void = {},
        onPause: @escaping () -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self._koti = koti
        self.onIncrement = onIncrement
        self.onKeystroke = onKeystroke
        self.onOpenPath = onOpenPath
        self.onThreshold = onThreshold
        self.onPause = onPause
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            theme.chromeBg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                bookArea
                inputBar
            }
            if tooFast {
                Text("Slow down. This is sadhana, not a race.")
                    .font(.custom("EB Garamond", size: 12))
                    .italic()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.bottom, 110)
            }
        }
        .foregroundStyle(theme.textPrimary)
        // Production rule: completion fires only when every mantra in the
        // chosen mode is written. No manual shortcut on the writing surface.
        .onChange(of: koti.count) { _, newValue in
            if newValue >= koti.target { onComplete() }
        }
    }

    private var topBar: some View {
        let pct = koti.progress
        let currentIdx = MilestoneCatalog.currentIndex(forProgress: pct)
        let milestone = MilestoneCatalog.path[currentIdx]
        return VStack(spacing: 6) {
            HStack {
                ThresholdPill(
                    color: theme.textPrimary,
                    background: theme.page,
                    label: "↩ Threshold",
                    action: onThreshold
                )
                Spacer()
            }
            counterRow(pct: pct, milestone: milestone)
        }
    }

    private func counterRow(pct: Double, milestone: Milestone) -> some View {
        HStack(spacing: 10) {
            ProgressArc(pct: pct, foil: theme.foil, size: 38, strokeWidth: 2.5)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 0) {
                    Text(formatted(koti.count))
                        .font(.custom("EB Garamond", size: 17))
                        .foregroundStyle(theme.textPrimary)
                    Text(" / \(formatted(koti.target))")
                        .font(.custom("EB Garamond", size: 17))
                        .foregroundStyle(theme.textPrimary.opacity(0.4))
                }
                Text("\(String(format: "%.2f", pct * 100))% · \(tradition.practice)")
                    .font(.system(size: 9.5))
                    .kerning(1.2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
            }
            Spacer(minLength: 0)
            Button(action: onOpenPath) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 6, height: 6)
                        .modifier(PulseAnimation())
                    Text(milestone.label(for: tradition.scriptKey == "telugu" ? .telugu : .hindi))
                        .font(.custom(tradition.displayFontKey, size: 11.5))
                        .foregroundStyle(theme.textPrimary)
                }
                .padding(.leading, 9)
                .padding(.trailing, 11)
                .padding(.vertical, 5)
                .background(theme.page)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.foil, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 64)
        .padding(.bottom, 8)
    }

    private var bookArea: some View {
        let pct = koti.progress
        let currentIdx = MilestoneCatalog.currentIndex(forProgress: pct)
        let milestone = MilestoneCatalog.path[currentIdx]
        let visible = cols * rows
        let filled = Int(min(Int64(visible), koti.count))
        return BookSpread(theme: theme) {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("FOLIO \(koti.count / 150 + 1)")
                        .font(.system(size: 9))
                        .kerning(2.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.42))
                    Spacer()
                    PetalBorder(foil: theme.foil, width: 120)
                    Spacer()
                    Text(milestone.label(for: tradition.scriptKey == "telugu" ? .telugu : .hindi))
                        .font(.custom(tradition.displayFontKey, size: 9))
                        .kerning(2.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.42))
                }
                .padding(.bottom, 6)

                MantraGrid(
                    cols: cols, rows: rows,
                    filled: filled,
                    visibleCount: visible,
                    mantra: tradition.mantra,
                    fontName: tradition.displayFontKey,
                    color: koti.inkColor,
                    fontSize: tradition.scriptKey == "devanagari" ? 14 : 12,
                    seedBase: Int(koti.count) - filled
                )
                .modifier(ShakeAnimation(active: shake))

                CornerFlourish(foil: theme.foil, size: 14)
                    .padding(.top, 6)
            }
            .padding(.top, 14)
            .padding(.leading, 28)
            .padding(.trailing, 16)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .frame(maxHeight: .infinity)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button(action: onPause) {
                Text("⏸")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textPrimary.opacity(0.7))
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(theme.foil, lineWidth: 0.5))
            }
            HStack {
                #if os(iOS)
                TextField("type \(tradition.mantraTyped)", text: $typed)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(Font.system(size: 16, weight: .regular, design: .monospaced))
                    .kerning(1.2)
                    .foregroundStyle(koti.inkColor)
                    .onChange(of: typed) { _, new in
                        handleInput(new)
                    }
                #else
                TextField("type \(tradition.mantraTyped)", text: $typed)
                    .autocorrectionDisabled()
                    .font(Font.system(size: 16, weight: .regular, design: .monospaced))
                    .kerning(1.2)
                    .foregroundStyle(koti.inkColor)
                    .onChange(of: typed) { _, new in
                        handleInput(new)
                    }
                #endif
                Text(tradition.mantra)
                    .font(.custom(tradition.displayFontKey, size: 18))
                    .foregroundStyle(koti.inkColor.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(theme.page)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(theme.foil, lineWidth: 0.5))
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
    }

    private func handleInput(_ raw: String) {
        let v = raw.lowercased()
        if v.count > 0 { onKeystroke() }
        if v == tradition.mantraTyped {
            commit()
        } else if tradition.mantraTyped.hasPrefix(v) {
            // OK — partial prefix
        } else {
            withAnimation(.linear(duration: 0.3)) { shake = true }
            typed = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { shake = false }
        }
    }

    private func commit() {
        let now = Date().timeIntervalSince1970 * 1000
        if now - lastCommitTime < 250 {
            tooFast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { tooFast = false }
        }
        lastCommitTime = now
        onIncrement()
        typed = ""
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}

/// Lightweight session payload threaded through the writing/completion/ship
/// flow without dragging the full `Koti` model around.
public struct KotiSession: Sendable, Hashable {
    public var name: String
    public var count: Int64
    public var target: Int64
    public var inkHex: String
    public var theme: ThemeKey
    public var modeKey: String
    public var daysActive: Int
    public var dedicationText: String

    public init(
        name: String,
        count: Int64,
        target: Int64,
        inkHex: String,
        theme: ThemeKey,
        modeKey: String,
        daysActive: Int,
        dedicationText: String
    ) {
        self.name = name
        self.count = count
        self.target = target
        self.inkHex = inkHex
        self.theme = theme
        self.modeKey = modeKey
        self.daysActive = daysActive
        self.dedicationText = dedicationText
    }

    public var progress: Double {
        guard target > 0 else { return 0 }
        return Double(count) / Double(target)
    }

    public var inkColor: Color { Color(hex: inkHex) }
}

private struct MantraGrid: View {
    let cols: Int
    let rows: Int
    let filled: Int
    let visibleCount: Int
    let mantra: String
    let fontName: String
    let color: Color
    let fontSize: CGFloat
    let seedBase: Int

    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: cols)
        LazyVGrid(columns: columns, spacing: 2) {
            ForEach(0..<visibleCount, id: \.self) { i in
                ZStack {
                    if i < filled {
                        MantraEntry(
                            mantra: mantra,
                            fontName: fontName,
                            color: color,
                            seed: seedBase + i + 1,
                            size: fontSize
                        )
                    }
                    if i == filled {
                        Capsule()
                            .fill(color.opacity(0.6))
                            .frame(height: 1.4)
                            .padding(.horizontal, 4)
                            .modifier(InkPulseAnimation())
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 14)
            }
        }
    }
}

// MARK: - Animations

private struct PulseAnimation: ViewModifier {
    @State private var pulse: Bool = false
    func body(content: Content) -> some View {
        content
            .opacity(pulse ? 0.4 : 1)
            .scaleEffect(pulse ? 0.85 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

private struct InkPulseAnimation: ViewModifier {
    @State private var on: Bool = false
    func body(content: Content) -> some View {
        content
            .opacity(on ? 0.85 : 0.25)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    on = true
                }
            }
    }
}

private struct ShakeAnimation: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            .offset(x: active ? -4 : 0)
            .animation(active ? .easeInOut(duration: 0.075).repeatCount(4, autoreverses: true) : .default, value: active)
    }
}
