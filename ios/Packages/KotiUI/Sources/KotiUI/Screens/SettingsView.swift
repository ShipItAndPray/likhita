import SwiftUI
import KotiCore
import KotiThemes

/// Minimal settings screen — active koti summary (when one exists), past
/// kotis (when there are any), foundation links. Designer jump rows are
/// gated to DEBUG so they never ship to TestFlight or App Store.
public struct SettingsView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let koti: KotiSession
    let onClose: () -> Void
    let onJump: (String) -> Void

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        koti: KotiSession,
        onClose: @escaping () -> Void,
        onJump: @escaping (String) -> Void = { _ in }
    ) {
        self.tradition = tradition
        self.theme = theme
        self.koti = koti
        self.onClose = onClose
        self.onJump = onJump
    }

    private var hasActiveKoti: Bool { koti.target > 0 && koti.count > 0 }

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if hasActiveKoti {
                            sectionHeader("ACTIVE KOTI")
                            card {
                                row(label: "Mode", value: KotiModeCatalog.plan(forKey: koti.modeKey).label)
                                row(label: "Theme", value: theme.displayName)
                                row(label: "Stylus", value: InkPalette.name(forHex: koti.inkHex))
                                row(label: "Progress", value: "\(formatted(koti.count)) / \(formatted(koti.target))")
                                row(label: "Audio", value: "Off", isLast: true)
                            }
                        }

                        sectionHeader("FOUNDATION")
                            .padding(.top, hasActiveKoti ? 20 : 0)
                        card {
                            row(label: "Transparency portal", value: "likhita.org")
                            row(label: "Support the Foundation", value: "optional")
                            row(label: "Privacy", value: "")
                            row(label: "About", value: "v1.0")
                            row(label: "Sangha by", value: "Mammu Inc.", isLast: true)
                        }

                        #if DEBUG
                        sectionHeader("DESIGNER JUMP").padding(.top, 20)
                        card {
                            ForEach(designerJumpKeys, id: \.self) { key in
                                row(label: key, value: "→", isLast: key == designerJumpKeys.last) {
                                    onJump(key)
                                }
                            }
                        }
                        #endif
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .foregroundStyle(theme.textPrimary)
    }

    private let designerJumpKeys = [
        "threshold", "welcome", "identity", "dedication", "stylus", "pledge",
        "writing", "path", "completion", "book", "ship", "status",
        "sharedHub", "sharedWrite", "sharedHands",
    ]

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Text("‹")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.textPrimary.opacity(0.6))
                }
                Spacer()
                Text("SETTINGS")
                    .font(.system(size: 11))
                    .kerning(2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                Color.clear.frame(width: 22, height: 22)
            }
            .padding(.horizontal, 24)
            .padding(.top, 54)

            Text(koti.name.isEmpty ? "A devotee" : koti.name)
                .font(.custom("EB Garamond", size: 26))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Text("\(tradition.appName) · joined this month")
                .font(.system(size: 12))
                .foregroundStyle(theme.textPrimary.opacity(0.6))
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 12)
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10))
            .kerning(1.6)
            .foregroundStyle(theme.textPrimary.opacity(0.55))
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .background(theme.page)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(.black.opacity(0.08), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
    }

    private func row(label: String, value: String, isLast: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button {
            action?()
        } label: {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .overlay(
                Rectangle()
                    .fill(.black.opacity(isLast ? 0 : 0.08))
                    .frame(height: 0.5)
                    .padding(.horizontal, 16),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}
