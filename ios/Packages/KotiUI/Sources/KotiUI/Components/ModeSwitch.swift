import SwiftUI
import KotiThemes

/// Single persistent control to flip between My Book and The Sangha. Lives
/// at the top of each mode's home screen. Style adapts to the mode you're
/// in via the `variant` — `paper` (light pill on cream) inside My Book,
/// `cloth` (dark pill on red) inside The Sangha.
///
/// Mirrors `mode-switch.jsx` in the v5 design package — same 220×38 track,
/// same 16pt thumb radius, same 0.18s ease cross-fade on the active thumb.
public struct ModeSwitch: View {
    public enum Pill {
        case mine
        case sangha
    }

    public enum Variant {
        case paper
        case cloth
    }

    let active: Pill
    let theme: any Theme
    let variant: Variant
    let onPickMine: () -> Void
    let onPickSangha: () -> Void

    public init(
        active: Pill,
        theme: any Theme,
        variant: Variant = .paper,
        onPickMine: @escaping () -> Void,
        onPickSangha: @escaping () -> Void
    ) {
        self.active = active
        self.theme = theme
        self.variant = variant
        self.onPickMine = onPickMine
        self.onPickSangha = onPickSangha
    }

    private var isPaper: Bool { variant == .paper }

    private var trackBg: Color {
        isPaper ? Color.black.opacity(0.05) : Color.black.opacity(0.30)
    }

    private var trackBorder: Color {
        isPaper ? Color.black.opacity(0.07) : theme.foil.opacity(0.25)
    }

    private var thumbBg: Color {
        isPaper ? theme.cloth : theme.foil
    }

    private var thumbColor: Color {
        isPaper ? theme.page : theme.cloth
    }

    private var inactiveColor: Color {
        isPaper ? Color.black.opacity(0.55) : Color.white.opacity(0.72)
    }

    public var body: some View {
        HStack(spacing: 0) {
            pill(label: "My Book", on: active == .mine, action: onPickMine)
            pill(label: "The Sangha", on: active == .sangha, action: onPickSangha)
        }
        .padding(3)
        .frame(width: 220)
        .background(trackBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(trackBorder, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .animation(.easeInOut(duration: 0.18), value: active)
    }

    private func pill(label: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: on ? .medium : .regular))
                .kerning(0.4)
                .foregroundStyle(on ? thumbColor : inactiveColor)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(on ? thumbBg : Color.clear)
                        .shadow(
                            color: on ? Color.black.opacity(0.18) : .clear,
                            radius: on ? 1 : 0,
                            x: 0, y: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
