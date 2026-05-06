import SwiftUI
import KotiCore
import KotiThemes
import KotiL10n

/// Six-step onboarding flow per SPEC.md §20.4 S3–S8. v1 wires only the
/// shells; production flow handlers (validation, persistence, calibration)
/// land in the next milestone.
public struct SankalpamView: View {
    public enum Step: Equatable {
        case identity
        case dedication
        case mode
        case stylus
        case theme
        case affirmation
    }

    private let step: Step
    private let onAdvance: (Step) -> Void
    private let onComplete: () -> Void

    @Environment(\.theme) private var theme

    public init(
        step: Step,
        onAdvance: @escaping (Step) -> Void,
        onComplete: @escaping () -> Void
    ) {
        self.step = step
        self.onAdvance = onAdvance
        self.onComplete = onComplete
    }

    public var body: some View {
        VStack(spacing: 24) {
            header
            Rectangle()
                .fill(theme.accent)
                .frame(height: 1)
                .padding(.horizontal, 32)
            stepBody
            Spacer()
            primaryButton
        }
        .padding(.vertical, 32)
    }

    private var header: some View {
        Text(L10n.Sankalpam.title, bundle: L10n.bundle)
            .font(.title)
            .fontWeight(.semibold)
    }

    @ViewBuilder
    private var stepBody: some View {
        switch step {
        case .identity:    IdentityStepView()
        case .dedication:  DedicationStepView()
        case .mode:        ModeStepView()
        case .stylus:      StylusStepView()
        case .theme:       ThemeStepView()
        case .affirmation: AffirmationStepView()
        }
    }

    private var primaryButton: some View {
        Button {
            advance()
        } label: {
            Text(L10n.Common.continue, bundle: L10n.bundle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .background(theme.accent)
        .foregroundStyle(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    private func advance() {
        switch step {
        case .identity:    onAdvance(.dedication)
        case .dedication:  onAdvance(.mode)
        case .mode:        onAdvance(.stylus)
        case .stylus:      onAdvance(.theme)
        case .theme:       onAdvance(.affirmation)
        case .affirmation: onComplete()
        }
    }
}

// MARK: - Step shells (intentionally minimal; designs land in milestone 2)

private struct IdentityStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Name").font(.subheadline)
            TextField("", text: .constant(""))
                .textFieldStyle(.roundedBorder)
            Text("Native place").font(.subheadline)
            TextField("", text: .constant(""))
                .textFieldStyle(.roundedBorder)
        }
        .padding(.horizontal, 24)
    }
}

private struct DedicationStepView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Sankalpam.dedication, bundle: L10n.bundle)
                .font(.subheadline)
            TextEditor(text: .constant(""))
                .frame(minHeight: 120)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray.opacity(0.3)))
        }
        .padding(.horizontal, 24)
    }
}

private struct ModeStepView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(KotiMode.allCases, id: \.self) { mode in
                HStack {
                    Text(String(describing: mode).capitalized)
                    Spacer()
                    Text("\(mode.targetCount)")
                        .monospacedDigit()
                }
                .padding(16)
                .background(.white.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct StylusStepView: View {
    var body: some View {
        Text("Stylus calibration — tap a swatch and type your mantra 5 times.")
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
    }
}

private struct ThemeStepView: View {
    var body: some View {
        Text(L10n.Sankalpam.theme, bundle: L10n.bundle)
            .padding(.horizontal, 24)
    }
}

private struct AffirmationStepView: View {
    var body: some View {
        Text("Hold to begin.")
            .padding(.horizontal, 24)
    }
}
