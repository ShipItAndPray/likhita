import SwiftUI
import KotiCore
import KotiThemes

/// Sankalpam step 3 of 5 — ink color, handwriting calibration, theme.
public struct StepStylusThemeView: View {
    let theme: any Theme
    let tradition: TraditionContent
    @Bindable var form: SankalpamForm
    let availableThemes: [any Theme]
    let onBack: () -> Void
    let onNext: () -> Void
    let onThemeSelected: (ThemeKey) -> Void

    @State private var calibrationStrokes: [HandwritingStroke] = []
    @State private var capturedSamples: [[HandwritingStroke]] = []
    @State private var hint: String = ""

    private let target = 3

    public init(
        theme: any Theme,
        tradition: TraditionContent,
        form: SankalpamForm,
        availableThemes: [any Theme],
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onThemeSelected: @escaping (ThemeKey) -> Void
    ) {
        self.theme = theme
        self.tradition = tradition
        self.form = form
        self.availableThemes = availableThemes
        self.onBack = onBack
        self.onNext = onNext
        self.onThemeSelected = onThemeSelected
    }

    private var ready: Bool { capturedSamples.count >= target }

    public var body: some View {
        SankalpamFrame(
            theme: theme,
            step: 3, total: 5,
            title: "Write it once, by hand",
            subtitle: "Trace \(tradition.mantra) with your finger. The shape of your hand — its pressure, its tilt — becomes the ink that fills your book.",
            onBack: onBack,
            content: { content },
            footer: {
                PrimaryButton(
                    ready ? "Continue" : "Sign \(target - capturedSamples.count) more time\(target - capturedSamples.count == 1 ? "" : "s")",
                    theme: theme,
                    isEnabled: ready,
                    action: onNext
                )
            }
        )
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("Ink color", theme: theme).padding(.bottom, 10)
            inkGrid
            Text(InkPalette.name(forHex: form.inkHex))
                .font(.system(size: 12))
                .foregroundStyle(theme.textPrimary.opacity(0.65))
                .padding(.top, 6)

            HStack {
                Eyebrow("Your hand · sample \(min(capturedSamples.count + 1, target)) of \(target)", theme: theme)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<target, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i < capturedSamples.count ? Color(hex: form.inkHex) : Color.black.opacity(0.12))
                            .frame(width: 16, height: 4)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 10)

            HandwritingCanvas(
                guideText: tradition.mantra,
                guideFontName: tradition.displayFontKey,
                ink: Color(hex: form.inkHex),
                paper: theme.page,
                foil: theme.foil,
                strokes: $calibrationStrokes
            )

            HStack(spacing: 8) {
                Button {
                    calibrationStrokes = []
                } label: {
                    Text("Clear")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.textPrimary.opacity(calibrationStrokes.isEmpty ? 0.35 : 0.85))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(.black.opacity(0.18), lineWidth: 0.5)
                        )
                }
                .disabled(calibrationStrokes.isEmpty)

                Button {
                    saveCurrent()
                } label: {
                    Text(ready ? "Calibrated" :
                         calibrationStrokes.isEmpty ? "Trace, then save" :
                         "Save \(capturedSamples.count + 1) of \(target)")
                        .font(.system(size: 13, weight: .medium))
                        .kerning(0.3)
                        .foregroundStyle(saveEnabled ? .white : Color.black.opacity(0.35))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(
                            saveEnabled ? Color(hex: form.inkHex) : Color.black.opacity(0.08)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxWidth: .infinity)
                .disabled(!saveEnabled)
            }
            .padding(.top, 10)

            if !capturedSamples.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text("CAPTURED SIGNATURES")
                            .font(.system(size: 10))
                            .kerning(1.4)
                            .foregroundStyle(theme.textPrimary.opacity(0.5))
                        if !hint.isEmpty {
                            Text("· \(hint)")
                                .font(.system(size: 10))
                                .italic()
                                .foregroundStyle(theme.textPrimary.opacity(0.7))
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(Array(capturedSamples.enumerated()), id: \.offset) { _, sample in
                            StrokeThumbnail(strokes: sample, ink: Color(hex: form.inkHex), paper: theme.page)
                        }
                    }
                }
                .padding(.top, 14)
            }

            Text("Your handwriting is yours. Samples stay on this device — only the rendered ink travels to print.")
                .font(.custom("EB Garamond", size: 11))
                .italic()
                .foregroundStyle(theme.textPrimary.opacity(0.55))
                .lineSpacing(3)
                .padding(.top, 14)

            Eyebrow("Theme · cover and page", theme: theme)
                .padding(.top, 24)
                .padding(.bottom, 8)
            VStack(spacing: 10) {
                ForEach(Array(availableThemes.enumerated()), id: \.offset) { _, t in
                    ThemeRow(
                        theme: t,
                        sampleMantra: String(tradition.mantra.prefix(1)),
                        sampleFontName: tradition.displayFontKey,
                        outerTheme: theme,
                        isOn: form.themeKey == t.key
                    ) {
                        form.themeKey = t.key
                        onThemeSelected(t.key)
                    }
                }
            }
        }
    }

    private var saveEnabled: Bool { !calibrationStrokes.isEmpty && !ready }

    private var inkGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(InkPalette.options) { ink in
                Button {
                    form.inkHex = ink.hex
                } label: {
                    ZStack {
                        Color(hex: ink.hex)
                        if form.inkHex == ink.hex {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(form.inkHex == ink.hex ? theme.foil : Color.black.opacity(0.15),
                                    lineWidth: form.inkHex == ink.hex ? 2 : 0.5)
                    )
                }
            }
        }
    }

    private func saveCurrent() {
        guard !calibrationStrokes.isEmpty, !ready else { return }
        capturedSamples.append(calibrationStrokes)
        calibrationStrokes = []
        hint = "saved"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { hint = "" }
        // Mirror to form (just count, not actual stroke geometry — that
        // stays on-device per privacy line in the design's copy).
        form.handwritingSamples = (0..<capturedSamples.count).map { _ in HandwritingStrokeStorage() }
    }
}

private struct ThemeRow: View {
    let theme: any Theme
    let sampleMantra: String
    let sampleFontName: String
    let outerTheme: any Theme
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    theme.cloth
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(theme.foil, lineWidth: 0.5)
                        .padding(6)
                    Text(sampleMantra)
                        .font(.custom(sampleFontName, size: 18))
                        .foregroundStyle(theme.foil)
                }
                .frame(width: 56, height: 72)
                .overlay(
                    Rectangle().stroke(.black.opacity(0.2), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.displayName)
                        .font(.custom("EB Garamond", size: 17))
                        .foregroundStyle(outerTheme.textPrimary)
                    Text(theme.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(outerTheme.textPrimary.opacity(0.6))
                }
                Spacer()
                Circle()
                    .fill(isOn ? outerTheme.cloth : Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().stroke(isOn ? outerTheme.cloth : Color.black.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(12)
            .background(isOn ? outerTheme.page : Color.white.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isOn ? outerTheme.cloth : Color.black.opacity(0.12), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}
