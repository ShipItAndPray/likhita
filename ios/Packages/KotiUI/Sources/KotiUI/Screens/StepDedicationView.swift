import SwiftUI
import KotiCore
import KotiThemes

/// Sankalpam step 2 of 5 — dedication text, dedicate-to chips, mode picker.
public struct StepDedicationView: View {
    let theme: any Theme
    let tradition: TraditionContent
    @Bindable var form: SankalpamForm
    let onBack: () -> Void
    let onNext: () -> Void

    public init(
        theme: any Theme,
        tradition: TraditionContent,
        form: SankalpamForm,
        onBack: @escaping () -> Void,
        onNext: @escaping () -> Void
    ) {
        self.theme = theme
        self.tradition = tradition
        self.form = form
        self.onBack = onBack
        self.onNext = onNext
    }

    public var body: some View {
        SankalpamFrame(
            theme: theme,
            step: 2, total: 5,
            title: "Why this koti?",
            subtitle: "Your reason will be printed on page one. Choose the count last.",
            onBack: onBack,
            content: {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Dedication · max 280", theme: theme)
                        .padding(.bottom, 8)
                    DedicationEditor(theme: theme, text: $form.dedicationText)
                    HStack {
                        Spacer()
                        Text("\(form.dedicationText.count) / 280")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textPrimary.opacity(0.5))
                    }
                    .padding(.top, 4)

                    Eyebrow("Dedicate to · optional", theme: theme)
                        .padding(.top, 20)
                        .padding(.bottom, 8)
                    chipRow

                    Eyebrow("Mode · count is locked once begun", theme: theme)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    VStack(spacing: 8) {
                        ForEach(KotiModeCatalog.plans) { plan in
                            ModeRow(plan: plan, isOn: form.modePlanKey == plan.key, theme: theme) {
                                form.modePlanKey = plan.key
                            }
                        }
                    }
                }
            },
            footer: {
                PrimaryButton("Continue", theme: theme, action: onNext)
            }
        )
    }

    private var chipRow: some View {
        // Wrap with a simple flex layout since SwiftUI lacks one natively.
        FlexibleHStack(spacing: 8, lineSpacing: 8) {
            ForEach(DedicationPreset.allCases, id: \.self) { preset in
                let on = (form.dedicationTo == preset)
                Button {
                    form.dedicationTo = on ? nil : preset
                } label: {
                    Text(preset.label)
                        .font(.system(size: 13))
                        .foregroundStyle(on ? theme.page : theme.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(on ? theme.cloth : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(on ? theme.cloth : Color.black.opacity(0.15), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}

private struct DedicationEditor: View {
    let theme: any Theme
    @Binding var text: String
    var body: some View {
        TextEditor(text: Binding(
            get: { text },
            set: { text = String($0.prefix(280)) }
        ))
        .font(.custom("EB Garamond", size: 15))
        .foregroundStyle(theme.textPrimary)
        .scrollContentBackground(.hidden)
        .padding(12)
        .frame(minHeight: 80, maxHeight: 96)
        .background(theme.page)
        .overlay(
            RoundedRectangle(cornerRadius: 10).stroke(theme.foil, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ModeRow: View {
    let plan: KotiModePlan
    let isOn: Bool
    let theme: any Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .lastTextBaseline, spacing: 8) {
                        Text(plan.label)
                            .font(.custom("EB Garamond", size: 18))
                            .foregroundStyle(theme.textPrimary)
                        if plan.recommended {
                            Text("RECOMMENDED")
                                .font(.system(size: 10))
                                .kerning(1.2)
                                .foregroundStyle(theme.accent)
                        }
                    }
                    Text("\(formatted(plan.count)) mantras · ~\(plan.pages) pages · \(plan.duration)")
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textPrimary.opacity(0.6))
                }
                Spacer()
                Circle()
                    .fill(isOn ? theme.cloth : Color.clear)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().stroke(isOn ? theme.cloth : Color.black.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isOn ? theme.page : Color.white.opacity(0.4))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isOn ? theme.cloth : Color.black.opacity(0.12), lineWidth: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.cloth, lineWidth: isOn ? 1 : 0)
                    .padding(0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
