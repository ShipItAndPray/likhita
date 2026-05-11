import SwiftUI
import KotiCore
import KotiThemes

/// Write into the communal book. Mixed-ink mantras, user's own entries
/// circled. The view feeds keystrokes into `SharedKotiViewModel.cadence`
/// and commits each completed mantra via `commitMantra()` which buffers
/// the entry and flushes to `POST /api/v1/shared/entries` on a debounce.
public struct SharedWritingView: View {
    let tradition: TraditionContent
    let theme: any Theme
    @Bindable var vm: SharedKotiViewModel
    let onClose: () -> Void

    @State private var typed: String = ""
    @State private var shake: Bool = false

    private let cols = 6
    private let rows = 10

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        vm: SharedKotiViewModel,
        onClose: @escaping () -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.vm = vm
        self.onClose = onClose
    }

    private var snap: LikhitaService.SharedHubSnapshot? { vm.snapshot }
    private var liveCount: Int64 { Int64(snap?.koti.currentCount ?? 0) + Int64(vm.mySessionCount) }
    private var target: Int64 { Int64(snap?.koti.targetCount ?? 10_000_000) }
    private var pct: Double { target > 0 ? Double(liveCount) / Double(target) : 0 }
    private var visibleCount: Int { cols * rows }

    private let palette: [String] = [
        "#7A1218", "#1A1410", "#E26B1A", "#3A2766",
        "#7A4424", "#4A6B30", "#0E5570"
    ]

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                bookArea
                inputBar
            }
        }
        .foregroundStyle(theme.textPrimary)
        .task { vm.startPolling() }
        .onDisappear { vm.stopPolling() }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Text("‹")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
            }
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(formatted(liveCount))
                        .font(.custom("EB Garamond", size: 16))
                        .kerning(0.2)
                    Text(" / 1,00,00,000")
                        .font(.system(size: 10))
                        .foregroundStyle(theme.textPrimary.opacity(0.5))
                }
                Text("SHARED KOTI · \(String(format: "%.3f", pct * 100))%")
                    .font(.system(size: 9.5))
                    .kerning(1.2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
            }
            Spacer()
            if vm.pendingFlush > 0 {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.6)
                    Text("syncing \(vm.pendingFlush)")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.page)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.foil, lineWidth: 0.5))
            } else {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: "#5BCB81"))
                        .frame(width: 6, height: 6)
                        .modifier(LiveDotAnimation())
                    Text("live")
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.page)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.foil, lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
        .padding(.bottom, 8)
    }

    private var bookArea: some View {
        BookSpread(theme: theme) {
            VStack(spacing: 6) {
                HStack {
                    Text("FOLIO \(liveCount / 150 + 1) · SHARED")
                        .font(.system(size: 9))
                        .kerning(2.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.42))
                    Spacer()
                    PetalBorder(foil: theme.foil, width: 100)
                    Spacer()
                    Text("\(formatted(Int64(snap?.uniqueWriters ?? 0))) HANDS")
                        .font(.system(size: 9))
                        .kerning(2.4)
                        .foregroundStyle(theme.textPrimary.opacity(0.42))
                }
                .padding(.bottom, 4)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: cols)
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(0..<visibleCount, id: \.self) { i in
                        cell(at: i)
                    }
                }
                .modifier(ShakeAnimation(active: shake))

                HStack {
                    Text("Your entries are circled")
                        .font(.custom("EB Garamond", size: 9))
                        .italic()
                        .foregroundStyle(theme.textPrimary.opacity(0.45))
                    Spacer()
                    CornerFlourish(foil: theme.foil, size: 12)
                }
                .padding(.top, 4)
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

    private func cell(at i: Int) -> some View {
        let inkHex = palette[(i * 31) % palette.count]
        let isMine = i >= visibleCount - vm.mySessionCount
        let color = isMine ? Color(hex: "#E34234") : Color(hex: inkHex)
        return ZStack {
            MantraEntry(
                mantra: tradition.mantra,
                fontName: tradition.displayFontKey,
                color: color,
                seed: Int(liveCount) - visibleCount + i + 1,
                size: tradition.scriptKey == "devanagari" ? 13 : 11
            )
            if isMine {
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(color.opacity(0.5), style: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .padding(-1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 14)
    }

    private var inputBar: some View {
        VStack(spacing: 8) {
            HStack {
                #if os(iOS)
                TextField("type \(tradition.mantraTyped) — your hand joins others", text: $typed)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(Font.system(size: 13, weight: .regular, design: .monospaced))
                    .kerning(1.2)
                    .foregroundStyle(Color(hex: "#E34234"))
                    .onChange(of: typed) { _, new in handleInput(new) }
                #else
                TextField("type \(tradition.mantraTyped) — your hand joins others", text: $typed)
                    .autocorrectionDisabled()
                    .font(Font.system(size: 13, weight: .regular, design: .monospaced))
                    .kerning(1.2)
                    .foregroundStyle(Color(hex: "#E34234"))
                    .onChange(of: typed) { _, new in handleInput(new) }
                #endif
                Text(tradition.mantra)
                    .font(.custom(tradition.displayFontKey, size: 18))
                    .foregroundStyle(Color(hex: "#E34234").opacity(0.5))
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(theme.page)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(theme.foil, lineWidth: 0.5))

            HStack {
                Group {
                    Text("You have written ") +
                    Text("\(vm.mySessionCount)").bold() +
                    Text(" in this session")
                }
                .font(.custom("EB Garamond", size: 10))
                .italic()
                .foregroundStyle(theme.textPrimary.opacity(0.6))
                Spacer()
                Text("APPEND-ONLY · PERMANENT")
                    .font(.system(size: 10))
                    .kerning(1.2)
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 28)
    }

    private func handleInput(_ raw: String) {
        let v = raw.lowercased().filter { $0.isLetter }
        if !v.isEmpty { vm.recordKeystroke() }
        if v == tradition.mantraTyped {
            vm.commitMantra()
            typed = ""
        } else if tradition.mantraTyped.hasPrefix(v) {
            if v != raw { typed = v }
        } else {
            withAnimation(.linear(duration: 0.3)) { shake = true }
            typed = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shake = false }
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
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                    pulse = true
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
