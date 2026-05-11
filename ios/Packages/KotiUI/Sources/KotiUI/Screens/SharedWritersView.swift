import SwiftUI
import KotiCore
import KotiThemes

/// "Many Hands" — leaderboard of top contributors + countries breakdown +
/// custodianship note. Always presented as a sheet from the Shared hub.
public struct SharedWritersView: View {
    let tradition: TraditionContent
    let theme: any Theme
    let onClose: () -> Void

    public init(tradition: TraditionContent, theme: any Theme, onClose: @escaping () -> Void) {
        self.tradition = tradition
        self.theme = theme
        self.onClose = onClose
    }

    private var k: SharedKoti { SharedKotiCatalog.sample }
    private var totalCountries: Int {
        SharedKotiCatalog.countries.reduce(0) { $0 + $1.count }
    }

    public var body: some View {
        ZStack {
            theme.chromeBg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        countTitle
                        GoldRule(foil: theme.foil, width: 300)
                            .padding(.top, 4)
                        topHands
                        countries
                        custodianship
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                }
            }
        }
        .foregroundStyle(theme.textPrimary)
    }

    private var header: some View {
        HStack {
            Button(action: onClose) {
                Text("‹")
                    .font(.system(size: 22))
                    .foregroundStyle(theme.textPrimary.opacity(0.6))
            }
            Spacer()
            Text("MANY HANDS")
                .font(.system(size: 11))
                .kerning(2)
                .foregroundStyle(theme.textPrimary.opacity(0.55))
            Spacer()
            Color.clear.frame(width: 22, height: 22)
        }
        .padding(.horizontal, 24)
        .padding(.top, 54)
        .padding(.bottom, 8)
    }

    private var countTitle: some View {
        Group {
            Text(formatted(Int64(k.uniqueWriters))) +
            Text(" devotees across ").font(.custom("EB Garamond", size: 14)).foregroundColor(.gray) +
            Text("\(k.countriesActive)") +
            Text(" countries").font(.custom("EB Garamond", size: 14)).foregroundColor(.gray)
        }
        .font(.custom("EB Garamond", size: 22))
        .foregroundStyle(theme.textPrimary)
    }

    private var topHands: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOST GENEROUS HANDS")
                .font(.system(size: 10))
                .kerning(1.6)
                .foregroundStyle(theme.textPrimary.opacity(0.55))

            VStack(spacing: 0) {
                ForEach(Array(SharedKotiCatalog.topWriters.enumerated()), id: \.offset) { i, w in
                    HStack {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(theme.foil.opacity(0.13))
                                    .frame(width: 24, height: 24)
                                Text("\(i + 1)")
                                    .font(.custom("EB Garamond", size: 11))
                                    .foregroundStyle(theme.cloth)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(w.name)
                                    .font(.custom("EB Garamond", size: 14))
                                    .foregroundStyle(theme.textPrimary)
                                Text("since \(w.joined)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(theme.textPrimary.opacity(0.55))
                            }
                        }
                        Spacer()
                        Text(formatted(Int64(w.count)))
                            .font(.custom("EB Garamond", size: 16))
                            .foregroundStyle(theme.textPrimary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .overlay(
                        Rectangle()
                            .fill(.black.opacity(i == 0 ? 0 : 0.07))
                            .frame(height: 0.5),
                        alignment: .top
                    )
                }
            }
            .background(theme.page)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.black.opacity(0.08), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text("Names appear by consent. Many devotees write anonymously.")
                .font(.custom("EB Garamond", size: 10))
                .italic()
                .foregroundStyle(theme.textPrimary.opacity(0.5))
        }
    }

    private var countries: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FROM ACROSS THE WORLD")
                .font(.system(size: 10))
                .kerning(1.6)
                .foregroundStyle(theme.textPrimary.opacity(0.55))

            VStack(spacing: 0) {
                ForEach(Array(SharedKotiCatalog.countries.enumerated()), id: \.offset) { i, c in
                    let w = totalCountries > 0 ? Double(c.count) / Double(totalCountries) : 0
                    VStack(spacing: 4) {
                        HStack {
                            Text(c.country)
                            Spacer()
                            Text(formatted(Int64(c.count)))
                                .foregroundStyle(theme.textPrimary.opacity(0.65))
                        }
                        .font(.system(size: 12))
                        Capsule()
                            .fill(.black.opacity(0.06))
                            .frame(height: 3)
                            .overlay(
                                GeometryReader { g in
                                    Capsule()
                                        .fill(theme.cloth)
                                        .frame(width: g.size.width * w, height: 3)
                                }
                            )
                    }
                    .padding(.vertical, 6)
                    .overlay(
                        Rectangle()
                            .fill(.black.opacity(i == 0 ? 0 : 0.06))
                            .frame(height: 0.5),
                        alignment: .top
                    )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(theme.page)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.black.opacity(0.08), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var custodianship: some View {
        HStack(alignment: .top, spacing: 12) {
            SriYantra(foil: theme.foil, size: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("CUSTODIANSHIP")
                    .font(.system(size: 10))
                    .kerning(1.6)
                    .foregroundStyle(theme.page.opacity(0.75))
                Text("\(k.custodian) holds the ledger in trust. When the koti completes, the bound book travels to \(k.destination.components(separatedBy: ",").first ?? "Bhadrachalam") on \(k.estimatedShipDate.components(separatedBy: "·").first?.trimmingCharacters(in: .whitespaces) ?? k.estimatedShipDate).")
                    .font(.custom("EB Garamond", size: 13))
                    .foregroundStyle(theme.page.opacity(0.9))
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .background(theme.cloth)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formatted(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_IN")
        return f.string(from: NSNumber(value: n)) ?? String(n)
    }
}
