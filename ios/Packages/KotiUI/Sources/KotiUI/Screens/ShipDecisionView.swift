import SwiftUI
import KotiCore
import KotiThemes

/// Where the printed book goes — temple / home / both.
public struct ShipDecisionView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let onBack: () -> Void
    let onShip: (ShipDecisionView.Choice) -> Void

    @State private var choice: Choice = .temple

    public enum Choice: String, CaseIterable, Sendable {
        case temple
        case home
        case both
    }

    public init(
        tradition: TraditionContent,
        theme: any Theme,
        onBack: @escaping () -> Void,
        onShip: @escaping (Choice) -> Void
    ) {
        self.tradition = tradition
        self.theme = theme
        self.onBack = onBack
        self.onShip = onShip
    }

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(options, id: \.key) { option in
                            OptionRow(option: option, isOn: choice == option.key, theme: theme) {
                                choice = option.key
                            }
                        }
                        AppleTaxDisclosure(theme: theme)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
                Button {
                    onShip(choice)
                } label: {
                    Text("Continue to checkout")
                        .font(.system(size: 16))
                        .foregroundStyle(theme.page)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(theme.cloth)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
        }
        .foregroundStyle(theme.textPrimary)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Text("‹")
                        .font(.system(size: 22))
                        .foregroundStyle(theme.textPrimary.opacity(0.6))
                }
                Spacer()
                Text("WHERE IT GOES")
                    .font(.system(size: 11))
                    .kerning(2)
                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                Spacer()
                Color.clear.frame(width: 22, height: 22)
            }

            Text("The book is ready")
                .font(.custom("EB Garamond", size: 26))
                .foregroundStyle(theme.textPrimary)
                .padding(.top, 8)

            Group {
                Text("Every fee below is at our actual cost. Likhita Foundation makes zero profit. ") +
                Text("likhita.org/transparency").underline()
            }
            .font(.system(size: 13))
            .foregroundStyle(theme.textPrimary.opacity(0.65))
            .lineSpacing(4)
            .padding(.top, 6)
        }
        .padding(.horizontal, 24)
        .padding(.top, 54)
        .padding(.bottom, 4)
    }

    private var options: [Option] {
        [
            Option(
                key: .temple,
                primary: true,
                title: "Deposit at \(tradition.templeShort)",
                subtitle: "Cloth-bound book printed and placed at \(tradition.templeFull). A photograph of your specific book + a temple-stamped receipt are mailed back within 60 days.",
                inr: 740, usd: 9
            ),
            Option(
                key: .home,
                primary: false,
                title: "Ship to your home",
                subtitle: "Premium hand-stitched edition delivered to you. Hand the koti to a family elder, or keep it on your altar.",
                inr: 1499, usd: 19.99
            ),
            Option(
                key: .both,
                primary: false,
                title: "Both",
                subtitle: "One copy to the temple. One copy to you. Printed in the same batch.",
                inr: 1999, usd: 26.99
            ),
        ]
    }

    fileprivate struct Option {
        let key: Choice
        let primary: Bool
        let title: String
        let subtitle: String
        let inr: Int
        let usd: Double
    }
}

private struct OptionRow: View {
    let option: ShipDecisionView.Option
    let isOn: Bool
    let theme: any Theme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(option.title)
                            .font(.custom("EB Garamond", size: 18))
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        HStack(spacing: 4) {
                            Text("₹\(option.inr)")
                                .font(.custom("EB Garamond", size: 14))
                            Text("· $\(String(format: "%.2f", option.usd))")
                                .font(.system(size: 12))
                                .foregroundStyle(theme.textPrimary.opacity(0.5))
                        }
                    }
                    Text(option.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(theme.textPrimary.opacity(0.7))
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isOn ? theme.page : Color.white.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isOn ? theme.cloth : Color.black.opacity(0.12), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))

                if option.primary {
                    Text("THE PILGRIMAGE")
                        .font(.system(size: 9))
                        .kerning(1.4)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .offset(x: -14, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct AppleTaxDisclosure: View {
    let theme: any Theme
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Apple-tax disclosure").bold()
            Group {
                Text("To avoid the 30% Apple platform fee, this purchase opens at ") +
                Text("likhita.org/checkout").underline() +
                Text(" via Safari.")
            }
        }
        .font(.system(size: 11))
        .lineSpacing(4)
        .foregroundStyle(theme.textPrimary.opacity(0.75))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
