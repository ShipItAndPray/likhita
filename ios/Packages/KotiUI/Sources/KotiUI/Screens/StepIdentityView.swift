import SwiftUI
import KotiCore
import KotiThemes

/// Sankalpam step 1 of 5 — name, gotra, native place, email.
public struct StepIdentityView: View {
    let theme: any Theme
    @Bindable var form: SankalpamForm
    let onBack: () -> Void
    let onNext: () -> Void

    public init(theme: any Theme, form: SankalpamForm, onBack: @escaping () -> Void, onNext: @escaping () -> Void) {
        self.theme = theme
        self.form = form
        self.onBack = onBack
        self.onNext = onNext
    }

    public var body: some View {
        SankalpamFrame(
            theme: theme,
            step: 1, total: 5,
            title: "Tell the book who you are",
            subtitle: "This will be printed in the colophon of your bound book — exactly as written.",
            onBack: onBack,
            content: {
                VStack(alignment: .leading, spacing: 16) {
                    field("Full name", hint: "Telugu, Devanagari, or Roman", text: $form.name)
                    field("Gotra", hint: "optional", text: $form.gotra)
                    field("Native place", hint: "optional", text: $form.nativePlace)
                    field("Email", hint: nil, text: $form.email, keyboard: .email)
                }
            },
            footer: {
                PrimaryButton("Continue", theme: theme, action: onNext)
            }
        )
    }

    enum Keyboard { case `default`, email }

    @ViewBuilder
    private func field(_ label: String, hint: String?, text: Binding<String>, keyboard: Keyboard = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text(label.uppercased())
                    .font(.system(size: 11))
                    .kerning(1.4)
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
                if let hint {
                    Text("· \(hint)")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textPrimary.opacity(0.42))
                }
            }
            #if os(iOS)
            TextField("", text: text)
                .keyboardType(keyboard == .email ? .emailAddress : .default)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.system(size: 16))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(theme.page)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.foil, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            #else
            TextField("", text: text)
                .autocorrectionDisabled()
                .font(.system(size: 16))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(theme.page)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(theme.foil, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
            #endif
        }
    }
}
